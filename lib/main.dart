import 'package:flutter/material.dart';

import 'models/auth.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.instance.restoreSession();
  runApp(const SSTApp());
}

class SSTApp extends StatelessWidget {
  const SSTApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SST Capacitacion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        fontFamily: 'Roboto',
      ),
      home: ValueListenableBuilder<UserProfile?>(
        valueListenable: SessionManager.instance.userNotifier,
        builder: (context, user, _) {
          if (!SessionManager.instance.isReady) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (user == null) {
            return const LoginScreen();
          }
          return const DashboardScreen();
        },
      ),
    );
  }
}
