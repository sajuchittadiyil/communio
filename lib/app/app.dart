import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import '../features/authentication/screens/login_screen.dart';

class CommunioApp extends StatelessWidget {
  const CommunioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Communio',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      home: const LoginScreen(),
    );
  }
}