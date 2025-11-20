import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';

class VerifyAndSetPasswordPage extends StatefulWidget {
  final String token;

  const VerifyAndSetPasswordPage({super.key, required this.token});

  @override
  State<VerifyAndSetPasswordPage> createState() =>
      _VerifyAndSetPasswordPageState();
}

class _VerifyAndSetPasswordPageState extends State<VerifyAndSetPasswordPage> {
  bool loading = true;
  bool tokenValid = false;

  String? userId;

  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    verifyToken();
  }

  Future<void> verifyToken() async {
    try {
      final response = await Api.send(
        'GET',
        '/auth/verifytoken/${widget.token}',
        requireAuth: false,
      );

      final decoded = jsonDecode(response.body);

      if (decoded['code'] == 'success') {
        setState(() {
          tokenValid = true;
          userId = decoded['detail']; // backend returns ONLY the id now
        });
      } else {
        setState(() => tokenValid = false);
      }
    } catch (_) {
      setState(() => tokenValid = false);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> changePassword() async {
    final password = passCtrl.text;
    final confirm = confirmCtrl.text;

    if (password != confirm) {
      showMsg("Passwords do not match");
      return;
    }

    if (userId == null) {
      showMsg("Invalid user");
      return;
    }

    try {
      final response = await Api.send(
        'PUT',
        '/auth/changepassword',
        requireAuth: false,
        payload: {
          '_id': userId,
          'currentPassword': password,
          'newPassword': password,
        },
      );

      final decoded = jsonDecode(response.body);

      if (decoded['code'] != 'error') {
        showMsg("Password updated successfully!");
      } else {
        showMsg("Failed to update password");
      }
    } catch (ex) {
      showMsg("Error updating password");
    }
  }

  void showMsg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!tokenValid) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Invalid or expired verification link.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                "Set Your Password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // password
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // confirm password
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: changePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                child: const Text("Set Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
