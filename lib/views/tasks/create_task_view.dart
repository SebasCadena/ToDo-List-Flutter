import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/services/task_service.dart';
import 'dart:convert';

class CreateTaskView extends StatefulWidget {
  const CreateTaskView({super.key});

  @override
  State<CreateTaskView> createState() => _CreateTaskViewState();
}

class _CreateTaskViewState extends State<CreateTaskView> {


  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();

  Future<void> _guardarTarea() async {
    if (_formKey.currentState!.validate()) {
      final nuevaTarea = Task(
        title: _tituloController.text,
        completed: 0,
        updated_at: DateTime.now().toIso8601String(),
        deleted: 0,
      );

      // Guardar en SQLite local
      final localId = await DBService.insertTask(nuevaTarea);
      
      // Encolar operación para sincronizar con el servidor
      await DBService.enqueueOperation(
        entity: 'task',
        entityId: localId.toString(),
        operation: 'CREATE',
        payload: json.encode({
          'title': _tituloController.text,
          'completed': 0,
        }),
      );
      
      if (!mounted) return;
      context.pop(); // Volver a la lista
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Tarea'),
      ),
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
                onPressed: _guardarTarea,
                child: const Text('Guardar Tarea'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}