import 'dart:convert';

import 'package:flutter/material.dart';
import 'api.dart';
import 'session.dart';
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
  bool _obscurePassword = true; // Added for password visibility toggle

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
          payload: {'email': emailCtrl.text},
        );

        final body = jsonDecode(userResponse.body);
        final List<dynamic> details = body['detail'];
        final Map<String, dynamic> userMap = details[0];

        UserData.setFromJson(userMap);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
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
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // RECOVERY EMAIL
  // --------------------------------------------------------------------------
Future<void> sendRecoveryEmail(String email) async {
  try {
    final res = await Api.send(
      'PUT',
      '/auth/createrecoverypasswordtoken',
      requireAuth: false,
      payload: {'email': email.trim()},
    );

    final data = jsonDecode(res.body);

    if (data['code'] == 'success') {
      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Correo enviado",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Si el correo existe, se ha enviado un código de recuperación de 6 dígitos.",
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      throw data['detail'];
    }
  } catch (err) {
    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Error",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "No se pudo enviar el correo de recuperación: $err",
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


  // --------------------------------------------------------------------------
  // FORGOT PASSWORD DIALOG (NARROWED)
  // --------------------------------------------------------------------------
  void openForgotPasswordDialog() {
    final TextEditingController forgotCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recuperar contraseña",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: forgotCtrl,
                  decoration: const InputDecoration(
                    labelText: "Correo electrónico",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        sendRecoveryEmail(forgotCtrl.text);
                      },
                      child: const Text("Enviar"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF4F5F7),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Accede al panel",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Administra empleados, perfiles de acceso\n"
                    "y visualiza los analíticos en un solo lugar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: 420,
                    height: 420,
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Iniciar sesión",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Usa tus credenciales corporativas.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextField(
                              controller: emailCtrl,
                              decoration: InputDecoration(
                                labelText: "Correo electrónico",
                                prefixIcon: const Icon(
                                  Icons.alternate_email_outlined,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: passCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),

                            TextButton(
                              onPressed: openForgotPasswordDialog,
                              child: const Text(
                                "¿Olvidaste tu contraseña?",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 6),

                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: loading ? null : login,
                                child: loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        "Ingresar",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            if (message.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}