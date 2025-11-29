class UserData {
  static String? firstName;
  static String? lastName;
  static String email = '';
  static dynamic accessProfile;
  static List<String>? allowedPermissions;
  static dynamic userType;
  static String? dashboard;

  static void setFromJson(Map<String, dynamic> json) {
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    accessProfile = json['accessProfile'];
    allowedPermissions = json['allowedPermissions'] != null
        ? List<String>.from(json['allowedPermissions'])
        : null;
    userType = json['userType'];
    dashboard = json['dashboardUrl'];
  }

  static void clear() {
    firstName = null;
    lastName = null;
    email = '';
    accessProfile = null;
    allowedPermissions = null;
    userType = null;
    dashboard = null;
  }
}
