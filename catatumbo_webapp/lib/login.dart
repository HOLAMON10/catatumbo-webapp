import 'package:flutter/material.dart';
import 'api.dart';
import 'session.dart';
import 'dart:convert';
import 'models/user.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool loading = false;
  String message = '';

  // 🌙 SEND LOGIN REQUEST
  Future<void> login() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final response = await Api.send(
        'POST',
        '/auth/verifycredentials',
        requireAuth: false,
        payload: {
          'email': emailCtrl.text,
          'password': passCtrl.text,
        },
      );

      final data = jsonDecode(response.body);

      if (data['code'] == 'success') {
        final token = data['detail'];

        final parts = token.split('.');
        final normalized = base64Url.normalize(parts[1]);
        final payload =
            jsonDecode(utf8.decode(base64Url.decode(normalized)));

        Session.jwt = token;
        Session.expiry = payload['exp'];
        await Session.save();

        final userResponse = await Api.send(
          'POST',
          '/users/search',
          payload: { 'email': emailCtrl.text },
        );

        final body = jsonDecode(userResponse.body);
        final List<dynamic> details = body['detail'];
        final Map<String, dynamic> userMap = details[0];

        UserData.setFromJson(userMap);

        Navigator.pushReplacementNamed(context, '/dashboard');
        return;
      }

      setState(() {
        message = "Login failed: ${data['detail']}";
      });
    } catch (e) {
      setState(() {
        message = "Error: $e";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // 🌙 SEND RECOVERY EMAIL
  Future<void> sendRecoveryEmail(String email) async {
    try {
      final res = await Api.send(
        'PUT',
        '/auth/createrecoverypasswordtoken',
        requireAuth: false,
        payload: { 'email': email.trim() },
      );

      final data = jsonDecode(res.body);

      if (data['code'] == 'success') {
        Navigator.pop(context); // close dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Recovery Email Sent"),
            content: const Text(
              "If the address exists, a 6-digit recovery code "
              "has been sent to your inbox.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      } else {
        throw data['detail'];
      }
    } catch (err) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Could not send recovery email: $err"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  // 🌙 ASK FOR EMAIL POPUP
  void openForgotPasswordDialog() {
    final TextEditingController forgotCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Forgot Password"),
        content: TextField(
          controller: forgotCtrl,
          decoration: const InputDecoration(
            labelText: "Enter your email",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              sendRecoveryEmail(forgotCtrl.text);
            },
            child: const Text("Send"),
          )
        ],
      ),
    );
  }

  // 🌙 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black12,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Login",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Log In"),
              ),
              const SizedBox(height: 14),

              // 🌙 ADD FORGOT PASSWORD BUTTON HERE
              TextButton(
                onPressed: openForgotPasswordDialog,
                child: const Text("Forgot password?"),
              ),

              Text(
                message,
                style: const TextStyle(color: Colors.redAccent),
              )
            ],
          ),
        ),
      ),
    );
  }
}
