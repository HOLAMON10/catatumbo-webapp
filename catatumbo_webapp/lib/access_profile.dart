import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'navbar.dart';
import 'enums/catalogs.dart';
import 'package:uuid/uuid.dart';
import 'models/user.dart';

class AccessProfilesPage extends StatefulWidget {
  const AccessProfilesPage({super.key});

  @override
  State<AccessProfilesPage> createState() => _AccessProfilesPageState();
}

class _AccessProfilesPageState extends State<AccessProfilesPage> {
  List<Map<String, dynamic>> profiles = [];
  List<Map<String, dynamic>> menuOptions = [];

  bool loadingProfiles = true;
  bool loadingMenus = true;

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

    if (hasPermission("userCanManageAccessLevels")) {
      loadMenuOptions();
      loadProfiles();
    } else {
      loadingMenus = false;
      loadingProfiles = false;
    }

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
  List<Map<String, dynamic>> get filteredProfiles {
    return profiles.where((p) {
      if (searchQuery.isNotEmpty) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final desc = (p['description'] ?? '').toString().toLowerCase();
        final ref = (p['referenceCode'] ?? '').toString().toLowerCase();
        if (!name.contains(searchQuery) &&
            !desc.contains(searchQuery) &&
            !ref.contains(searchQuery)) {
          return false;
        }
      }

      final active = p['isActive'] == true;
      if (showActiveOnly && !active) return false;
      if (showInactiveOnly && active) return false;

      return true;
    }).toList();
  }

  // --------------------------------------------------------------------------
  // LOAD
  // --------------------------------------------------------------------------
  Future<void> loadProfiles() async {
    try {
      final res =
          await Api.send('POST', '/accessprofiles/search', payload: {});
      final body = jsonDecode(res.body);
      final List list = body['detail'] ?? [];

      setState(() {
        profiles = list.map((e) => Map<String, dynamic>.from(e)).toList();
        loadingProfiles = false;
      });
    } catch (_) {
      loadingProfiles = false;
    }
  }

  Future<void> loadMenuOptions() async {
    try {
      final res = await Api.send(
        'GET',
        '/catalogs/${CatalogName.menuoptions.value}',
      );
      final body = jsonDecode(res.body);
      final List list = body['detail'] ?? [];

      setState(() {
        menuOptions = list.map((e) => Map<String, dynamic>.from(e)).toList();
        loadingMenus = false;
      });
    } catch (_) {
      loadingMenus = false;
    }
  }

  // --------------------------------------------------------------------------
  // DELETE
  // --------------------------------------------------------------------------
  Future<void> deleteProfile(Map<String, dynamic> profile) async {
    if (!hasPermission("userCanManageAccessLevels")) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Inactivation"),
        content: Text(
          'Are you sure you want to inactivate "${profile["name"]}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Inactivate"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await Api.send('PUT', '/accessprofiles', payload: {
      ...profile,
      "isActive": false,
    });

    loadProfiles();
  }

  // --------------------------------------------------------------------------
  // MODAL (unchanged)
  // --------------------------------------------------------------------------
  void openProfileModal({Map<String, dynamic>? profile}) {
    if (!hasPermission("userCanManageAccessLevels")) return;

    final nameCtrl = TextEditingController(text: profile?["name"] ?? "");
    final descCtrl =
        TextEditingController(text: profile?["description"] ?? "");
    final refCtrl =
        TextEditingController(text: profile?["referenceCode"] ?? const Uuid().v4());

    bool isActive = profile?["isActive"] ?? true;
    List<String> selectedMenuOptions =
        (profile?["menuOptions"] ?? []).map<String>((e) => e.toString()).toList();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DefaultTabController(
            length: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Access Profile",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TabBar(
                    tabs: [
                      Tab(text: "Info"),
                      Tab(text: "Menu Options"),
                    ],
                  ),
                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      children: [
                        ListView(
                          children: [
                            TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: "Name",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descCtrl,
                              decoration: const InputDecoration(
                                labelText: "Description",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: refCtrl,
                              decoration: const InputDecoration(
                                labelText: "Reference Code",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            SwitchListTile(
                              title: const Text("Active"),
                              value: isActive,
                              onChanged: (v) =>
                                  setState(() => isActive = v),
                            ),
                          ],
                        ),
                        ListView(
                          children: menuOptions.map((opt) {
                            final id = opt["_id"].toString();
                            return CheckboxListTile(
                              title: Text(opt["name"].toString()),
                              value: selectedMenuOptions.contains(id),
                              onChanged: (v) {
                                setState(() {
                                  v == true
                                      ? selectedMenuOptions.add(id)
                                      : selectedMenuOptions.remove(id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final payload = {
                            "name": nameCtrl.text,
                            "description": descCtrl.text,
                            "referenceCode": refCtrl.text,
                            "isActive": isActive,
                            "menuOptions":
                                selectedMenuOptions.toSet().toList(),
                          };

                          await Api.send(
                            profile == null ? 'POST' : 'PUT',
                            '/accessprofiles',
                            payload: profile == null
                                ? payload
                                : {...payload, "_id": profile["_id"]},
                          );

                          Navigator.pop(context);
                          loadProfiles();
                        },
                        child: Text(profile == null ? "Create" : "Save"),
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
    final loading = loadingProfiles || loadingMenus;
    final display = filteredProfiles;

    return Scaffold(
      appBar: const Navbar(),
      body: Container(
        color: const Color(0xFFF4F5F7),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Access Profiles',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage access levels and permissions.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
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
                          onPressed: () => openProfileModal(),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('New'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // FILTER CARD
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchCtrl,
                              decoration: InputDecoration(
                                labelText: "Search",
                                prefixIcon:
                                    const Icon(Icons.search, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilterChip(
                            label: const Text("Active"),
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
                            label: const Text("Inactive"),
                            selected: showInactiveOnly,
                            onSelected: (v) {
                              setState(() {
                                showInactiveOnly = v;
                                if (v) showActiveOnly = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : Card(
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
                                    DataColumn(label: Text("Name")),
                                    DataColumn(label: Text("Description")),
                                    DataColumn(label: Text("Reference")),
                                    DataColumn(label: Text("Active")),
                                    DataColumn(label: Text("Actions")),
                                  ],
                                  rows: display.map((p) {
                                    final active = p["isActive"] == true;
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(p["name"] ?? "")),
                                        DataCell(Text(p["description"] ?? "")),
                                        DataCell(Text(p["referenceCode"] ?? "")),
                                        DataCell(
                                          Icon(
                                            active
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: active
                                                ? Colors.green
                                                : Colors.red,
                                            size: 16,
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                                Icons.edit_outlined),
                                            onPressed: () =>
                                                openProfileModal(profile: p),
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
