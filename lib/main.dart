import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/theme_provider.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/view/login_screen.dart';
import 'features/dashboard/view/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ToolboxApp(),
    ),
  );
}

class ToolboxApp extends ConsumerWidget {
  const ToolboxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);

    return MaterialApp(
      title: 'Toolbox Pro',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: authState.isAuthenticated 
          ? const DashboardScreen(key: ValueKey('Dashboard')) 
          : const LoginScreen(key: ValueKey('Login')),
    );
  }
}
