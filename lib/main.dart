import 'package:flutter/material.dart';
import 'theme.dart';
import 'auth_gate_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PassKeepApp());
}

class PassKeepApp extends StatelessWidget {
  const PassKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PassKeep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGateScreen(),
    );
  }
}
