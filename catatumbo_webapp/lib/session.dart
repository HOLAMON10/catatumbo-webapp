import 'dart:convert';
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

  // ⭐ THIS NOW RESTORES USER DATA AUTOMATICALLY
  static Future<void> load() async {
    jwt = html.window.localStorage['jwt'];
    final expStr = html.window.localStorage['expiry'];

    print("🔵 LOADING SESSION");
    print("jwt raw = '$jwt'");
    print("expiry raw = '$expStr'");

    // If nothing stored → end session
    if (jwt == null || jwt!.isEmpty || expStr == null || expStr.isEmpty) {
      print("❌ Session incomplete — clearing");
      clear();
      UserData.clear();
      return;
    }

    expiry = int.tryParse(expStr);
    print("🟢 Parsed expiry = $expiry");

    // Check expiration
    if (isExpired) {
      print("❌ Token expired — clearing");
      clear();
      UserData.clear();
      return;
    }

    // ------------------------------
    // ⭐ Decode JWT → extract userId
    // ------------------------------
    try {
      final parts = jwt!.split('.');
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      userId = payload["user"];
      print("🟢 Extracted userId = $userId");
    } catch (e) {
      print("❌ Failed decoding JWT: $e");
      clear();
      UserData.clear();
      return;
    }

    // ------------------------------
    // ⭐ Fetch user from backend
    // ------------------------------
    try {
      final response = await Api.send(
        "POST",
        "/users/search",
        payload: {"_id": userId},
      );

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
    } catch (e) {
      print("❌ Could not fetch user: $e");
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
