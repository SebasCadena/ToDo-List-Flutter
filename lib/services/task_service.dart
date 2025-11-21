import 'package:path/path.dart'; // Ayuda a construir rutas de archivos de forma segura
import 'package:sqflite/sqflite.dart'; // Plugin principal para trabajar con SQLite en Flutter
import '../models/task_model.dart'; // Modelo que representa la entidad 'Task'

///! Servicio para gestionar la base de datos local SQLite
class DBService {
  // Instancia única de la base de datos
  // Se usa para evitar múltiples conexiones a la misma base de datos
  // y para asegurar que solo haya una instancia de la base de datos en toda la app
  static Database? _database;

  //! Acceso a la base de datos; si no está inicializada, se crea
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db'); // Inicializa si no existe
    return _database!;
  }

  /// Inicializa la base de datos en la ruta segura del sistema
  static Future<Database> _initDB(String fileName) async {
    final dbPath =
        await getDatabasesPath(); // Ruta estándar donde Flutter guarda DBs
    final path = join(dbPath, fileName); // Construcción segura de la ruta final

    //! Crea y abre la base de datos; si es nueva, ejecuta la sentencia sql para crear las tablas
    //! Create se ejecuta solo si la base de datos no existe
    return await openDatabase(
      path,
      version: 2, // Incrementamos versión para agregar nueva tabla
      onCreate: (db, version) async {
        // Tabla de tareas
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0
          );
        ''');
        
        // Tabla de cola de operaciones para sincronización
        await db.execute('''
          CREATE TABLE queue_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            op TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            attempt_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Si actualizamos desde v1, crear la tabla de cola
          await db.execute('''
            CREATE TABLE IF NOT EXISTS queue_operations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entity TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              op TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              attempt_count INTEGER NOT NULL DEFAULT 0,
              last_error TEXT
            );
          ''');
        }
      },
    );
  }

  /// Inserta una nueva tarea en la base de datos
  static Future<int> insertTask(Task task) async {
    final db = await database;
    //db.insert se usa para insertar un nuevo registro en la tabla
    // El método toMap convierte el objeto Categoria a un mapa para la inserción
    return await db.insert('tasks', task.toMap());
  }

  /// Obtiene la lista de todas las tareas registradas
  static Future<List<Task>> getTasks() async {
    final db = await database;
    // db.query se usa para obtener registros de la tabla
    // Se puede usar un filtro, pero aquí se obtienen todos los registros
    final res = await db.query('tasks', where: 'deleted = ?', whereArgs: [0]);
    return res.map((e) => Task.fromMap(e)).toList();
  }

  static Future<List<Task>> getTasksDeleted() async {
    final db = await database;
    // db.query se usa para obtener registros de la tabla
    // Se puede usar un filtro, pero aquí se obtienen todos los registros
    final res = await db.query('tasks', where: 'deleted = ?', whereArgs: [1]);
    return res.map((e) => Task.fromMap(e)).toList();
  }

  // Solo pendientes
  static Future<List<Task>> getTasksPending() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'deleted = ? AND completed = ?',
      whereArgs: [0, 0],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Solo completadas
  static Future<List<Task>> getTasksCompleted() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'deleted = ? AND completed = ?',
      whereArgs: [0, 1],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  /// Actualiza una tarea existente según su ID
  static Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?', // Filtro para identificar el registro
      whereArgs: [task.id], // Argumento que reemplaza el '?'
    );
  }

  // ========== FUNCIONES DE COLA DE SINCRONIZACIÓN ==========

  /// Encola una operación para sincronizar con el servidor
  static Future<void> enqueueOperation({
    required String entity,
    required String entityId,
    required String operation, // CREATE, UPDATE, DELETE, RESTORE
    required String payload,
  }) async {
    final db = await database;
    await db.insert('queue_operations', {
      'entity': entity,
      'entity_id': entityId,
      'op': operation,
      'payload': payload,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'attempt_count': 0,
      'last_error': null,
    });
    print('✅ Operación encolada: $operation $entity $entityId');
  }

  /// Obtiene todas las operaciones pendientes en la cola
  static Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return await db.query(
      'queue_operations',
      orderBy: 'created_at ASC', // FIFO
    );
  }

  /// Elimina una operación de la cola después de sincronizar exitosamente
  static Future<void> removeOperation(int queueId) async {
    final db = await database;
    await db.delete(
      'queue_operations',
      where: 'id = ?',
      whereArgs: [queueId],
    );
  }

  /// Actualiza el contador de intentos y error de una operación
  static Future<void> updateOperationAttempt(int queueId, String error) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE queue_operations 
      SET attempt_count = attempt_count + 1, last_error = ?
      WHERE id = ?
    ''', [error, queueId]);
  }

  /// Elimina permanentemente una tarea de SQLite (hard delete)
  static Future<void> deletePermanently(int taskId) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Elimina TODAS las tareas de SQLite (útil para limpiar y empezar de cero)
  static Future<void> deleteAllTasks() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('queue_operations'); // También limpiar la cola
  }
}
