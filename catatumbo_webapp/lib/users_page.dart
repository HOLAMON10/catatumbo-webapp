import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'navbar.dart';
import 'session.dart';
import 'models/user.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> menuOptions = [];
  List<Map<String, dynamic>> userPermissions = [];

  bool loadingUsers = true;
  bool loadingMenus = true;
  bool loadingPermissions = true;

  // Search/Filter state
  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = '';
  bool showActiveOnly = false;
  bool showInactiveOnly = false;

  // Permission helper
  bool hasPermission(String perm) {
    return UserData.allowedPermissions?.contains(perm) ?? false;
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadMenuOptions();
    loadUserPermissions();
    
    searchCtrl.addListener(() {
      setState(() {
        searchQuery = searchCtrl.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // FILTER USERS
  // --------------------------------------------------------------------------
  List<Map<String, dynamic>> get filteredUsers {
    return users.where((u) {
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final firstName = (u['firstName'] ?? '').toString().toLowerCase();
        final lastName = (u['lastName'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final userType = (u['userType'] ?? '').toString().toLowerCase();
        
        if (!firstName.contains(searchQuery) &&
            !lastName.contains(searchQuery) &&
            !email.contains(searchQuery) &&
            !userType.contains(searchQuery)) {
          return false;
        }
      }

      // Filter by active status
      final isActive = u['isActive'] == true;
      if (showActiveOnly && !isActive) return false;
      if (showInactiveOnly && isActive) return false;

      return true;
    }).toList();
  }

  // --------------------------------------------------------------------------
  // LOAD USERS
  // --------------------------------------------------------------------------
  Future<void> loadUsers() async {
    if (!hasPermission("userCanAccessUserProfiles")) {
      setState(() {
        loadingUsers = false;
      });
      return;
    }

    try {
      final response = await Api.send(
        'POST',
        '/users/search',
        payload: {},
      );

      final data = jsonDecode(response.body);
      final List<dynamic> detail = data['detail'] ?? [];

      setState(() {
        users = detail.map((e) => Map<String, dynamic>.from(e)).toList();
        loadingUsers = false;
      });
    } catch (e) {
      print("Error loading users: $e");
      users = [];
      loadingUsers = false;
    }
  }

  // --------------------------------------------------------------------------
  // LOAD ACCESS PROFILES
  // --------------------------------------------------------------------------
  Future<void> loadMenuOptions() async {
    try {
      final res = await Api.send('POST', '/accessprofiles/search');
      final body = jsonDecode(res.body);
      final List<dynamic> detailList = body['detail'] ?? [];

      setState(() {
        menuOptions =
            detailList.map((e) => Map<String, dynamic>.from(e)).toList();
        loadingMenus = false;
      });
    } catch (e) {
      print("Error loading menu options: $e");
      loadingMenus = false;
    }
  }

  // --------------------------------------------------------------------------
  // LOAD USER PERMISSIONS
  // --------------------------------------------------------------------------
  Future<void> loadUserPermissions() async {
    try {
      final res = await Api.send(
        'GET',
        '/catalogs/userpermissions',
      );

      final body = jsonDecode(res.body);
      final List<dynamic> detailList = body['detail'] ?? [];

      setState(() {
        userPermissions =
            detailList.map((p) => Map<String, dynamic>.from(p)).toList();
        loadingPermissions = false;
      });
    } catch (e) {
      print("Error loading permissions: $e");
      loadingPermissions = false;
    }
  }

  // --------------------------------------------------------------------------
  // DEACTIVATE USER
  // --------------------------------------------------------------------------
  Future<void> deactivateUser(Map<String, dynamic> u) async {
    if (!hasPermission("userCanDeactivateUser")) return;

    final updated = Map<String, dynamic>.from(u);
    updated["isActive"] = false;

    try {
      await Api.send('PUT', '/users', payload: updated);
    } catch (e) {
      print("Error deactivating user: $e");
    }

    loadUsers();
  }

  // --------------------------------------------------------------------------
  // CONFIRM DEACTIVATION
  // --------------------------------------------------------------------------
  Future<void> confirmDeactivate(Map<String, dynamic> user) async {
    if (!hasPermission("userCanDeactivateUser")) return;

    final fullName =
        "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deactivate User?"),
        content: Text(
            "Are you sure you want to deactivate $fullName?\nThey will no longer be able to log in."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Deactivate"),
          ),
        ],
      ),
    );

    if (result == true) deactivateUser(user);
  }

  // --------------------------------------------------------------------------
  // USER MODAL WITH TABS
  // --------------------------------------------------------------------------
  void openUserModal({Map<String, dynamic>? user}) {
    final bool isEdit = user != null;

    // Permissions enforcement
    if (isEdit && !hasPermission("userCanModifyExistingUser")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot modify users.")),
      );
      return;
    }
    if (!isEdit && !hasPermission("userCanCreateNewUser")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot create users.")),
      );
      return;
    }

    final firstCtrl = TextEditingController(text: user?['firstName'] ?? '');
    final lastCtrl = TextEditingController(text: user?['lastName'] ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] ?? '');
    final typeCtrl = TextEditingController(text: user?['userType'] ?? '');

    String? userId = user?['_id'];
    String? selectedMenuOption = user?['accessProfile'];
    bool isActive = user?['isActive'] ?? true;

    // Load user's permissions from DB field
    List<String> selectedPermissions =
        List<String>.from(user?['allowedPermissions'] ?? []);

    final bool canModifyPermissions =
        hasPermission("userCanAssignRoles") ||
            hasPermission("userCanModifyRoles");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(isEdit ? "Edit User" : "Create User"),
            content: SizedBox(
              width: 500,
              child: DefaultTabController(
                length: canModifyPermissions ? 2 : 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      tabs: [
                        const Tab(text: "Info"),
                        if (canModifyPermissions)
                          const Tab(text: "Permissions"),
                      ],
                    ),
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        children: [
                          // ------------------------- INFO TAB -------------------------
                          SingleChildScrollView(
                            child: Column(
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
                                  decoration:
                                      const InputDecoration(labelText: "Menu Option"),
                                  items: menuOptions.map((p) {
                                    final id = p['_id']?.toString() ?? '';
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Text(p['name']),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setStateSB(() => selectedMenuOption = val);
                                  },
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Active"),
                                    Switch(
                                      value: isActive,
                                      onChanged: (v) {
                                        setStateSB(() => isActive = v);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ---------------------- PERMISSIONS TAB ----------------------
                          if (canModifyPermissions)
                            ListView(
                              children: userPermissions.map((perm) {
                                final id = perm['_id']?.toString() ?? '';
                                final name = perm['name'];

                                return CheckboxListTile(
                                  title: Text(name),
                                  value: selectedPermissions.contains(id),
                                  onChanged: (checked) {
                                    setStateSB(() {
                                      if (checked == true) {
                                        selectedPermissions.add(id);
                                      } else {
                                        selectedPermissions.remove(id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
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

                  // Only add permissions if user may edit them
                  if (canModifyPermissions) {
                    payload["allowedPermissions"] = selectedPermissions;
                  }

                  try {
                    if (isEdit) {
                      payload["_id"] = userId;
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
                child: Text(isEdit ? "Save" : "Create"),
              )
            ],
          );
        });
      },
    );
  }

  // --------------------------------------------------------------------------
  // BUILD UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loading = loadingUsers || loadingMenus || loadingPermissions;

    if (!hasPermission("userCanAccessUserProfiles")) {
      return const Scaffold(
        body: Center(
          child: Text(
            "You do not have permission to view user profiles.",
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    final displayUsers = filteredUsers;

    return Scaffold(
      appBar: const Navbar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header Row
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
                      if (hasPermission("userCanCreateNewUser"))
                        ElevatedButton(
                          onPressed: () => openUserModal(),
                          child: const Text("Create User"),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Search and Filter Row
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            labelText: "Search users...",
                            hintText: "Name, email, or type",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      searchCtrl.clear();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Active Filter
                      FilterChip(
                        label: const Text("Active Only"),
                        selected: showActiveOnly,
                        onSelected: (selected) {
                          setState(() {
                            showActiveOnly = selected;
                            if (selected) showInactiveOnly = false;
                          });
                        },
                      ),

                      const SizedBox(width: 8),

                      // Inactive Filter
                      FilterChip(
                        label: const Text("Inactive Only"),
                        selected: showInactiveOnly,
                        onSelected: (selected) {
                          setState(() {
                            showInactiveOnly = selected;
                            if (selected) showActiveOnly = false;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Results count
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Showing ${displayUsers.length} of ${users.length} users",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Data Table
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
                        rows: displayUsers.map((u) {
                          String menuName = "N/A";

                          final menuId = u['accessProfile']?.toString();
                          if (menuId != null) {
                            final found = menuOptions.where(
                              (p) => p['_id'] == menuId,
                            );
                            if (found.isNotEmpty) {
                              menuName = found.first['name'];
                            }
                          }

                          final bool active = u['isActive'] == true;

                          return DataRow(
                            cells: [
                              DataCell(Text(u['firstName'] ?? '')),
                              DataCell(Text(u['lastName'] ?? '')),
                              DataCell(Text(u['email'] ?? '')),
                              DataCell(Text(u['userType'] ?? '')),
                              DataCell(
                                Row(
                                  children: [
                                    Icon(
                                      active ? Icons.check_circle : Icons.cancel,
                                      color: active ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(active ? "Yes" : "No"),
                                  ],
                                ),
                              ),
                              DataCell(Text(menuName)),
                              DataCell(
                                Row(
                                  children: [
                                    if (hasPermission("userCanModifyExistingUser"))
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => openUserModal(user: u),
                                      ),
                                    if (active &&
                                        hasPermission("userCanDeactivateUser"))
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => confirmDeactivate(u),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
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