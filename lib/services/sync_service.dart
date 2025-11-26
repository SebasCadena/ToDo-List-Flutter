import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import 'task_service.dart';

/// Servicio simple de sincronización
class SyncService {
  /// Verifica si hay conexión a internet
  static Future<bool> hasConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);
  }

  /// Procesa todas las operaciones pendientes en la cola
  static Future<Map<String, dynamic>> syncPendingOperations() async {
    // Verificar conexión
    if (!await hasConnection()) {
      return {'success': false, 'message': 'Sin conexión a internet'};
    }

    int synced = 0;
    int failed = 0;
    String lastError = '';

    // Procesar operaciones hasta que no haya más pendientes
    while (true) {
      final pendingOps = await DBService.getPendingOperations();
      
      if (pendingOps.isEmpty) {
        break; // No hay más operaciones
      }

      // Procesar solo la primera operación y luego refrescar la lista
      final op = pendingOps.first;
      final queueId = op['id'] as int;
      final operation = op['op'] as String;
      final entityId = op['entity_id'] as String;
      final payload = json.decode(op['payload'] as String);

      try {
        switch (operation) {
          case 'CREATE':
            // Crear tarea en el servidor
            final newTask = await ApiService.createTask(payload['title']);
            final localId = int.parse(entityId);
            final serverId = newTask.id!;
            
            // Actualizar ID local con el ID del servidor en la tabla tasks
            await DBService.database.then((db) => db.update(
              'tasks',
              {'id': serverId, 'updated_at': newTask.updated_at},
              where: 'id = ?',
              whereArgs: [localId],
            ));
            
            // ⭐ IMPORTANTE: Actualizar entity_id en operaciones pendientes de esta tarea
            await DBService.database.then((db) => db.update(
              'queue_operations',
              {'entity_id': serverId.toString()},
              where: 'entity_id = ? AND entity = ? AND id != ?',
              whereArgs: [localId.toString(), 'task', queueId],
            ));
            
            print('✅ ID actualizado: $localId → $serverId en operaciones pendientes');
            break;

          case 'UPDATE':
            // Actualizar tarea en el servidor
            await ApiService.updateTask(
              int.parse(entityId),
              payload['title'],
              payload['completed'] == 1,
            );
            break;

          case 'DELETE':
            // Eliminar tarea en el servidor
            await ApiService.deleteTask(int.parse(entityId));
            break;

          case 'RESTORE':
            // Restaurar tarea en el servidor
            await ApiService.restoreTask(int.parse(entityId));
            break;
        }

        // Operación exitosa, eliminar de la cola
        await DBService.removeOperation(queueId);
        synced++;
        print('✅ Sincronizado: $operation #$entityId');
      } catch (e) {
        // Error al sincronizar
        lastError = e.toString();
        final attemptCount = op['attempt_count'] as int;
        
        // Reintentar solo si no ha superado el máximo de intentos
        if (attemptCount < 5) {
          await DBService.updateOperationAttempt(queueId, lastError);
          print('❌ Error sincronizando: $operation #$entityId (intento ${attemptCount + 1}/5) - $e');
          
          // Backoff exponencial: 1s, 2s, 4s, 8s, 16s
          final backoffSeconds = (1 << attemptCount); // 2^attemptCount
          print('⏳ Reintentando en ${backoffSeconds}s...');
          await Future.delayed(Duration(seconds: backoffSeconds));
        } else {
          // Marcar como fallida después de 5 intentos
          await DBService.updateOperationAttempt(queueId, 'MAX_RETRIES_EXCEEDED: $lastError');
          print('🚫 Operación fallida permanentemente: $operation #$entityId');
          // Eliminar operación fallida para no bloquear la cola
          await DBService.removeOperation(queueId);
        }
        
        failed++;
      }
    }

    return {
      'success': failed == 0,
      'synced': synced,
      'failed': failed,
      'message': failed == 0
          ? '✅ $synced operaciones sincronizadas'
          : '⚠️ $synced sincronizadas, $failed fallidas',
      'lastError': lastError,
    };
  }

  /// Sincroniza y además actualiza las tareas locales con las del servidor
  static Future<Map<String, dynamic>> fullSync() async {
    // Primero sincronizar operaciones pendientes
    final syncResult = await syncPendingOperations();

    // Luego obtener tareas del servidor y actualizar local
    if (await hasConnection()) {
      try {
        final serverTasks = await ApiService.getTasks();
        
        // Actualizar tareas locales (estrategia simple: Last-Write-Wins)
        for (var serverTask in serverTasks) {
          final db = await DBService.database;
          final localTask = await db.query(
            'tasks',
            where: 'id = ?',
            whereArgs: [serverTask.id],
          );

          if (localTask.isEmpty) {
            // Tarea no existe localmente, insertarla
            await db.insert('tasks', serverTask.toMap());
          } else {
            // Comparar updated_at y mantener el más reciente
            final localUpdatedAt = DateTime.parse(localTask.first['updated_at'] as String);
            final serverUpdatedAt = DateTime.parse(serverTask.updated_at);
            
            if (serverUpdatedAt.isAfter(localUpdatedAt)) {
              // El servidor tiene la versión más reciente
              await db.update(
                'tasks',
                serverTask.toMap(),
                where: 'id = ?',
                whereArgs: [serverTask.id],
              );
            }
          }
        }
        
        syncResult['fullSyncCompleted'] = true;
      } catch (e) {
        syncResult['fullSyncError'] = e.toString();
      }
    }

    return syncResult;
  }
}
