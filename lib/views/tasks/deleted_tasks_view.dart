import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/services/task_service.dart';

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

    await DBService.updateTask(updatedTask);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Deleted Tasks'),
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
                                    onPressed: () => _toggleTaskRestored(task), 
                                    icon: Icon(Icons.add_box_rounded, color: Theme.of(context).colorScheme.primary, size: 30,),
                                    )
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
