import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/services/task_service.dart';

class UpdateTaskView extends StatefulWidget {
  final int id;

  const UpdateTaskView({super.key, required this.id});

  @override
  State<UpdateTaskView> createState() => _UpdateTaskViewState();
}

class _UpdateTaskViewState extends State<UpdateTaskView> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  late Task _task;

  Future<void> _cargarDatos() async {
    final tareas = await DBService.getTasks();
    _task = tareas.firstWhere((c) => c.id == widget.id);
    _tituloController.text = _task.title;
  }

  Future<void> _actualizarCategoria() async {
    if (_formKey.currentState!.validate()) {
      final actualizada = Task(
        id: _task.id,
        title: _tituloController.text,
        completed: _task.completed,
        updated_at: DateTime.now().toIso8601String(),
        deleted: _task.deleted,
      );

      await DBService.updateTask(actualizada);
      if (context.mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nueva Tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título de la tarea',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _actualizarCategoria,
                child: const Text('Actualizar Tarea'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
