import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Add this import

import 'session.dart';
import 'login.dart';
import 'dashboard.dart';
import 'placeholderpage.dart';
import 'users_page.dart';
import 'access_profile.dart';
import 'auth_guard.dart';
import 'verification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure URL strategy to remove the # from URLs
  usePathUrlStrategy(); // Add this line
  
  await dotenv.load(fileName: ".env");
  await Session.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        print('🔍 Route requested: ${settings.name}');
        final uri = Uri.parse(settings.name ?? '');
        print('🔍 Parsed path: ${uri.path}');
        print('🔍 Query params: ${uri.queryParameters}');

        // Handle verification page
        if (uri.path == '/verify' && uri.queryParameters.containsKey('token')) {
          final token = uri.queryParameters['token']!;
          print('✅ Verification route matched! Token: $token');

          return MaterialPageRoute(
            builder: (_) => VerifyAndSetPasswordPage(token: token),
            settings: settings,
          );
        }

        print('⚠️ Verification route NOT matched, falling through...');

        // Standard named routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomePage());

          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => AuthGuard(child: const DashboardPage()),
            );

          case '/users':
            return MaterialPageRoute(
              builder: (_) => AuthGuard(child: const UsersPage()),
            );

          case '/access-profiles':
            return MaterialPageRoute(
              builder: (_) => AuthGuard(child: const AccessProfilesPage()),
            );

          case '/employees':
            return MaterialPageRoute(
              builder: (_) =>
                  AuthGuard(child: const PlaceholderPage("Employees")),
            );
        }

        return MaterialPageRoute(builder: (_) => const HomePage());
      },
    );
  }
}