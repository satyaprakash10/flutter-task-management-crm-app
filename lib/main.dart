import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/task_detail_screen.dart';
import 'widgets/app_shell.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'services/auth_service.dart';
import 'widgets/toast.dart';
import 'services/theme_service.dart';
import 'screens/landing_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await ThemeService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF0EA5E9); // Sky 500
    const appBarBg = Color(0xFF1E293B); // Slate 800
    const surfaceAlt = Color(0xFFF1F5F9); // Slate 50

    // Listen and greet on login
    AuthService.currentUser.addListener(() {
      final user = AuthService.currentUser.value;
      if (user != null) {
        ToastService.success('Welcome, ${user.name}!');
      }
    });

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      scaffoldBackgroundColor: Colors.white,
      drawerTheme: const DrawerThemeData(backgroundColor: surfaceAlt),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceAlt,
        selectedIconTheme: const IconThemeData(color: brand),
        selectedLabelTextStyle: const TextStyle(
          color: brand,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: brand.withOpacity(0.12),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.black87,
        textColor: Colors.black87,
      ),
      cardTheme: const CardThemeData(color: Colors.white, elevation: 0),
      dividerColor: Colors.black12,
      dataTableTheme: const DataTableThemeData(),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        labelStyle: const TextStyle(color: Colors.black87),
        selectedColor: brand.withOpacity(0.16),
        side: BorderSide(color: Colors.black12),
      ),
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    ).copyWith(surface: const Color(0xFF111827));

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B1220),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF111827),
      dividerColor: Colors.white12,
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white70,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF111827)),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF111827),
        selectedIconTheme: const IconThemeData(color: brand),
        selectedLabelTextStyle: const TextStyle(
          color: brand,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: brand.withOpacity(0.22),
        unselectedIconTheme: const IconThemeData(color: Colors.white70),
        unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.resolveWith(
          (_) => const Color(0xFF1F2937),
        ),
        dataTextStyle: const TextStyle(color: Colors.white70),
        headingTextStyle: const TextStyle(color: Colors.white),
        dividerThickness: 0.6,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF1F2937),
        labelStyle: TextStyle(color: Colors.white70),
        selectedColor: Color(0xFF0EA5E9),
        secondarySelectedColor: Color(0xFF0EA5E9),
        side: BorderSide(color: Colors.white12),
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AuthService.ready,
          builder: (context, authReady, __) {
            if (!authReady) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeMode,
                home: const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            return MaterialApp(
              title: 'Flutter Todo Demo',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
              routes: {
                '/signin': (_) => const SignInScreen(),
                '/signup': (_) => const SignUpScreen(),
                '/landing': (_) => const LandingScreen(),
              },
              onGenerateRoute: (settings) {
                bool authed = AuthService.currentUser.value != null;
                bool needsAuth(String? name) {
                  return name == '/dashboard' ||
                      name == '/' ||
                      name == '/tasks' ||
                      name == '/settings' ||
                      name == '/task';
                }

                final name = settings.name;
                if (!authed && needsAuth(name)) {
                  return MaterialPageRoute(
                    builder: (_) => const LandingScreen(),
                  );
                }

                switch (name) {
                  case '/dashboard':
                    return MaterialPageRoute(
                      builder: (_) => const AppShell(
                        selectedIndex: 0,
                        title: 'Dashboard',
                        body: DashboardScreen(),
                      ),
                    );
                  case '/':
                  case '/tasks':
                    return MaterialPageRoute(
                      builder: (_) => AppShell(
                        selectedIndex: 1,
                        title: 'Tasks',
                        body: HomeScreen(),
                      ),
                    );
                  case '/settings':
                    return MaterialPageRoute(
                      builder: (_) => const AppShell(
                        selectedIndex: 2,
                        title: 'Settings',
                        body: SettingsScreen(),
                      ),
                    );
                  case '/task':
                    {
                      final args = settings.arguments;
                      if (args is Map && args.containsKey('task')) {
                        return MaterialPageRoute(
                          builder: (_) => AppShell(
                            selectedIndex: 1,
                            title: 'Task',
                            body: TaskDetailScreen(task: args['task']),
                          ),
                          settings: settings,
                        );
                      }
                      return MaterialPageRoute(
                        builder: (_) => const LandingScreen(),
                      );
                    }
                }
                return null;
              },
              builder: (ctx, child) {
                return Stack(
                  children: [child ?? const SizedBox.shrink(), const Toaster()],
                );
              },
            );
          },
        );
      },
    );
  }
}
