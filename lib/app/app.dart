import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import '../features/authentication/screens/auth_gate.dart';
import '../features/authentication/services/authentication_service.dart';
import '../features/authentication/services/session_store.dart';
import '../features/authentication/state/authentication_controller.dart';
import '../features/authentication/state/authentication_scope.dart';

class CommunioApp extends StatefulWidget {
  const CommunioApp({
    required this.authenticationService,
    required this.sessionStore,
    super.key,
  });

  final AuthenticationService authenticationService;
  final SessionStore sessionStore;

  @override
  State<CommunioApp> createState() => _CommunioAppState();
}

class _CommunioAppState extends State<CommunioApp> {
  late final AuthenticationController _authenticationController;

  @override
  void initState() {
    super.initState();
    _authenticationController = AuthenticationController(
      widget.authenticationService,
      widget.sessionStore,
    );
    _authenticationController.restoreSession();
  }

  @override
  void dispose() {
    _authenticationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticationScope(
      controller: _authenticationController,
      child: MaterialApp(
        title: 'Communio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => Theme(
          data: MediaQuery.sizeOf(context).width < 760
              ? AppTheme.mobile
              : AppTheme.light,
          child: child!,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
