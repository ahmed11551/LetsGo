import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:letsgo/providers/auth_provider.dart';
import 'package:letsgo/providers/notification_provider.dart';
import 'package:letsgo/screens/auth/login_screen.dart';
import 'package:letsgo/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Инициализируем уведомления
    await notificationProvider.initialize();

    // Проверяем авторизацию
    final isAuthenticated = await authProvider.checkAuth();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isAuthenticated ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 