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

    if (hasPermission("userCanManageAccessLevels")) {
      loadMenuOptions();
      loadProfiles();
    } else {
      loadingMenus = false;
      loadingProfiles = false;
    }

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
  // FILTER PROFILES
  // --------------------------------------------------------------------------
  List<Map<String, dynamic>> get filteredProfiles {
    return profiles.where((p) {
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final description = (p['description'] ?? '').toString().toLowerCase();
        final refCode = (p['referenceCode'] ?? '').toString().toLowerCase();

        if (!name.contains(searchQuery) &&
            !description.contains(searchQuery) &&
            !refCode.contains(searchQuery)) {
          return false;
        }
      }

      // Filter by active status
      final isActive = p['isActive'] == true;
      if (showActiveOnly && !isActive) return false;
      if (showInactiveOnly && isActive) return false;

      return true;
    }).toList();
  }

  // --------------------------------------------------------------------------
  // LOAD ACCESS PROFILES
  // --------------------------------------------------------------------------
  Future<void> loadProfiles() async {
    try {
      final res =
          await Api.send('POST', '/accessprofiles/search', payload: {});
      final body = jsonDecode(res.body);

      final detail = body["detail"];
      List<Map<String, dynamic>> parsed = [];

      if (detail is List) {
        parsed = detail
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      setState(() {
        profiles = parsed;
        loadingProfiles = false;
      });
    } catch (e) {
      print("Error loading profiles: $e");
      profiles = [];
      loadingProfiles = false;
    }
  }

  // --------------------------------------------------------------------------
  // LOAD MENU OPTIONS
  // --------------------------------------------------------------------------
  Future<void> loadMenuOptions() async {
    try {
      final res = await Api.send(
        'GET',
        '/catalogs/${CatalogName.menuoptions.value}',
      );

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
  // DELETE (INACTIVATE)
  // --------------------------------------------------------------------------
  Future<void> deleteProfile(Map<String, dynamic> profile) async {
    if (!hasPermission("userCanManageAccessLevels")) return;

    final shouldDeactivate = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Inactivate"),
          ),
        ],
      ),
    );

    if (shouldDeactivate != true) return;

    try {
      final payload = {
        ...profile,
        "isActive": false,
      };

      await Api.send(
        'PUT',
        '/accessprofiles',
        payload: payload,
      );
    } catch (e) {
      print("Error deactivating profile: $e");
    }

    loadProfiles();
  }

  // --------------------------------------------------------------------------
  // OPEN MODAL
  // --------------------------------------------------------------------------
  void openProfileModal({Map<String, dynamic>? profile}) {
    if (!hasPermission("userCanManageAccessLevels")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You do not have permission to manage access levels."),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: profile?["name"] ?? "");
    final descCtrl =
        TextEditingController(text: profile?["description"] ?? "");
    final refCtrl =
        TextEditingController(text: profile?["referenceCode"] ?? const Uuid().v4());

    bool isActive = profile?["isActive"] ?? true;

    List<String> selectedMenuOptions = [];

    if (profile != null && profile["menuOptions"] is List) {
      selectedMenuOptions =
          (profile["menuOptions"] as List).map((e) => e.toString()).toList();
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          child: SizedBox(
            width: 550,
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: "Access Profile"),
                      Tab(text: "Menu Options"),
                    ],
                  ),

                  SizedBox(
                    height: 430,
                    child: TabBarView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: ListView(
                            children: [
                              TextField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(
                                    labelText: "Name"),
                              ),
                              TextField(
                                controller: descCtrl,
                                decoration: const InputDecoration(
                                    labelText: "Description"),
                              ),
                              TextField(
                                controller: refCtrl,
                                decoration: const InputDecoration(
                                    labelText: "Reference Code"),
                              ),

                              StatefulBuilder(
                                builder: (context, modalSetState) {
                                  return SwitchListTile(
                                    title: const Text("Active"),
                                    value: isActive,
                                    onChanged: (v) {
                                      modalSetState(() => isActive = v);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: StatefulBuilder(
                            builder: (context, modalSetState) {
                              return ListView(
                                children: menuOptions.map((opt) {
                                  final id = opt["_id"].toString();
                                  final name = opt["name"].toString();

                                  final checked =
                                      selectedMenuOptions.contains(id);

                                  return CheckboxListTile(
                                    title: Text(name),
                                    value: checked,
                                    onChanged: (v) {
                                      modalSetState(() {
                                        if (v == true) {
                                          selectedMenuOptions.add(id);
                                        } else {
                                          selectedMenuOptions.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
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
                      ElevatedButton(
                        onPressed: () async {
                          final payload = {
                            "name": nameCtrl.text,
                            "description": descCtrl.text,
                            "referenceCode": refCtrl.text,
                            "isActive": isActive,
                            "menuOptions":
                                selectedMenuOptions.toSet().toList(),
                          };

                          try {
                            final res = await Api.send(
                              profile == null ? 'POST' : 'PUT',
                              '/accessprofiles',
                              payload: profile == null
                                  ? payload
                                  : {...payload, "_id": profile["_id"]},
                            );

                            final body = jsonDecode(res.body);

                            if (body["code"] != "success") {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title:
                                      const Text("Validation Error"),
                                  content: Text(body["detail"]
                                          ?.toString() ??
                                      "Unknown validation issue"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context);
                            loadProfiles();
                          } catch (e) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Unexpected Error"),
                                content: Text(e.toString()),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text("OK"),
                                  )
                                ],
                              ),
                            );
                          }
                        },
                        child: Text(profile == null ? "Create" : "Save"),
                      ),
                      const SizedBox(width: 12),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // BUILD UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loading = loadingProfiles || loadingMenus;

    if (!hasPermission("userCanManageAccessLevels")) {
      return const Scaffold(
        body: Center(
          child: Text(
            "You do not have permission to manage access profiles.",
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    final displayProfiles = filteredProfiles;

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
                        "Access Profiles",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasPermission("userCanManageAccessLevels"))
                        ElevatedButton(
                          onPressed: () => openProfileModal(),
                          child: const Text("Create Profile"),
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
                            labelText: "Search profiles...",
                            hintText: "Name, description, or reference code",
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
                      "Showing ${displayProfiles.length} of ${profiles.length} profiles",
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
                          DataColumn(label: Text("Name")),
                          DataColumn(label: Text("Description")),
                          DataColumn(label: Text("Reference Code")),
                          DataColumn(label: Text("Active")),
                          DataColumn(label: Text("Menu Options")),
                          DataColumn(label: Text("Actions")),
                        ],
                        rows: displayProfiles.map((p) {
                          final menuIds = (p["menuOptions"] ?? []) as List;

                          final names = menuIds.map((id) {
                            final found = menuOptions.firstWhere(
                              (m) => m["_id"] == id,
                              orElse: () => {},
                            );
                            return found["name"] ?? "Unknown";
                          }).join(", ");

                          final bool active = p["isActive"] == true;

                          return DataRow(
                            cells: [
                              DataCell(Text(p["name"] ?? "")),
                              DataCell(Text(p["description"] ?? "")),
                              DataCell(Text(p["referenceCode"] ?? "")),
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
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    names.isEmpty ? "None" : names,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    if (hasPermission("userCanManageAccessLevels"))
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            openProfileModal(profile: p),
                                      ),
                                    if (active &&
                                        hasPermission("userCanManageAccessLevels"))
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => deleteProfile(p),
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