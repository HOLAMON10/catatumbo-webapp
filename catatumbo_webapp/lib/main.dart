import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session.dart';
import 'login.dart';
import 'dashboard.dart';
import 'placeholderpage.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Session.load(); // load token from localStorage

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
        '/dashboard': (context) => const DashboardPage(),

        '/users': (context) => const PlaceholderPage("Users"),
        '/access-profiles': (context) => const PlaceholderPage("Access Profiles"),
        '/employees': (context) => const PlaceholderPage("Employees"),
      }
    );
  }
}
