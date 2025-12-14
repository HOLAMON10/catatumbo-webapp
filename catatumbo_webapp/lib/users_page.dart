import 'dart:convert';
import 'package:flutter/material.dart';

import 'api.dart';
import 'navbar.dart';
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

  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = '';
  bool showActiveOnly = false;
  bool showInactiveOnly = false;

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
      setState(() => searchQuery = searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // FILTER
  // --------------------------------------------------------------------------
  List<Map<String, dynamic>> get filteredUsers {
    return users.where((u) {
      if (searchQuery.isNotEmpty) {
        final values = [
          u['firstName'],
          u['lastName'],
          u['email'],
          u['userType'],
        ].map((e) => (e ?? '').toString().toLowerCase());

        if (!values.any((v) => v.contains(searchQuery))) return false;
      }

      final isActive = u['isActive'] == true;
      if (showActiveOnly && !isActive) return false;
      if (showInactiveOnly && isActive) return false;

      return true;
    }).toList();
  }

  // --------------------------------------------------------------------------
  // LOAD DATA
  // --------------------------------------------------------------------------
  Future<void> loadUsers() async {
    if (!hasPermission("userCanAccessUserProfiles")) {
      loadingUsers = false;
      return;
    }

    try {
      final res = await Api.send('POST', '/users/search');
      final body = jsonDecode(res.body);
      users = (body['detail'] ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } finally {
      loadingUsers = false;
      setState(() {});
    }
  }

  Future<void> loadMenuOptions() async {
    try {
      final res = await Api.send('POST', '/accessprofiles/search');
      final body = jsonDecode(res.body);
      menuOptions = (body['detail'] ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } finally {
      loadingMenus = false;
      setState(() {});
    }
  }

  Future<void> loadUserPermissions() async {
    try {
      final res = await Api.send('GET', '/catalogs/userpermissions');
      final body = jsonDecode(res.body);
      userPermissions = (body['detail'] ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } finally {
      loadingPermissions = false;
      setState(() {});
    }
  }

  // --------------------------------------------------------------------------
  // CONFIRM DEACTIVATION (STYLED)
  // --------------------------------------------------------------------------
  Future<void> confirmDeactivate(Map<String, dynamic> user) async {
    final fullName =
        "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                    "Dar de baja usuario",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "¿Deseas dar de baja a $fullName?",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Dar de baja"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      user['isActive'] = false;
      await Api.send('PUT', '/users', payload: user);
      loadUsers();
    }
  }

  // --------------------------------------------------------------------------
  // USER MODAL (FULLY STYLED)
  // --------------------------------------------------------------------------
  void openUserModal({Map<String, dynamic>? user}) {
    final bool isEdit = user != null;

    final firstCtrl = TextEditingController(text: user?['firstName'] ?? '');
    final lastCtrl = TextEditingController(text: user?['lastName'] ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] ?? '');
    final typeCtrl = TextEditingController(text: user?['userType'] ?? '');
    final dashboardUrlCtrl =
        TextEditingController(text: user?['dashboardUrl'] ?? '');

    String? selectedMenuOption = user?['accessProfile'];
    bool isActive = user?['isActive'] ?? true;

    List<String> selectedPermissions =
        List<String>.from(user?['allowedPermissions'] ?? []);

    final bool canModifyPermissions =
        hasPermission("userCanAssignRoles") ||
            hasPermission("userCanModifyRoles");

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: DefaultTabController(
              length: canModifyPermissions ? 2 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isEdit ? "Editar usuario" : "Nuevo usuario",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    tabs: [
                      const Tab(text: "Info"),
                      if (canModifyPermissions)
                        const Tab(text: "Permisos"),
                    ],
                  ),
                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      children: [
                        // INFO TAB
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              TextField(
                                controller: firstCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Nombre",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: lastCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Apellido",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: emailCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Email",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: typeCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Tipo de usuario",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: dashboardUrlCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Dashboard URL",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: selectedMenuOption,
                                decoration: const InputDecoration(
                                  labelText: "Perfil de acceso",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: menuOptions.map<DropdownMenuItem<String>>((p) {
  final id = p['_id']?.toString() ?? '';
  return DropdownMenuItem<String>(
    value: id,
    child: Text(p['name']),
  );
}).toList(),
                                onChanged: (v) =>
                                    selectedMenuOption = v,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Activo"),
                                  Switch(
                                    value: isActive,
                                    onChanged: (v) =>
                                        isActive = v,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // PERMISSIONS TAB
                        if (canModifyPermissions)
                          ListView(
                            children: userPermissions.map((perm) {
                              final id = perm['_id'];
                              return CheckboxListTile(
                                title: Text(perm['name']),
                                value: selectedPermissions.contains(id),
                                onChanged: (v) {
                                  if (v == true) {
                                    selectedPermissions.add(id);
                                  } else {
                                    selectedPermissions.remove(id);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        onPressed: () async {
                          final payload = {
                            "firstName": firstCtrl.text,
                            "lastName": lastCtrl.text,
                            "email": emailCtrl.text,
                            "userType": typeCtrl.text,
                            "dashboardUrl": dashboardUrlCtrl.text,
                            "accessProfile": selectedMenuOption,
                            "isActive": isActive,
                            if (canModifyPermissions)
                              "allowedPermissions": selectedPermissions,
                            if (isEdit) "_id": user?['_id'],
                          };

                          await Api.send(
                            isEdit ? 'PUT' : 'POST',
                            '/users',
                            payload: payload,
                          );

                          Navigator.pop(context);
                          loadUsers();
                        },
                        child: Text(isEdit ? "Guardar" : "Crear"),
                      ),
                    ],
                  )
                ],
              ),
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
  final loading = loadingUsers || loadingMenus || loadingPermissions;

  return Scaffold(
    appBar: const Navbar(),
    body: Container(
      color: const Color(0xFFF4F5F7),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // HEADER
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Usuarios',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Administra cuentas y permisos.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (hasPermission("userCanCreateNewUser"))
                            SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () => openUserModal(),
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text("Nuevo"),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // FILTERS (MATCHING CARD STYLE)
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Buscar',
                                    isDense: true,
                                    prefixIcon:
                                        const Icon(Icons.search, size: 18),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilterChip(
                                label: const Text("Activos"),
                                selected: showActiveOnly,
                                onSelected: (v) {
                                  setState(() {
                                    showActiveOnly = v;
                                    if (v) showInactiveOnly = false;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text("Inactivos"),
                                selected: showInactiveOnly,
                                onSelected: (v) {
                                  setState(() {
                                    showInactiveOnly = v;
                                    if (v) showActiveOnly = false;
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () => setState(() {}),
                                  icon: const Icon(Icons.filter_list, size: 18),
                                  label: const Text('Aplicar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // TABLE (MATCH MEETING ROOMS CARD + PADDING + DATATABLE SIZING)
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowHeight: 40,
                                dataRowHeight: 46,
                                headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                columns: const [
                                  DataColumn(label: Text("Nombre")),
                                  DataColumn(label: Text("Email")),
                                  DataColumn(label: Text("Tipo")),
                                  DataColumn(label: Text("Estado")),
                                  DataColumn(label: Text("Acciones")),
                                ],
                                rows: filteredUsers.map((u) {
                                  final active = u['isActive'] == true;

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(
                                        "${u['firstName'] ?? ''} ${u['lastName'] ?? ''}",
                                      )),
                                      DataCell(Text((u['email'] ?? '').toString())),
                                      DataCell(Text((u['userType'] ?? '').toString())),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(999),
                                            color: active
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                          ),
                                          child: Text(
                                            active ? 'Activo' : 'Inactivo',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: active
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (hasPermission(
                                                "userCanModifyExistingUser"))
                                              IconButton(
                                                tooltip: 'Editar',
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    openUserModal(user: u),
                                              ),
                                            if (active &&
                                                hasPermission(
                                                    "userCanDeactivateUser"))
                                              IconButton(
                                                tooltip: 'Dar de baja',
                                                icon: Icon(
                                                  Icons.block_outlined,
                                                  size: 20,
                                                  color: Colors.red.shade400,
                                                ),
                                                onPressed: () =>
                                                    confirmDeactivate(u),
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
