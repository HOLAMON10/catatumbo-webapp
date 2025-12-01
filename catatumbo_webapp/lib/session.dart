import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;

import 'api.dart';
import 'models/user.dart';

class Session {
  static String? jwt;
  static int? expiry;
  static String? userId; // decoded from JWT

  static bool get hasToken => jwt != null && jwt!.isNotEmpty;

  static bool get isExpired {
    if (expiry == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiry!;
  }

  static Future<void> save() async {
    html.window.localStorage['jwt'] = jwt ?? '';
    html.window.localStorage['expiry'] = expiry?.toString() ?? '';
  }

  // ✅ BULLETPROOF SESSION LOAD (NO MORE INFINITE HANGS)
  static Future<void> load() async {
    try {
      print("🔵 LOADING SESSION");

      jwt = html.window.localStorage['jwt'];
      final expStr = html.window.localStorage['expiry'];

      print("jwt raw = '$jwt'");
      print("expiry raw = '$expStr'");

      // ------------------------------
      // ❌ Missing session data
      // ------------------------------
      if (jwt == null || jwt!.isEmpty || expStr == null || expStr.isEmpty) {
        print("❌ Session incomplete — clearing");
        clear();
        UserData.clear();
        return;
      }

      expiry = int.tryParse(expStr);
      print("🟢 Parsed expiry = $expiry");

      // ------------------------------
      // ❌ Expired token
      // ------------------------------
      if (isExpired) {
        print("❌ Token expired — clearing");
        clear();
        UserData.clear();
        return;
      }

      // ------------------------------
      // ✅ Decode JWT → extract userId
      // ------------------------------
      final parts = jwt!.split('.');
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      userId = payload["user"];
      print("🟢 Extracted userId = $userId");

      // ------------------------------
      // ✅ Fetch user from backend (WITH TIMEOUT)
      // ------------------------------
      final response = await Api.send(
        "POST",
        "/users/search",
        payload: {"_id": userId},
      ).timeout(const Duration(seconds: 10)); // 🔥 HARD STOP

      final body = jsonDecode(response.body);
      final list = body["detail"] as List;

      if (list.isNotEmpty) {
        UserData.setFromJson(list.first);
        print("🟢 User loaded: ${UserData.email}");
      } else {
        print("❌ No user for this ID — clearing");
        clear();
        UserData.clear();
      }
    }

    // ------------------------------
    // ⏱️ Network Timeout Protection
    // ------------------------------
    on TimeoutException {
      print("⏱️ Session load timed out — forcing logout");
      clear();
      UserData.clear();
    }

    // ------------------------------
    // ❌ Absolute Safety Net
    // ------------------------------
    catch (e) {
      print("❌ Session load fatal error: $e");
      clear();
      UserData.clear();
    }
  }

  static Future<void> clear() async {
    html.window.localStorage.remove('jwt');
    html.window.localStorage.remove('expiry');
    jwt = null;
    expiry = null;
    userId = null;
  }
}
