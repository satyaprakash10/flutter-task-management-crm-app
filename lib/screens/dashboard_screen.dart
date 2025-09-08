import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/todo.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/task_store.dart';
import '../widgets/add_task_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<Todo> _all = const [];
  List<Todo> _todos = const [];
  int _page = 1;
  final int _limit = 10;
  bool _hasMore = false;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    final all = await LocalStorageService.loadAllTasks();
    _applyPageFrom(all, _page);
    setState(() => _loading = false);
  }

  void _applyPageFrom(List<Todo> all, int page) {
    _all = all;
    _totalCount = all.length;
    final start = (page - 1) * _limit;
    final end = (start + _limit).clamp(0, all.length);
    _todos = start < all.length ? all.sublist(start, end) : <Todo>[];
    _page = page;
    _hasMore = page * _limit < _totalCount;
    TaskStore.set(_todos);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final all = await LocalStorageService.loadAllTasks();
    setState(() {
      _applyPageFrom(all, page);
      _loading = false;
    });
  }

  int get total => _totalCount;
  int get completed => _all.where((t) => t.completed).length;
  int get pending => total - completed;

  List<int> _buckets() {
    final buckets = List<int>.filled(7, 0);
    for (final t in _all) {
      final b = t.id % 7;
      buckets[b] += 1;
    }
    return buckets;
  }

  List<FlSpot> _buildLineSpots() {
    final b = _buckets();
    final allZero = b.every((v) => v == 0);
    final data = allZero ? <int>[0, 0, 0, 0, 0, 0, 0] : b;
    return List<FlSpot>.generate(
      7,
      (i) => FlSpot(i.toDouble(), data[i].toDouble()),
    );
  }

  double _maxY() {
    final b = _buckets();
    final m = b.isEmpty ? 0 : b.reduce((a, c) => a > c ? a : c);
    return (m == 0 ? 6 : m + 1).toDouble();
  }

  void _openTask(Todo t, {bool edit = false}) async {
    await Navigator.pushNamed(
      context,
      '/task',
      arguments: {'task': t, 'edit': edit},
    );
    final all = await LocalStorageService.loadAllTasks();
    if (!mounted) return;
    setState(() => _applyPageFrom(all, _page));
  }

  void _toggleTask(Todo t, bool value) async {
    final all = await LocalStorageService.loadAllTasks();
    final idx = all.indexWhere((x) => x.id == t.id);
    if (idx != -1) all[idx] = all[idx].copyWith(completed: value);
    await LocalStorageService.saveAllTasks(all);
    if (!mounted) return;
    setState(() => _applyPageFrom(all, _page));
  }

  Future<void> _openAddTaskModal() async {
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
                    all.add(newTask);
                    await LocalStorageService.saveAllTasks(all);
                    if (!mounted) return;
                    setState(() => _applyPageFrom(all, _page));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statCardBox({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.cardColor;
    final badge = isDark ? color.withOpacity(0.22) : color.withOpacity(0.14);
    final border = theme.dividerColor;
    final textColor = theme.textTheme.bodyMedium?.color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badge,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor?.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 2),
                const SizedBox.shrink(),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: _statCardBox(label: label, count: count, icon: icon, color: color),
    );
  }

  LineChartData _buildLineChartData({
    required List<FlSpot> spots,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final gridColor = theme.dividerColor;
    final labelStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final borderColor = theme.dividerColor;
    final lineColor = theme.colorScheme.primary;
    return LineChartData(
      minY: 0,
      maxY: _maxY(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: gridColor, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (v, meta) =>
                Text(v.toInt().toString(), style: labelStyle),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) => Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'D${v.toInt() + 1}',
                style: labelStyle.copyWith(fontSize: 10),
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: borderColor),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          barWidth: 3,
          color: lineColor,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withOpacity(0.12),
          ),
          spots: spots,
        ),
      ],
    );
  }

  BarChartData _buildBarChartData({required List<int> values}) {
    final theme = Theme.of(context);
    final gridColor = theme.dividerColor;
    final labelStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final borderColor = theme.dividerColor;
    final barColor = Colors.orangeAccent;
    final groups = List<BarChartGroupData>.generate(7, (i) {
      final y = values[i].toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: y,
            color: barColor,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return BarChartData(
      minY: 0,
      maxY: _maxY(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: gridColor, strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (v, meta) =>
                Text(v.toInt().toString(), style: labelStyle),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) => Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'D${v.toInt() + 1}',
                style: labelStyle.copyWith(fontSize: 10),
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: borderColor),
      ),
      barGroups: groups,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser.value;
    final theme = Theme.of(context);
    final surface = theme.cardColor;
    final shadow = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.06);

    final lineChartCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tasks Over Last 7 Days (Line Chart)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              _buildLineChartData(
                spots: _buildLineSpots(),
                color: Colors.indigo,
              ),
            ),
          ),
        ],
      ),
    );

    final barChartCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tasks Over Last 7 Days (Bar Chart)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(_buildBarChartData(values: _buckets())),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 720;
        // Welcome card uses themed surface and shadow in both light and dark
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_emotions,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Welcome back, ${user.name}!',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isNarrow) ...[
                _statCardBox(
                  label: 'Total',
                  count: total,
                  icon: Icons.assignment,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _statCardBox(
                  label: 'Pending',
                  count: pending,
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                _statCardBox(
                  label: 'Completed',
                  count: completed,
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ] else ...[
                Row(
                  children: [
                    _statCard(
                      label: 'Total',
                      count: total,
                      icon: Icons.assignment,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      label: 'Pending',
                      count: pending,
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      label: 'Completed',
                      count: completed,
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (isNarrow) ...[
                lineChartCard,
                const SizedBox(height: 16),
                barChartCard,
              ] else ...[
                Row(
                  children: [
                    Expanded(child: lineChartCard),
                    const SizedBox(width: 12),
                    Expanded(child: barChartCard),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Recent Tasks',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _openAddTaskModal,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Task'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (ctx, cons) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: cons.maxWidth),
                          child: _RecentTasksTable(
                            tasks: _todos,
                            onOpen: _openTask,
                            onToggle: _toggleTask,
                          ),
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
                          onPressed: _page > 1 && !_loading
                              ? () => _load(_page - 1)
                              : null,
                        ),
                        IconButton(
                          tooltip: 'Next',
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _hasMore && !_loading
                              ? () => _load(_page + 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentTasksTable extends StatefulWidget {
  final List<Todo> tasks;
  final void Function(Todo t, {bool edit}) onOpen;
  final void Function(Todo t, bool value) onToggle;
  const _RecentTasksTable({
    required this.tasks,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  State<_RecentTasksTable> createState() => _RecentTasksTableState();
}

class _RecentTasksTableState extends State<_RecentTasksTable> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headBg = theme.brightness == Brightness.dark
        ? const Color(0xFF1F2937)
        : Colors.indigo.shade50;
    final hoverBg = theme.colorScheme.primary.withOpacity(0.06);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(headBg),
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Done')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List<DataRow>.generate(widget.tasks.length, (i) {
          final t = widget.tasks[i];
          final hovered = _hoverIndex == i;
          return DataRow(
            color: WidgetStateProperty.all(
              hovered ? hoverBg : Colors.transparent,
            ),
            onSelectChanged: (_) => widget.onOpen(t),
            onLongPress: () => widget.onOpen(t),
            cells: [
              DataCell(Text('#${t.id}')),
              DataCell(
                MouseRegion(
                  onEnter: (_) => setState(() => _hoverIndex = i),
                  onExit: (_) => setState(() => _hoverIndex = null),
                  child: Text(
                    t.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: t.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ),
              DataCell(
                Checkbox(
                  value: t.completed,
                  onChanged: (v) => widget.onToggle(t, v ?? false),
                ),
              ),
              DataCell(
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'view':
                        widget.onOpen(t);
                        break;
                      case 'edit':
                        widget.onOpen(t, edit: true);
                        break;
                      case 'complete':
                        widget.onToggle(t, true);
                        break;
                      case 'incomplete':
                        widget.onToggle(t, false);
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
                          t.completed ? 'Mark Incomplete' : 'Mark Complete',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
