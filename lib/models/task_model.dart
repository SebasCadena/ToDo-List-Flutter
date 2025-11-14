class Task {
  int? id;
  String title;
  int completed;
  String updated_at;
  int deleted;

  Task({this.id, required this.title, required this.completed, required this.updated_at, required this.deleted});
  /// Convierte un mapa (registro de la base de datos) a una instancia de Task
  factory Task.fromMap(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    completed: json['completed'],
    updated_at: json['updated_at'],
    deleted: json['deleted'],
  );

  /// Convierte la instancia de Categoria a un mapa para ser almacenado en la base de datos
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'completed': completed,
    'updated_at': updated_at,
    'deleted': deleted,
  };
}
