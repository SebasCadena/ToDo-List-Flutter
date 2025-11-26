class Task {
  int? id;
  String title;
  int completed;
  String updated_at;
  int deleted;

  Task({this.id, required this.title, required this.completed, required this.updated_at, required this.deleted});
  
  /// Convierte un mapa (registro de la base de datos SQLite) a una instancia de Task
  factory Task.fromMap(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    completed: json['completed'],
    updated_at: json['updated_at'],
    deleted: json['deleted'],
  );

  /// Convierte un JSON de la API (completed es bool) a una instancia de Task
  factory Task.fromApiJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    completed: json['completed'] == true ? 1 : 0, // bool -> int
    updated_at: json['updated_at'],
    deleted: json['deleted'],
  );

  /// Convierte la instancia de Task a un mapa para ser almacenado en la base de datos
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'completed': completed,
    'updated_at': updated_at,
    'deleted': deleted,
  };

  /// Convierte la instancia de Task a JSON para enviar a la API (completed es bool)
  Map<String, dynamic> toApiJson() => {
    'title': title,
    'completed': completed == 1, // int -> bool
  };
}
