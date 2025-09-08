import 'package:flutter/material.dart';
import '../models/todo.dart';

class TaskCard extends StatelessWidget {
  final Todo todo;

  const TaskCard({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        leading: Icon(
          todo.completed ? Icons.check_circle : Icons.circle_outlined,
          color: todo.completed ? Colors.green : Colors.grey,
        ),
        title: Text(todo.title),
      ),
    );
  }
}
