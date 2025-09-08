import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddTaskModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onTaskAdded;

  const AddTaskModal({super.key, required this.onTaskAdded});

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _MutableSubTask {
  String title;
  bool completed;
  _MutableSubTask({required this.title}) : completed = false;
}

class _AddTaskModalState extends State<AddTaskModal> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  DateTime? _startDate;
  DateTime? _dueDate;
  String _priority = 'Medium';
  final List<String> _availableTags = ['Work', 'Personal', 'Urgent'];
  final List<String> _selectedTags = [];
  final List<_MutableSubTask> _subTasks = [];

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime initial =
        (isStart ? _startDate : _dueDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_dueDate != null && _dueDate!.isBefore(_startDate!)) {
            _dueDate = _startDate;
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _addSubTaskField() {
    setState(() => _subTasks.add(_MutableSubTask(title: '')));
  }

  void _addTagFromInput() {
    final v = _tagInputController.text.trim();
    if (v.isEmpty) return;
    if (!_availableTags.contains(v)) _availableTags.add(v);
    if (!_selectedTags.contains(v)) _selectedTags.add(v);
    _tagInputController.clear();
    setState(() {});
  }

  String? _validateTitle(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Title is required' : null;
  String? _validateDescription(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Description is required' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add New Task',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateTitle,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateDescription,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _startDate == null
                                ? 'Select Date'
                                : DateFormat('yyyy-MM-dd').format(_startDate!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _dueDate == null
                                ? 'Select Date'
                                : DateFormat('yyyy-MM-dd').format(_dueDate!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) =>
                      setState(() => _priority = value ?? 'Medium'),
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    border: OutlineInputBorder(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: -8,
                        children: [
                          for (final tag in _availableTags)
                            FilterChip(
                              label: Text(tag),
                              selected: _selectedTags.contains(tag),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    if (!_selectedTags.contains(tag)) {
                                      _selectedTags.add(tag);
                                    }
                                  } else {
                                    _selectedTags.remove(tag);
                                  }
                                });
                              },
                            ),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _tagInputController,
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Add tag...',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _addTagFromInput(),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Add tag',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _addTagFromInput,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    for (int i = 0; i < _subTasks.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _subTasks[i].title,
                                style: TextStyle(
                                  decoration: _subTasks[i].completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Subtask',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => _subTasks[i].title = val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Checkbox(
                              value: _subTasks[i].completed,
                              onChanged: (v) => setState(
                                () => _subTasks[i].completed = v ?? false,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _subTasks.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addSubTaskField,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Subtask'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      widget.onTaskAdded({
                        'title': _titleController.text.trim(),
                        'description': _descriptionController.text.trim(),
                        'startDate': _startDate?.toIso8601String(),
                        'dueDate': _dueDate?.toIso8601String(),
                        'priority': _priority,
                        'tags': List<String>.from(_selectedTags),
                        'subtasks': _subTasks
                            .map(
                              (s) => {
                                'title': s.title,
                                'completed': s.completed,
                              },
                            )
                            .toList(),
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Create Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
