import 'package:flutter/material.dart';
import '../models/todo.dart';

class TaskTableRow extends StatelessWidget {
  final Todo task;
  final Function(Todo) onEdit;
  final Function(Todo) onView;
  final Function(Todo) onDelete;
  final Function(Todo) onComplete;
  final bool selected;
  final Function(bool?) onSelect;

  const TaskTableRow({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
    required this.onComplete,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return TableRowInkWell(
      child: Row(
        children: [
          Checkbox(value: selected, onChanged: onSelect),
          Expanded(
            child: InkWell(
              onTap: () => onView(task),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          Text(task.priority),
          Text(task.tags.join(", ")),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'Edit':
                  onEdit(task);
                  break;
                case 'View':
                  onView(task);
                  break;
                case 'Delete':
                  onDelete(task);
                  break;
                case 'Mark Complete':
                  onComplete(task);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Edit', child: Text('Edit')),
              PopupMenuItem(value: 'View', child: Text('View')),
              PopupMenuItem(value: 'Delete', child: Text('Delete')),
              PopupMenuItem(
                value: 'Mark Complete',
                child: Text('Mark Complete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
