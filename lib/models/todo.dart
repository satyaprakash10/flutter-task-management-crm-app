class SubTask {
  final String title;
  final bool done;

  const SubTask({required this.title, this.done = false});

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(title: json['title'] ?? '', done: json['done'] ?? false);
  }

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  SubTask copyWith({String? title, bool? done}) {
    return SubTask(title: title ?? this.title, done: done ?? this.done);
  }
}

class Todo {
  final int id;
  final String title;
  final bool completed;
  final String? description;
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime? dueDate;
  final DateTime? startDate;
  final List<String> tags;
  final List<SubTask> subtasks;

  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    this.description,
    this.priority = 'Medium',
    this.dueDate,
    this.startDate,
    this.tags = const [],
    this.subtasks = const [],
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
      description: json['description'],
      priority: json['priority'] ?? 'Medium',
      dueDate: json['dueDate'] != null && json['dueDate'] != ''
          ? DateTime.tryParse(json['dueDate'])
          : null,
      startDate: json['startDate'] != null && json['startDate'] != ''
          ? DateTime.tryParse(json['startDate'])
          : null,
      tags: (json['tags'] is List)
          ? (json['tags'] as List).map((e) => '$e').toList()
          : <String>[],
      subtasks: (json['subtasks'] is List)
          ? (json['subtasks'] as List)
                .map(
                  (e) => e is Map<String, dynamic>
                      ? SubTask.fromJson(e)
                      : SubTask(title: '$e'),
                )
                .toList()
          : const <SubTask>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'description': description,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'tags': tags,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
    };
  }

  Todo copyWith({
    int? id,
    String? title,
    bool? completed,
    String? description,
    String? priority,
    DateTime? dueDate,
    DateTime? startDate,
    List<String>? tags,
    List<SubTask>? subtasks,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
