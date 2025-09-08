import 'package:flutter/foundation.dart';
import '../models/todo.dart';

class TaskStore {
  static final ValueNotifier<List<Todo>> todos = ValueNotifier<List<Todo>>(
    <Todo>[],
  );

  static void set(List<Todo> list) {
    todos.value = List<Todo>.unmodifiable(list);
  }

  static List<Todo> get current => todos.value;
}
