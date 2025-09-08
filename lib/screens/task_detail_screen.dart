import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../widgets/toast.dart';

class TaskDetailScreen extends StatefulWidget {
  final Todo task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Todo _task;
  bool _editing = false;
  bool _didInitArgs = false;

  final TextEditingController _title = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _tagInput = TextEditingController();
  String _priority = 'Medium';
  DateTime? _start;
  DateTime? _due;
  late List<String> _tags;
  late List<SubTask> _subs;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initFromTask(widget.task);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['edit'] == true) {
      setState(() => _editing = true);
    }
  }

  void _initFromTask(Todo t) {
    _task = t;
    _title.text = t.title;
    _desc.text = t.description ?? '';
    _priority = t.priority;
    _start = t.startDate;
    _due = t.dueDate;
    _tags = List<String>.from(t.tags);
    _subs = List<SubTask>.from(t.subtasks);
  }

  Future<void> _pickDate(bool start) async {
    final base = start ? (_start ?? DateTime.now()) : (_due ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => start ? _start = picked : _due = picked);
  }

  void _addTagFromInput() {
    final v = _tagInput.text.trim();
    if (v.isEmpty) return;
    if (!_tags.contains(v)) setState(() => _tags.add(v));
    _tagInput.clear();
  }

  void _toggleComplete() {
    setState(() => _task = _task.copyWith(completed: !_task.completed));
    ToastService.success(
      _task.completed ? 'Task marked complete' : 'Task marked incomplete',
    );
    Navigator.pop(context, _task);
  }

  void _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ToastService.warning('Task deleted');
      Navigator.pop(context, {'delete': true, 'id': _task.id});
    }
  }

  String? _validateTitle(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Title is required' : null;
  String? _validateDesc(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Description is required' : null;

  void _saveEdits() {
    if (!_formKey.currentState!.validate()) return;
    final updated = _task.copyWith(
      title: _title.text.trim().isEmpty ? _task.title : _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      priority: _priority,
      startDate: _start,
      dueDate: _due,
      tags: List<String>.from(_tags),
      subtasks: List<SubTask>.from(_subs),
    );
    setState(() {
      _task = updated;
      _editing = false;
    });
    ToastService.success('Task updated');
    Navigator.pop(context, _task);
  }

  Widget _tagBadge(BuildContext context, String tag) {
    final theme = Theme.of(context);
    final seed = tag.hashCode;
    final hue = (seed % 360).toDouble();
    final color = HSLColor.fromAHSL(
      1,
      hue,
      0.6,
      theme.brightness == Brightness.dark ? 0.5 : 0.7,
    ).toColor();
    final bg = color.withOpacity(
      theme.brightness == Brightness.dark ? 0.20 : 0.12,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        tag,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _priorityBadge(BuildContext context, String priority) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Color bg;
    Color fg;
    switch (priority) {
      case 'High':
        bg = isDark ? Colors.red.withOpacity(0.12) : Colors.red.shade50;
        fg = isDark ? Colors.redAccent : Colors.red.shade700;
        break;
      case 'Low':
        bg = isDark ? Colors.green.withOpacity(0.12) : Colors.green.shade50;
        fg = isDark ? Colors.greenAccent : Colors.green.shade700;
        break;
      default:
        bg = isDark ? Colors.orange.withOpacity(0.12) : Colors.orange.shade50;
        fg = isDark ? Colors.orangeAccent : Colors.orange.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task #${_task.id}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'edit':
                  setState(() => _editing = true);
                  break;
                case 'complete':
                  _toggleComplete();
                  break;
                case 'delete':
                  _delete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
              ),
              PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: Icon(
                    _task.completed
                        ? Icons.radio_button_unchecked
                        : Icons.check_circle,
                  ),
                  title: Text(
                    _task.completed ? 'Mark Incomplete' : 'Mark Complete',
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _editing
            ? Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: _editForm(),
              )
            : _readView(),
      ),
    );
  }

  Widget _readView() {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Row(
          children: [
            Checkbox(
              value: _task.completed,
              onChanged: (_) => _toggleComplete(),
            ),
            Text(
              _task.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if ((_task.description ?? '').isNotEmpty) Text(_task.description ?? ''),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Priority: '),
            _priorityBadge(context, _task.priority),
          ],
        ),
        const SizedBox(height: 8),
        if (_task.startDate != null) Text('Start: ${_task.startDate}'),
        if (_task.dueDate != null) Text('Due: ${_task.dueDate}'),
        const SizedBox(height: 8),
        if (_task.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: -8,
            children: [for (final t in _task.tags) _tagBadge(context, t)],
          ),
        const SizedBox(height: 8),
        if (_subs.isNotEmpty) const Text('Subtasks:'),
        for (int i = 0; i < _subs.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Checkbox(
                  value: _subs[i].done,
                  onChanged: (v) => setState(() {
                    _subs[i] = _subs[i].copyWith(done: v ?? false);
                    _task = _task.copyWith(subtasks: List<SubTask>.from(_subs));
                    ToastService.success(
                      _subs[i].done ? 'Subtask completed' : 'Subtask unchecked',
                    );
                  }),
                ),
                Text(
                  _subs[i].title,
                  style: TextStyle(
                    decoration: _subs[i].done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _editForm() {
    return ListView(
      children: [
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          validator: _validateTitle,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _desc,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          validator: _validateDesc,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                ),
                child: InkWell(
                  onTap: () => _pickDate(true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      _start != null
                          ? _start!.toLocal().toString().split(' ').first
                          : 'Select',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                ),
                child: InkWell(
                  onTap: () => _pickDate(false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      _due != null
                          ? _due!.toLocal().toString().split(' ').first
                          : 'Select',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Priority',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _priority,
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                  for (final t in _tags)
                    Chip(
                      label: Text(t),
                      onDeleted: () => setState(() => _tags.remove(t)),
                    ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _tagInput,
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
        const SizedBox(height: 12),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Subtasks',
            border: OutlineInputBorder(),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _subs.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _subs[i].title,
                          style: TextStyle(
                            decoration: _subs[i].done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Subtask',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) =>
                              _subs[i] = _subs[i].copyWith(title: v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _subs[i].done,
                        onChanged: (v) => setState(
                          () => _subs[i] = _subs[i].copyWith(done: v ?? false),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _subs.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _subs.add(const SubTask(title: ''))),
                  icon: const Icon(Icons.add),
                  label: const Text('Add subtask'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _saveEdits,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
