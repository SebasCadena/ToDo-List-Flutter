import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

/// Servicio simple para comunicarse con la API REST del backend
class ApiService {
  // URL base - Servidor ngrok en producción
  static const String baseUrl = 'https://f77116f8ec5b.ngrok-free.app';
  
  /// GET /tasks - Obtener todas las tareas activas
  static Future<List<Task>> getTasks() async {
    try {
      print('🔄 Iniciando petición GET /tasks...');
      final response = await http.get(
        Uri.parse('$baseUrl/tasks?deleted=0'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'ToDoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      print('✅ Respuesta recibida: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromApiJson(json)).toList();
      } else {
        throw Exception('Error al obtener tareas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getTasks: $e');
      rethrow;
    }
  }

  /// GET /tasks/deleted - Obtener tareas eliminadas
  static Future<List<Task>> getDeletedTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/deleted'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'ToDoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromApiJson(json)).toList();
      } else {
        throw Exception('Error al obtener tareas eliminadas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getDeletedTasks: $e');
      rethrow;
    }
  }

  /// POST /tasks - Crear nueva tarea
  static Future<Task> createTask(String title) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'ToDoApp/1.0',
        },
        body: json.encode({
          'title': title,
          'completed': false,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Task.fromApiJson(data);
      } else {
        throw Exception('Error al crear tarea: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en createTask: $e');
      rethrow;
    }
  }

  /// PUT /tasks/{id} - Actualizar tarea
  static Future<Task> updateTask(int id, String title, bool completed) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'ToDoApp/1.0',
        },
        body: json.encode({
          'title': title,
          'completed': completed,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Task.fromApiJson(data);
      } else {
        throw Exception('Error al actualizar tarea: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en updateTask: $e');
      rethrow;
    }
  }

  /// DELETE /tasks/{id} - Eliminar tarea (soft delete)
  static Future<void> deleteTask(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'ToDoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar tarea: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en deleteTask: $e');
      rethrow;
    }
  }

  /// PUT /tasks/{id}/restore - Restaurar tarea eliminada
  static Future<Task> restoreTask(int id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id/restore'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'ToDoApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Task.fromApiJson(data);
      } else {
        throw Exception('Error al restaurar tarea: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en restoreTask: $e');
      rethrow;
    }
  }
}
