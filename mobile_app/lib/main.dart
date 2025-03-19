import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:letsgo/providers/auth_provider.dart';
import 'package:letsgo/providers/trip_provider.dart';
import 'package:letsgo/providers/payment_provider.dart';
import 'package:letsgo/providers/chat_provider.dart';
import 'package:letsgo/providers/review_provider.dart';
import 'package:letsgo/providers/notification_provider.dart';
import 'package:letsgo/screens/splash_screen.dart';
import 'package:letsgo/services/notification_handler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationHandler = NotificationHandlerService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'LetsGo',
        navigatorKey: notificationHandler.navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
