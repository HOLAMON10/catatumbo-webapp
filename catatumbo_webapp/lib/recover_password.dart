import 'package:flutter/material.dart';
import 'api.dart';
import 'dart:convert';

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final TextEditingController tokenCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController pass2Ctrl = TextEditingController();

  String userId = "";
  bool loading = false;
  String message = "";

  // --------------------------------------------------
  // 1️⃣ VERIFY TOKEN
  // --------------------------------------------------
  Future<void> verifyToken() async {
    setState(() {
      message = "";
      loading = true;
    });

    final raw = tokenCtrl.text;
    final token = raw.replaceAll(RegExp(r'\s+'), '');

    print("RAW TOKEN: '$raw'");
    print("CLEAN TOKEN: '$token'");

    if (token.isEmpty) {
      setState(() {
        message = "Enter the 6-digit token.";
        loading = false;
      });
      return;
    }

    try {
      final res = await Api.send(
        'GET',
        '/auth/verifytoken/$token',
        requireAuth: false,
      );

      final data = jsonDecode(res.body);

      if (data['code'] == 'success') {
        setState(() {
          userId = data['detail'];
          message = "Token verified — please enter a new password.";
        });
      } else {
        throw data['detail'];
      }
    } catch (err) {
      setState(() {
        message = "Invalid token: $err";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // --------------------------------------------------
  // 2️⃣ CHANGE PASSWORD
  // --------------------------------------------------
  Future<void> changePassword() async {
    setState(() {
      message = "";
      loading = true;
    });

    final newPass = passCtrl.text.trim();
    final confirmPass = pass2Ctrl.text.trim();

    if (newPass != confirmPass) {
      setState(() {
        message = "Passwords do not match.";
        loading = false;
      });
      return;
    }

    try {
      final res = await Api.send(
        'PUT',
        '/auth/changepassword',
        requireAuth: false,
        payload: {
          "_id": userId,
          "newPassword": newPass,
        },
      );

      final data = jsonDecode(res.body);

      if (data['code'] == 'success') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Password Updated"),
            content: const Text("Your password has been changed."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text("Login"),
              )
            ],
          ),
        );
      } else {
        throw data['detail'];
      }
    } catch (err) {
      setState(() {
        message = "Could not change password: $err";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
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
              BoxShadow(blurRadius: 8, color: Colors.black12)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Recover Password",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: tokenCtrl,
                decoration: const InputDecoration(
                  labelText: "6-digit recovery token",
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: loading ? null : verifyToken,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Verify Token"),
              ),

              const SizedBox(height: 20),

              if (userId.isNotEmpty) ...[
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: "New Password"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: pass2Ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: loading ? null : changePassword,
                  child: const Text("Change Password"),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
