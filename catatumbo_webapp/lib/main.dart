import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'session.dart';
import 'login.dart';
import 'dashboard.dart';
import 'placeholderpage.dart';
import 'users_page.dart';
import 'access_profile.dart';
import 'auth_guard.dart';
import 'verification.dart';
import 'recover_password.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Correct URL strategy
  setUrlStrategy(PathUrlStrategy());

  await dotenv.load(fileName: ".env");

  await Session.load(); // load user from token

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ⭐ STATIC ROUTES (required by Flutter Web)
      routes: {
        "/": (_) => const HomePage(),
        "/recover": (_) => const RecoverPasswordPage(),
        "/dashboard": (_) => AuthGuard(child: const DashboardPage()),
        "/users": (_) => AuthGuard(child: const UsersPage()),
        "/access-profiles": (_) => AuthGuard(child: const AccessProfilesPage()),
        "/employees": (_) => AuthGuard(child: const PlaceholderPage("Employees")),
      },

      // ⭐ verify token dynamic route
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? "/") ?? Uri(path: "/");

        if (uri.path == "/verify" &&
            uri.queryParameters.containsKey("token")) {
          final token = uri.queryParameters["token"]!;
          return MaterialPageRoute(
            builder: (_) => VerifyAndSetPasswordPage(token: token),
            settings: settings,
          );
        }

        return null; // fallback to static routes
      },
    );
  }
}
