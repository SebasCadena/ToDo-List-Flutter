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

    //! Crea y abre la base de datos; si es nueva, ejecuta la sentencia sql para crear la tabla
    //! Create se ejecuta solo si la base de datos no existe
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Define la estructura de la tabla 'categorias'
        // db.execute se usa para ejecutar sentencias SQL
        return db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0
          );
        ''');
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
    final res = await db.query('tasks');
    return res.map((e) => Task.fromMap(e)).toList();
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
}
