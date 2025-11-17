import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'navbar.dart';
import 'enums/catalogs.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> menuOptions = [];

  bool loadingUsers = true;
  bool loadingMenus = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadMenuOptions();
  }

  // --------------------------------------------------------------------------
  // LOAD USERS (SAFE)
  // --------------------------------------------------------------------------
  Future<void> loadUsers() async {
    try {
      final response = await Api.send(
        'POST',
        '/users/search',
        payload: {},
      );

      final data = jsonDecode(response.body);
      final detail = data['detail'];
      List<Map<String, dynamic>> parsedUsers = [];

      if (detail is List) {
        parsedUsers = detail
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      setState(() {
        users = parsedUsers;
        loadingUsers = false;
      });
    } catch (e, st) {
      print("Error in loadUsers: $e");
      print(st);
      setState(() {
        users = [];
        loadingUsers = false;
      });
    }
  }

  // --------------------------------------------------------------------------
  // LOAD MENU OPTIONS (SAFE)
  // --------------------------------------------------------------------------
  Future<void> loadMenuOptions() async {
    try {
      final res = await Api.send(
        'POST',
        '/accessprofiles/search',
      );

      final body = jsonDecode(res.body);

      final List<dynamic> detailList = body['detail'] ?? [];
      final List<Map<String, dynamic>> parsed =
          detailList.map((e) => Map<String, dynamic>.from(e)).toList();

      setState(() {
        menuOptions = parsed;
        loadingMenus = false;
      });
    } catch (e) {
      print("Error loading menu options: $e");
      setState(() {
        menuOptions = [];
        loadingMenus = false;
      });
    }
  }

  // --------------------------------------------------------------------------
  // DELETE USER
  // --------------------------------------------------------------------------
  Future<void> deleteUser(String id) async {
    try {
      await Api.send('DELETE', '/users/remove/$id');
    } catch (e) {
      print("Error deleting user: $e");
    }
    loadUsers();
  }

  // --------------------------------------------------------------------------
  // CREATE / EDIT MODAL
  // --------------------------------------------------------------------------
 void openUserModal({Map<String, dynamic>? user}) {
  final firstCtrl = TextEditingController(text: user?['firstName'] ?? '');
  final lastCtrl = TextEditingController(text: user?['lastName'] ?? '');
  final emailCtrl = TextEditingController(text: user?['email'] ?? '');
  final typeCtrl = TextEditingController(text: user?['userType'] ?? '');

  String? userId = user?['_id'];                     // <-- added
  String? selectedMenuOption = user?['accessProfile']; 
  bool isActive = user?['isActive'] ?? true;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(user == null ? "Create User" : "Edit User"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstCtrl,
                    decoration: const InputDecoration(labelText: "First Name"),
                  ),
                  TextField(
                    controller: lastCtrl,
                    decoration: const InputDecoration(labelText: "Last Name"),
                  ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  TextField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(labelText: "User Type"),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: selectedMenuOption,
                    decoration: const InputDecoration(labelText: "Menu Option"),
                    items: menuOptions.map((p) {
                      final id = p['_id']?.toString() ?? '';
                      final name = p['name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateSB(() {
                        selectedMenuOption = val;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Active"),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          setStateSB(() => isActive = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final payload = {
                    "firstName": firstCtrl.text,
                    "lastName": lastCtrl.text,
                    "email": emailCtrl.text,
                    "userType": typeCtrl.text,
                    "accessProfile": selectedMenuOption,
                    "isActive": isActive,
                  };

                  try {
                    if (userId != null) {
                      payload["_id"] = userId;               // <-- safe assign
                      await Api.send('PUT', '/users', payload: payload);
                    } else {
                      await Api.send('POST', '/users', payload: payload);
                    }
                  } catch (e) {
                    print("Error saving user: $e");
                  }

                  Navigator.pop(context);
                  loadUsers();
                },
                child: Text(user == null ? "Create" : "Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loading = loadingUsers || loadingMenus;

    return Scaffold(
      appBar: const Navbar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Users",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => openUserModal(),
                        child: const Text("Create User"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("First Name")),
                          DataColumn(label: Text("Last Name")),
                          DataColumn(label: Text("Email")),
                          DataColumn(label: Text("Type")),
                          DataColumn(label: Text("Active")),
                          DataColumn(label: Text("Menu Option")),
                          DataColumn(label: Text("Actions")),
                        ],
                        rows: users.map((u) {
                          String menuName = "N/A";

                          final menuId = u['accessProfile']?.toString();
                          if (menuId != null && menuOptions.isNotEmpty) {
                            final found = menuOptions.where(
                              (p) => p['_id']?.toString() == menuId,
                            );
                            if (found.isNotEmpty) {
                              menuName =
                                  found.first['name']?.toString() ?? "N/A";
                            }
                          }

                          return DataRow(cells: [
                            DataCell(Text(u['firstName']?.toString() ?? '')),
                            DataCell(Text(u['lastName']?.toString() ?? '')),
                            DataCell(Text(u['email']?.toString() ?? '')),
                            DataCell(Text(u['userType']?.toString() ?? '')),
                            DataCell(
                              Text((u['isActive'] == true) ? "Yes" : "No"),
                            ),
                            DataCell(Text(menuName)),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    openUserModal(user: u);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    deleteUser(u['_id']);
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
