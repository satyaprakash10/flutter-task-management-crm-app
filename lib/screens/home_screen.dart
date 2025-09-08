import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../widgets/add_task_modal.dart';
import '../services/task_store.dart';
import '../services/local_storage_service.dart';
import '../widgets/toast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> tasks = [];
  bool _loading = false;
  int _page = 1;
  final int _limit = 10;
  bool _hasMore = false;
  int _totalCount = 0;

  // Sorting
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // Filter
  String _filter = 'All'; // All, Completed, Pending

  // Row hover tracking
  int? _hoverRow;

  static const double _tableMinWidth =
      980; // ensures horizontal scroll on small screens

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    final all = await LocalStorageService.loadAllTasks();
    _totalCount = all.length;
    _applyPageFrom(all, _page);
    setState(() => _loading = false);
  }

  void _applyPageFrom(List<Todo> all, int page) {
    final start = (page - 1) * _limit;
    final end = math.min(start + _limit, all.length);
    final slice = (start >= 0 && start < all.length)
        ? all.sublist(start, end)
        : <Todo>[];
    tasks = slice;
    _page = page;
    _totalCount = all.length;
    _hasMore = page * _limit < _totalCount;
    TaskStore.set(tasks);
  }

  void _updateFromStorageSamePage() async {
    final all = await LocalStorageService.loadAllTasks();
    setState(() => _applyPageFrom(all, _page));
  }

  List<Todo> get _visibleTasks {
    switch (_filter) {
      case 'Completed':
        return tasks.where((t) => t.completed).toList();
      case 'Pending':
        return tasks.where((t) => !t.completed).toList();
      default:
        return tasks;
    }
  }

  Future<void> _loadPage(int page) async {
    final all = await LocalStorageService.loadAllTasks();
    setState(() => _applyPageFrom(all, page));
  }

  void _nextPage() {
    if (_hasMore && !_loading) _loadPage(_page + 1);
  }

  void _prevPage() {
    if (_page > 1 && !_loading) _loadPage(_page - 1);
  }

  void _sortBy<T extends Comparable>(
    Comparable<T>? Function(Todo t) getField,
    int columnIndex,
  ) async {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = _sortColumnIndex == columnIndex ? !_sortAscending : true;
      tasks.sort((a, b) {
        final av = getField(a);
        final bv = getField(b);
        final result = Comparable.compare(
          av ?? '' as Comparable,
          bv ?? '' as Comparable,
        );
        return _sortAscending ? result : -result;
      });
      TaskStore.set(tasks);
    });
    // Persist sorted order within the full list
    final all = await LocalStorageService.loadAllTasks();
    final start = (_page - 1) * _limit;
    for (int i = 0; i < tasks.length; i++) {
      if (start + i < all.length) all[start + i] = tasks[i];
    }
    await LocalStorageService.saveAllTasks(all);
  }

  void _openAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final controller = ScrollController();
        final theme = Theme.of(context);
        final surface = theme.cardColor;
        final shadow = theme.brightness == Brightness.dark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.08);
        final border = theme.dividerColor;
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(top: BorderSide(color: border)),
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: AddTaskModal(
                  onTaskAdded: (taskData) async {
                    final all = await LocalStorageService.loadAllTasks();
                    final startIso = taskData['startDate'] as String?;
                    final dueIso = taskData['dueDate'] as String?;
                    final newId =
                        (all.isNotEmpty
                            ? all
                                  .map((t) => t.id)
                                  .reduce((a, b) => a > b ? a : b)
                            : 0) +
                        1;
                    final newTask = Todo(
                      id: newId,
                      title: taskData['title'] ?? '',
                      completed: false,
                      description:
                          (taskData['description'] as String?)?.isEmpty == true
                          ? null
                          : taskData['description'],
                      startDate: startIso != null
                          ? DateTime.tryParse(startIso)
                          : null,
                      dueDate: dueIso != null
                          ? DateTime.tryParse(dueIso)
                          : null,
                      priority: taskData['priority'] ?? 'Medium',
                      tags: List<String>.from(
                        taskData['tags'] ?? const <String>[],
                      ),
                      subtasks:
                          (taskData['subtasks'] as List? ?? const <dynamic>[])
                              .map(
                                (s) => SubTask(
                                  title: (s['title'] ?? '').toString(),
                                  done: (s['completed'] ?? false) as bool,
                                ),
                              )
                              .toList(),
                    );
                    all.insert(0, newTask);
                    await LocalStorageService.saveAllTasks(all);
                    if (!mounted) return;
                    setState(() => _applyPageFrom(all, 1));
                    ToastService.success('Task created');
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCompleteBadge(bool completed) {
    final text = completed ? 'Task is completed' : 'Task marked incomplete';
    final icon = completed ? Icons.check_circle : Icons.radio_button_unchecked;
    // Toast only (no SnackBar) to avoid duplicate messages
    if (completed) {
      ToastService.success('Task marked complete');
    } else {
      ToastService.info('Task marked incomplete');
    }
  }

  Future<void> _confirmDelete(Todo task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
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
    if (confirmed == true) {
      final all = await LocalStorageService.loadAllTasks();
      all.removeWhere((t) => t.id == task.id);
      await LocalStorageService.saveAllTasks(all);
      if (!mounted) return;
      setState(() => _applyPageFrom(all, _page));
      ToastService.warning('Task deleted');
    }
  }

  void _toggleComplete(Todo task, bool value) async {
    final all = await LocalStorageService.loadAllTasks();
    final idx = all.indexWhere((t) => t.id == task.id);
    if (idx != -1) all[idx] = all[idx].copyWith(completed: value);
    await LocalStorageService.saveAllTasks(all);
    if (!mounted) return;
    setState(() => _applyPageFrom(all, _page));
    _showCompleteBadge(value);
  }

  Future<void> _goToDetail(Todo task, {bool startInEdit = false}) async {
    final result = await Navigator.pushNamed(
      context,
      '/task',
      arguments: {'task': task, 'edit': startInEdit},
    );
    if (!mounted) return;
    if (result is Todo) {
      final all = await LocalStorageService.loadAllTasks();
      final idx = all.indexWhere((t) => t.id == result.id);
      if (idx != -1) all[idx] = result;
      await LocalStorageService.saveAllTasks(all);
      setState(() => _applyPageFrom(all, _page));
      // No toast here; TaskDetailScreen will have shown it already
    } else if (result is Map && result['delete'] == true) {
      final all = await LocalStorageService.loadAllTasks();
      all.removeWhere((t) => t.id == result['id'] as int);
      await LocalStorageService.saveAllTasks(all);
      setState(() => _applyPageFrom(all, _page));
      // No toast here; TaskDetailScreen will have shown it already
    }
  }

  void _editTask(Todo task) => _goToDetail(task, startInEdit: true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color tableHeader = theme.brightness == Brightness.dark
        ? const Color(0xFF1F2937)
        : Colors.indigo.shade50;
    final Color zebra = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.03)
        : Colors.indigo.shade50.withOpacity(0.35);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final shown = _visibleTasks.length; // on this page, post-filter
    final pageCount = tasks.length; // items in current page
    final completedOnPage = tasks.where((t) => t.completed).length;
    final start = _totalCount == 0 ? 0 : (_page - 1) * _limit + 1;
    final end = _totalCount == 0 ? 0 : (start + pageCount - 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Task Manager')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: theme.brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.25)
                              : Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: _filter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filter = v ?? 'All'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Showing $start-$end of $_totalCount  •  This page: $shown/$pageCount (Completed: $completedOnPage)',
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _openAddTaskModal,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Task'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: _tableMinWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(tableHeader),
                  columns: [
                    DataColumn(label: Text('ID', style: headerStyle)),
                    DataColumn(
                      label: Row(
                        children: [
                          const Text('Title'),
                          const SizedBox(width: 6),
                          const Icon(Icons.unfold_more, size: 16),
                        ],
                      ),
                      onSort: (i, _) => _sortBy<String>((t) => t.title, i),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          const Text('Priority'),
                          const SizedBox(width: 6),
                          const Icon(Icons.unfold_more, size: 16),
                        ],
                      ),
                      numeric: false,
                      onSort: (i, _) => _sortBy<String>((t) => t.priority, i),
                    ),
                    DataColumn(label: Text('Status', style: headerStyle)),
                    DataColumn(label: Text('Due', style: headerStyle)),
                    DataColumn(label: Text('Actions', style: headerStyle)),
                  ],
                  rows: List<DataRow>.generate(_visibleTasks.length, (index) {
                    final t = _visibleTasks[index];
                    final zebraColor = index % 2 == 1
                        ? zebra
                        : Colors.transparent;
                    final priorityBg = t.priority == 'High'
                        ? (theme.brightness == Brightness.dark
                              ? Colors.red.withOpacity(0.12)
                              : Colors.red.shade50)
                        : t.priority == 'Low'
                        ? (theme.brightness == Brightness.dark
                              ? Colors.green.withOpacity(0.12)
                              : Colors.green.shade50)
                        : (theme.brightness == Brightness.dark
                              ? Colors.orange.withOpacity(0.12)
                              : Colors.orange.shade50);
                    final priorityFg = t.priority == 'High'
                        ? (theme.brightness == Brightness.dark
                              ? Colors.redAccent
                              : Colors.red.shade700)
                        : t.priority == 'Low'
                        ? (theme.brightness == Brightness.dark
                              ? Colors.greenAccent
                              : Colors.green.shade700)
                        : (theme.brightness == Brightness.dark
                              ? Colors.orangeAccent
                              : Colors.orange.shade700);
                    return DataRow(
                      color: WidgetStateProperty.all(zebraColor),
                      cells: [
                        DataCell(Text('#${t.id}')),
                        DataCell(
                          Text(
                            t.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              decoration: t.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: priorityBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.priority,
                              style: TextStyle(color: priorityFg),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Checkbox(
                                value: t.completed,
                                onChanged: (v) =>
                                    _toggleComplete(t, v ?? false),
                              ),
                              Text(t.completed ? 'Completed' : 'Pending'),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            t.dueDate != null
                                ? '${t.dueDate!.year}-${t.dueDate!.month.toString().padLeft(2, '0')}-${t.dueDate!.day.toString().padLeft(2, '0')}'
                                : '-',
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              switch (v) {
                                case 'view':
                                  _goToDetail(t);
                                  break;
                                case 'edit':
                                  _editTask(t);
                                  break;
                                case 'complete':
                                  _toggleComplete(t, true);
                                  break;
                                case 'incomplete':
                                  _toggleComplete(t, false);
                                  break;
                                case 'delete':
                                  _confirmDelete(t);
                                  break;
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: ListTile(
                                  leading: Icon(Icons.open_in_new),
                                  title: Text('View'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Edit'),
                                ),
                              ),
                              PopupMenuItem(
                                value: t.completed ? 'incomplete' : 'complete',
                                child: ListTile(
                                  leading: Icon(
                                    t.completed
                                        ? Icons.radio_button_unchecked
                                        : Icons.check_circle,
                                  ),
                                  title: Text(
                                    t.completed
                                        ? 'Mark Incomplete'
                                        : 'Mark Complete',
                                  ),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_forever),
                                  title: Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Page $_page'),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Prev',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _page > 1 && !_loading ? _prevPage : null,
                ),
                IconButton(
                  tooltip: 'Next',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _hasMore && !_loading ? _nextPage : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
