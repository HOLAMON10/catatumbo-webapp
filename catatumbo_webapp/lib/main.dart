import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session.dart';
import 'login.dart';
import 'dashboard.dart';
import 'placeholderpage.dart';
import 'users_page.dart';
import 'access_profile.dart';
import 'auth_guard.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Session.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // If logged in → start at dashboard
      // If not → start at login
      initialRoute: Session.hasToken && !Session.isExpired
          ? '/dashboard'
          : '/',

      routes: {
        '/': (context) => const HomePage(),
        '/dashboard': (context) => AuthGuard(child: const DashboardPage()),
        '/users': (context) => AuthGuard(child: const UsersPage()),
        '/access-profiles': (context) => AuthGuard(child: const AccessProfilesPage()),
        '/employees': (context) => AuthGuard(child: const PlaceholderPage("Employees")),
      }

    );
  }
}
