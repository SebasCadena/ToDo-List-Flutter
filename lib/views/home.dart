import 'package:flutter/material.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/services/task_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Task>> _futureTasks;

  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _futureTasks = DBService.getTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('To Do List'),
        actions: [Icon(Icons.person)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              SizedBox(height: 10),
              Text("Tus Tareas", style: TextStyle(fontSize: 20)),
              SizedBox(height: 10),
              FutureBuilder<List<Task>>(
                future: _futureTasks,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!;

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _futureTasks = DBService.getTasks(); // vuelve a cargar
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
                            children: [
                              Checkbox(
                                // Asigna el valor de la variable al estado del checkbox
                                value: _isChecked,
                      
                                // Usa onChanged para cambiar el estado cuando se hace clic
                                onChanged: (bool? newValue) {
                                  // Actualiza el estado dentro de una función setState
                                  setState(() {
                                    _isChecked = newValue!;
                                  });
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: Text("${task.title}"),
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
            ],
          ),
        ),
      ),
    );
  }
}
