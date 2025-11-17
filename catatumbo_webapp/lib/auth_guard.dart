import 'package:flutter/material.dart';
import 'session.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  bool get isSessionValid {
    if (!Session.hasToken || Session.expiry == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return Session.expiry! > now;
  }

  @override
  Widget build(BuildContext context) {
    if (!isSessionValid) {
      Future.microtask(() async {
        await Session.clear();
        Navigator.pushReplacementNamed(context, '/');
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return child;
  }
}
