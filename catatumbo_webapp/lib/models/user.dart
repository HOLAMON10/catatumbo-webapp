import 'dart:convert';
import '../api.dart';
import 'dart:html' as html;

class UserData {
  static String? firstName;
  static String? lastName;
  static String email = '';
  static dynamic accessProfile;
  static List<String>? allowedPermissions;
  static dynamic userType;

  static void setFromJson(Map<String, dynamic> json) {
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    accessProfile = json['accessProfile'];
    allowedPermissions = json['allowedPermissions'] != null
        ? List<String>.from(json['allowedPermissions'])
        : null;
    userType = json['userType'];
  }
  static Future<void> loadProfile() async {
    final userId = html.window.localStorage['userId'];

    if (userId == null || userId.isEmpty) return;

    final response = await Api.send(
      'POST',
      '/users/search',
      payload: { "_id": userId },   // ⭐ SAFE — EXACT MATCH ONLY
    );

    final data = jsonDecode(response.body);
    final detail = data['detail'];

    if (detail is List && detail.isNotEmpty) {
      setFromJson(detail[0]);
    }
  }

  static void clear() {
    firstName = null;
    lastName = null;
    email = '';
    accessProfile = null;
    allowedPermissions = null;
    userType = null;
  }
}
