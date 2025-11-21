import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/services/task_service.dart';
import 'package:to_do_list/providers/sync_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Task>> _futureTasks;
  TaskFilter _currentFilter = TaskFilter.all;

  //bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  loadTasks() {
    setState(() {
      switch (_currentFilter) {
        case TaskFilter.all:
          _futureTasks = DBService.getTasks();
          break;
        case TaskFilter.pending:
          _futureTasks = DBService.getTasksPending();
          break;
        case TaskFilter.completed:
          _futureTasks = DBService.getTasksCompleted();
          break;
      }
    });
  }

  void _changeFilter(TaskFilter filter) {
    setState(() {
      _currentFilter = filter;
      loadTasks();
    });
  }

  goToAdd() async {
    await context.push('/createTask');
    loadTasks();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      completed: task.completed == 1 ? 0 : 1, // Toggle entre 0 y 1
      updated_at: DateTime.now().toIso8601String(),
      deleted: task.deleted,
    );

    // Actualizar en SQLite local
    await DBService.updateTask(updatedTask);
    
    // Encolar operación para sincronizar
    await DBService.enqueueOperation(
      entity: 'task',
      entityId: task.id.toString(),
      operation: 'UPDATE',
      payload: json.encode({
        'title': task.title,
        'completed': updatedTask.completed,
      }),
    );
    
    loadTasks(); // Recarga la lista actualizada
  }

  Future<void> _toggleTaskDeleted(Task task) async {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      completed: task.completed,
      updated_at: DateTime.now().toIso8601String(),
      deleted: 1,
    );

    // Actualizar en SQLite local
    await DBService.updateTask(updatedTask);
    
    // Encolar operación DELETE para sincronizar
    await DBService.enqueueOperation(
      entity: 'task',
      entityId: task.id.toString(),
      operation: 'DELETE',
      payload: json.encode({'id': task.id}),
    );
    
    loadTasks(); // Recarga la lista actualizada
  }

  deletedTasks() async {
    await context.push('/deletedTasks');
    loadTasks();
  }

  // Sincronización manual usando Provider
  Future<void> _manualSync() async {
    final syncProvider = context.read<SyncProvider>();
    await syncProvider.syncNow();
    loadTasks(); // Recargar lista después de sincronizar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          children: [
            const Text('To Do List'),
            const SizedBox(width: 10),
            // Indicador de estado de sincronización
            Consumer<SyncProvider>(
              builder: (context, syncProvider, _) {
                if (syncProvider.status == SyncStatus.syncing) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                } else if (syncProvider.status == SyncStatus.success) {
                  return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20);
                } else if (syncProvider.status == SyncStatus.error) {
                  return const Icon(Icons.error, color: Colors.redAccent, size: 20);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          // Botón de sincronización manual
          Consumer<SyncProvider>(
            builder: (context, syncProvider, _) {
              return IconButton(
                onPressed: syncProvider.isSyncing ? null : _manualSync,
                icon: syncProvider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.sync),
                tooltip: 'Sincronizar con servidor',
              );
            },
          ),
          IconButton(onPressed: goToAdd, icon: const Icon(Icons.add)),
        ],
        leading: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            deletedTasks();
          },
        ),
      ),
      body: Consumer<SyncProvider>(
        builder: (context, syncProvider, child) {
          // Mostrar SnackBar cuando cambia el estado de sincronización
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (syncProvider.status == SyncStatus.success && syncProvider.message.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(syncProvider.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (syncProvider.status == SyncStatus.error && syncProvider.message.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(syncProvider.message),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });

          return child!;
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("Tus Tareas", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                    FilterChip(
                    label: const Text('Pendientes'),
                    selected: _currentFilter == TaskFilter.pending,
                    onSelected: (selected) => _changeFilter(TaskFilter.pending),
                  ),
                  
                  FilterChip(
                    label: const Text('Completadas'),
                    selected: _currentFilter == TaskFilter.completed,
                    onSelected: (selected) =>
                        _changeFilter(TaskFilter.completed),
                  ),

                  FilterChip(
                    label: const Text('Todas'),
                    selected: _currentFilter == TaskFilter.all,
                    onSelected: (selected) => _changeFilter(TaskFilter.all),
                  ),
                ],
              ),
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
                          _futureTasks = DBService.getTasks();
                        });
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (_, index) {
                          final task = tasks[index];
                          return InkWell(
                            onTap: () async {
                              await context.push('/updateTask/${task.id}');
                              loadTasks();
                            },
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Checkbox(
                                      value: task.completed == 1,
                                      onChanged: (bool? newValue) {
                                        _toggleTaskCompletion(task);
                                      },
                                    ),
                                    SizedBox(width: 20),
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
                                    IconButton(
                                      onPressed: () {
                                        _toggleTaskDeleted(task);
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 25,
                                      ),
                                    ),
                                  ],
                                ),
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
        ), // Cierra Padding
      ), // Cierra Center
      ), // Cierra Consumer
    ); // Cierra Scaffold
  }
}

enum TaskFilter { all, pending, completed }
