import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/services/task_service.dart';
import 'dart:convert';

class DeletedTasksView extends StatefulWidget {
  const DeletedTasksView({super.key});

  @override
  State<DeletedTasksView> createState() => _DeletedTasksViewState();
}

class _DeletedTasksViewState extends State<DeletedTasksView> {
  late Future<List<Task>> _futureTasks;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  loadTasks() {
    setState(() {
      _futureTasks = DBService.getTasksDeleted();
    });
  }

  Future<void> _toggleTaskRestored(Task task) async {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      completed: task.completed,
      updated_at: DateTime.now().toIso8601String(),
      deleted: 0,
    );

    // Actualizar en SQLite local
    await DBService.updateTask(updatedTask);
    
    // Encolar operación RESTORE para sincronizar
    await DBService.enqueueOperation(
      entity: 'task',
      entityId: task.id.toString(),
      operation: 'RESTORE',
      payload: json.encode({'id': task.id}),
    );
    
    loadTasks(); // Recarga la lista actualizada
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      completed: task.completed == 1 ? 0 : 1, // Toggle entre 0 y 1
      updated_at: DateTime.now().toIso8601String(),
      deleted: task.deleted,
    );

    await DBService.updateTask(updatedTask);
    loadTasks(); // Recarga la lista actualizada
  }

  /// Eliminar PERMANENTEMENTE una tarea de SQLite
  Future<void> _deletePermanently(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar permanentemente'),
        content: Text('¿Estás seguro de eliminar "${task.title}" permanentemente?\n\nEsto la eliminará de:\n• Base de datos local (SQLite)\n• Servidor (cuando sincronice)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Encolar operación DELETE para sincronizar con el servidor
      await DBService.enqueueOperation(
        entity: 'task',
        entityId: task.id.toString(),
        operation: 'DELETE',
        payload: json.encode({'id': task.id}),
      );
      
      // Eliminar de SQLite local
      await DBService.deletePermanently(task.id!);
      
      loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tarea eliminada permanentemente (se sincronizará)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Limpiar TODAS las tareas de SQLite
  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar base de datos'),
        content: const Text('¿Eliminar TODAS las tareas de SQLite? Esto incluye las activas, eliminadas y la cola de sincronización. Útil para empezar de cero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LIMPIAR TODO'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBService.deleteAllTasks();
      loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Base de datos limpiada completamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Deleted Tasks'),
        actions: [
          // Botón para limpiar toda la base de datos
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Limpiar toda la BD',
            onPressed: _clearAllData,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text("Tus Tareas Eliminadas", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Task>>(
                  future: _futureTasks,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tasks = snapshot.data!;

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _futureTasks = DBService.getTasksDeleted();
                        });
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (_, index) {
                          final task = tasks[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Checkbox(
                                    value: task.completed == 1,
                                    onChanged: (bool? newValue) {
                                      _toggleTaskCompletion(task);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        decoration: task.completed == 1
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  // Botón para restaurar
                                  IconButton(
                                    onPressed: () => _toggleTaskRestored(task), 
                                    icon: Icon(
                                      Icons.restore_from_trash,
                                      color: Colors.green,
                                      size: 26,
                                    ),
                                    tooltip: 'Restaurar',
                                  ),
                                  // Botón para eliminar permanentemente
                                  IconButton(
                                    onPressed: () => _deletePermanently(task), 
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                      size: 26,
                                    ),
                                    tooltip: 'Eliminar permanentemente',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
