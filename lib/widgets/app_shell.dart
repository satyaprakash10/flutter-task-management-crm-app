import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../models/todo.dart';
import '../services/task_store.dart';
import '../services/auth_service.dart';
import '../widgets/toast.dart';
import '../services/theme_service.dart';

class AppShell extends StatefulWidget {
  final int selectedIndex; // 0 Dashboard, 1 Tasks, 2 Settings
  final String title; // used in breadcrumb
  final Widget body;
  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.title,
    required this.body,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _extended = true;
  String _profileSelection = 'profile';

  void _navTo(int index) {
    if (index == widget.selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  void _onProfileSelect(String v) async {
    setState(() => _profileSelection = v);
    switch (v) {
      case 'profile':
        Navigator.pushReplacementNamed(context, '/settings');
        break;
      case 'settings':
        Navigator.pushReplacementNamed(context, '/settings');
        break;
      case 'logout':
        await AuthService.signOut();
        if (!mounted) return;
        ToastService.info('You have been logged out');
        Navigator.pushReplacementNamed(context, '/landing');
        break;
    }
  }

  void _toggleTheme() {
    final m = ThemeService.mode.value;
    if (m == ThemeMode.light) {
      ThemeService.set(ThemeMode.dark);
    } else {
      ThemeService.set(ThemeMode.light);
    }
    setState(() {});
  }

  PopupMenuButton<String> _profilePopup({required double width}) {
    final user = AuthService.currentUser.value;
    final theme = Theme.of(context);
    final bg = theme.cardColor;
    final border = theme.dividerColor;
    return PopupMenuButton<String>(
      onSelected: _onProfileSelect,
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(leading: Icon(Icons.person), title: Text('Profile')),
        ),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(leading: Icon(Icons.logout), title: Text('Logout')),
        ),
      ],
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 12,
                child: Icon(Icons.person, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name : 'Account',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSearch() async {
    final outerCtx = context;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        List<Todo> results = [];
        bool loading = false;
        String query = '';
        int debounceToken = 0;

        final pages = [
          {
            'label': 'Dashboard',
            'route': '/dashboard',
            'icon': Icons.dashboard,
          },
          {'label': 'Tasks', 'route': '/', 'icon': Icons.list_alt},
          {'label': 'Settings', 'route': '/settings', 'icon': Icons.settings},
        ];

        Future<void> runSearch(StateSetter setSB) async {
          final localToken = ++debounceToken;
          final q = query.trim();
          setSB(() => loading = true);
          try {
            // Combine in-memory tasks with API results; de-dupe by id
            final local = TaskStore.current;
            final api = await ApiService.searchTodos(q);
            if (localToken != debounceToken) return; // stale
            final Map<int, Todo> byId = {for (final t in api) t.id: t};
            for (final t in local) {
              if (q.isEmpty ||
                  t.title.toLowerCase().contains(q.toLowerCase()) ||
                  t.id.toString() == q) {
                byId[t.id] = t;
              }
            }
            final next = byId.values.toList()
              ..sort((a, b) => a.id.compareTo(b.id));
            setSB(() {
              results = next;
              loading = false;
            });
          } catch (_) {
            if (localToken != debounceToken) return;
            setSB(() => loading = false);
          }
        }

        return StatefulBuilder(
          builder: (ctx2, setSB) {
            final q = query.trim().toLowerCase();
            final pageMatches = pages
                .where(
                  (p) =>
                      q.isEmpty ||
                      (p['label'] as String).toLowerCase().contains(q),
                )
                .toList();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText:
                                'Search tasks by title or id, or type page name... (Enter)',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                          onChanged: (v) {
                            query = v;
                            Future.delayed(
                              const Duration(milliseconds: 220),
                              () => runSearch(setSB),
                            );
                            setSB(() {});
                          },
                          onSubmitted: (v) {
                            query = v;
                            final exact = pageMatches
                                .where(
                                  (p) =>
                                      (p['label'] as String)
                                          .toLowerCase()
                                          .trim() ==
                                      query.trim().toLowerCase(),
                                )
                                .toList();
                            if (exact.isNotEmpty) {
                              final p = exact.first;
                              Navigator.pop(ctx2);
                              Navigator.pushReplacementNamed(
                                outerCtx,
                                p['route'] as String,
                              );
                              return;
                            }
                            if (results.isNotEmpty) {
                              final todo = results.first;
                              Navigator.pop(ctx2);
                              Navigator.pushNamed(
                                outerCtx,
                                '/task',
                                arguments: {'task': todo},
                              );
                            } else {
                              runSearch(setSB);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (pageMatches.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6.0,
                                      horizontal: 4.0,
                                    ),
                                    child: Text(
                                      'Pages',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ...pageMatches.map(
                                  (p) => ListTile(
                                    leading: Icon(p['icon'] as IconData),
                                    title: Text(p['label'] as String),
                                    onTap: () {
                                      Navigator.pop(ctx2);
                                      Navigator.pushReplacementNamed(
                                        outerCtx,
                                        p['route'] as String,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 6.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Text(
                                    'Tasks',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (loading)
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (results.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No matching tasks'),
                                  )
                                else
                                  ...results
                                      .take(20)
                                      .map(
                                        (t) => ListTile(
                                          leading: const Icon(Icons.task_alt),
                                          title: Text(t.title),
                                          subtitle: Text('ID: ${t.id}'),
                                          onTap: () {
                                            Navigator.pop(ctx2);
                                            Navigator.pushNamed(
                                              outerCtx,
                                              '/task',
                                              arguments: {'task': t},
                                            );
                                          },
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _breadcrumb() {
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    Map<String, dynamic>? args;
    final modal = ModalRoute.of(context);
    if (modal != null) args = modal.settings.arguments as Map<String, dynamic>?;

    final atTask = routeName == '/task' && args != null && args['task'] is Todo;
    final Todo? currentTask = atTask ? args['task'] as Todo : null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final crumbColor = isDark ? Colors.lightBlueAccent : Colors.indigo;
    final sepColor = isDark ? Colors.white30 : Colors.black26;
    final bg = theme.cardColor;
    final border = theme.dividerColor;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
              child: Text('Home', style: TextStyle(color: crumbColor)),
            ),
            Text(' / ', style: TextStyle(color: sepColor)),
            InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, '/'),
              child: Text(
                widget.selectedIndex == 1 ? 'Tasks' : widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: crumbColor,
                ),
              ),
            ),
            if (currentTask != null) ...[
              Text(' / ', style: TextStyle(color: sepColor)),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/task',
                  arguments: {'task': currentTask},
                ),
                child: Text(
                  'Task #${currentTask.id}',
                  style: TextStyle(color: crumbColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthed = AuthService.currentUser.value != null;
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 960;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final logo = SvgPicture.asset(
          'assets/icons/task.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        );

        final content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(
              position: offset,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Container(
            key: ValueKey('${widget.selectedIndex}-${widget.title}'),
            color: isDark ? const Color(0xFF0B1220) : Colors.grey.shade50,
            child: widget.body,
          ),
        );

        if (!isWide) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: isAuthed ? Row(children: [logo]) : const SizedBox.shrink(),
              actions: [
                if (isAuthed)
                  IconButton(
                    icon: Icon(
                      ThemeService.mode.value == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    onPressed: _toggleTheme,
                  ),
                if (isAuthed)
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _openSearch,
                  ),
                if (isAuthed)
                  PopupMenuButton<String>(
                    onSelected: _onProfileSelect,
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(
                        value: 'profile',
                        child: ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Profile'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Logout'),
                        ),
                      ),
                    ],
                    child: const CircleAvatar(child: Icon(Icons.person)),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            drawer: Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DrawerHeader(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/task.svg',
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Todo Demo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      selected: widget.selectedIndex == 0,
                      onTap: () => _navTo(0),
                    ),
                    ListTile(
                      leading: const Icon(Icons.list_alt),
                      title: const Text("Tasks"),
                      selected: widget.selectedIndex == 1,
                      onTap: () => _navTo(1),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      selected: widget.selectedIndex == 2,
                      onTap: () => _navTo(2),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _profilePopup(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _breadcrumb(),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: isAuthed ? Row(children: [logo]) : const SizedBox.shrink(),
            actions: [
              if (isAuthed)
                IconButton(
                  icon: Icon(
                    ThemeService.mode.value == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  onPressed: _toggleTheme,
                ),
              if (isAuthed)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _openSearch,
                ),
              if (isAuthed)
                PopupMenuButton<String>(
                  onSelected: _onProfileSelect,
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Profile'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Settings'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                      ),
                    ),
                  ],
                  child: const CircleAvatar(child: Icon(Icons.person)),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              Material(
                elevation: 2,
                color: Theme.of(context).navigationRailTheme.backgroundColor,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          NavigationRail(
                            extended: _extended,
                            minExtendedWidth: 220,
                            selectedIndex: widget.selectedIndex,
                            onDestinationSelected: _navTo,
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.dashboard_outlined),
                                selectedIcon: Icon(Icons.dashboard),
                                label: Text('Dashboard'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.list_alt_outlined),
                                selectedIcon: Icon(Icons.list_alt),
                                label: Text('Tasks'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings_outlined),
                                selectedIcon: Icon(Icons.settings),
                                label: Text('Settings'),
                              ),
                            ],
                          ),
                          Container(
                            width: 28,
                            height: double.infinity,
                            color: Theme.of(
                              context,
                            ).navigationRailTheme.backgroundColor,
                            child: Center(
                              child: IconButton(
                                tooltip: _extended ? 'Collapse' : 'Expand',
                                iconSize: 20,
                                icon: Icon(
                                  _extended
                                      ? Icons.chevron_left
                                      : Icons.chevron_right,
                                ),
                                onPressed: () =>
                                    setState(() => _extended = !_extended),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _profilePopup(width: _extended ? 220 : 72),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _breadcrumb(),
                    Expanded(child: content),
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
