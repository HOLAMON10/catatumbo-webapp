import 'package:flutter/material.dart';
import 'session.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    // Wait ONE frame before checking session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _ready = true;
      });
    });
  }

  bool get isSessionValid {
    if (Session.jwt == null ||
        Session.jwt!.isEmpty ||
        Session.expiry == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return Session.expiry! > now;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isSessionValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Session.clear();
        Navigator.pushReplacementNamed(context, '/');
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.child;
  }
}
