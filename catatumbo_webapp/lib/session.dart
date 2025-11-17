import 'dart:html' as html;

class Session {
  static String? jwt;
  static int? expiry;

  static bool get hasToken => jwt != null;
  static bool get isExpired {
    if (expiry == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiry!;
  }

  static Future<void> save() async {
    html.window.localStorage['jwt'] = jwt ?? '';
    html.window.localStorage['expiry'] = expiry?.toString() ?? '';
  }

  static Future<void> load() async {
    jwt = html.window.localStorage['jwt'];
    final expStr = html.window.localStorage['expiry'];

    if (jwt == null || expStr == null || expStr.isEmpty) {
      jwt = null;
      expiry = null;
      return;
    }

    expiry = int.tryParse(expStr);
  }
  
  static Future<void> clear() async {
    html.window.localStorage.remove('jwt');
    html.window.localStorage.remove('expiry');
    jwt = null;
    expiry = null;
  }
}
