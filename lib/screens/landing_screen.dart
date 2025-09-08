import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SvgPicture.asset(
                'assets/icons/task.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const Text('Todo Demo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signin'),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: Icon(
              ThemeService.mode.value == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => ThemeService.set(
              ThemeService.mode.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _HeroSimple(),
            SizedBox(height: 16),
            _WorkflowSection(),
            SizedBox(height: 16),
            _LineChartSection(),
            SizedBox(height: 16),
            _BarChartSection(),
            SizedBox(height: 16),
            _FooterSimple(),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _HeroSimple extends StatelessWidget {
  const _HeroSimple();
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: LayoutBuilder(
        builder: (context, c) {
          final isNarrow = c.maxWidth < 900;
          final image = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/shots/tasks_table.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, s) => Container(
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, size: 48),
              ),
            ),
          );
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Tasks Effortlessly',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'From idea to done: create tasks with rich details, prioritize with drag-and-drop, and track progress with live charts. All responsive and theme-aware.',
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/signin'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Get Started'),
              ),
            ],
          );
          if (isNarrow) {
            return Column(children: [image, const SizedBox(height: 12), text]);
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(aspectRatio: 16 / 9, child: image),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkflowSection extends StatefulWidget {
  const _WorkflowSection();
  @override
  State<_WorkflowSection> createState() => _WorkflowSectionState();
}

class _WorkflowSectionState extends State<_WorkflowSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'A lightweight flow that keeps you in control: sign in, add tasks, prioritize, and complete. No clutter, just speed.',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Step(
                icon: Icons.login,
                label: 'Sign in',
                ac: _ac,
                color: theme.colorScheme.primary,
              ),
              _Arrow(ac: _ac),
              _Step(
                icon: Icons.add_task,
                label: 'Create tasks',
                ac: _ac,
                color: Colors.green,
              ),
              _Arrow(ac: _ac),
              _Step(
                icon: Icons.drag_indicator,
                label: 'Prioritize',
                ac: _ac,
                color: Colors.orange,
              ),
              _Arrow(ac: _ac),
              _Step(
                icon: Icons.check_circle,
                label: 'Complete',
                ac: _ac,
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String label;
  final AnimationController ac;
  final Color color;
  const _Step({
    required this.icon,
    required this.label,
    required this.ac,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.95,
          end: 1.05,
        ).animate(CurvedAnimation(parent: ac, curve: Curves.easeInOut)),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final AnimationController ac;
  const _Arrow({required this.ac});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.4,
          end: 1.0,
        ).animate(CurvedAnimation(parent: ac, curve: Curves.easeInOut)),
        child: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class _LineChartSection extends StatelessWidget {
  const _LineChartSection();
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: LayoutBuilder(
        builder: (context, c) {
          final isNarrow = c.maxWidth < 900;
          final desc = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Line Chart'),
              SizedBox(height: 6),
              Text(
                'Understand daily momentum: the line chart highlights task throughput trends. Hover on web or tap in app to explore values.',
              ),
            ],
          );
          final shot = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/shots/line_chart.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, s) => _ShotFallback(title: 'Line Chart'),
            ),
          );
          if (isNarrow) {
            return Column(children: [shot, const SizedBox(height: 12), desc]);
          }
          return Row(
            children: [
              Expanded(child: desc),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(aspectRatio: 16 / 9, child: shot),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BarChartSection extends StatelessWidget {
  const _BarChartSection();
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: LayoutBuilder(
        builder: (context, c) {
          final isNarrow = c.maxWidth < 900;
          final desc = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Bar Chart'),
              SizedBox(height: 6),
              Text(
                'Spot volume at a glance: the bar chart compares tasks created per day to help balance workloads and deadlines.',
              ),
            ],
          );
          final shot = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/shots/bar_chart.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, s) => _ShotFallback(title: 'Bar Chart'),
            ),
          );
          if (isNarrow) {
            return Column(children: [shot, const SizedBox(height: 12), desc]);
          }
          return Row(
            children: [
              Expanded(child: desc),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(aspectRatio: 16 / 9, child: shot),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShotFallback extends StatelessWidget {
  final String title;
  const _ShotFallback({required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }
}

class _FooterSimple extends StatelessWidget {
  const _FooterSimple();
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('© ${DateTime.now().year} Todo Demo'));
  }
}
