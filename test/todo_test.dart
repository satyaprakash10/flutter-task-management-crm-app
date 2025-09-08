import 'package:flutter_test/flutter_test.dart';
import 'package:todo_demo/models/todo.dart';

void main() {
  test('Todo fromJson test', () {
    final json = {'id': 1, 'title': 'Test Task', 'completed': false};
    final todo = Todo.fromJson(json);

    expect(todo.id, 1);
    expect(todo.title, 'Test Task');
    expect(todo.completed, false);
  });
}
