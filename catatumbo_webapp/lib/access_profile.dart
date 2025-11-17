import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'navbar.dart';
import 'enums/catalogs.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void initState() {
    super.initState();
    loadMenuOptions();
    loadProfiles();
  }

  // --------------------------------------------------------------------------
  // LOAD ACCESS PROFILES
  // --------------------------------------------------------------------------
  Future<void> loadProfiles() async {
    try {
      final res = await Api.send('POST', '/accessprofiles/search', payload: {});
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
      setState(() {
        profiles = [];
        loadingProfiles = false;
      });
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
      setState(() {
        menuOptions = [];
        loadingMenus = false;
      });
    }
  }

  // --------------------------------------------------------------------------
  // DELETE ACCESS PROFILE
  // --------------------------------------------------------------------------
  Future<void> deleteProfile(String id) async {
    try {
      await Api.send('DELETE', '/accessprofiles/remove/$id');
    } catch (e) {
      print("Error deleting profile: $e");
    }
    loadProfiles();
  }

  // --------------------------------------------------------------------------
  // OPEN MODAL (INSIDE THIS COMPONENT)
  // --------------------------------------------------------------------------
  void openProfileModal({Map<String, dynamic>? profile}) {
    final nameCtrl = TextEditingController(text: profile?["name"] ?? "");
    final descCtrl =
        TextEditingController(text: profile?["description"] ?? "");
    final refCtrl =
        TextEditingController(text: profile?["referenceCode"] ?? const Uuid().v4());

    bool isActive = profile?["isActive"] ?? true;

    List<String> selectedMenuOptions = [];

    if (profile != null && profile["menuOptions"] is List) {
      selectedMenuOptions = (profile["menuOptions"] as List)
          .map((e) => e.toString())
          .toSet()
          .toList();
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
                        // --------------------------------------------------
                        // TAB 1: PROFILE INFO
                        // --------------------------------------------------
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: ListView(
                            children: [
                              TextField(
                                controller: nameCtrl,
                                decoration:
                                    const InputDecoration(labelText: "Name"),
                              ),
                              TextField(
                                controller: descCtrl,
                                decoration:
                                    const InputDecoration(labelText: "Description"),
                              ),
                              TextField(
                                controller: refCtrl,
                                decoration: const InputDecoration(
                                    labelText: "Reference Code"),
                              ),
                              SwitchListTile(
                                title: const Text("Active"),
                                value: isActive,
                                onChanged: (v) {
                                  setState(() => isActive = v);
                                },
                              ),
                            ],
                          ),
                        ),

                        // --------------------------------------------------
                        // TAB 2: MENU OPTIONS MULTI-SELECT
                        // --------------------------------------------------
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

                  // ----------------------------------------------------------
                  // ACTION BUTTONS
                  // ----------------------------------------------------------
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
    "menuOptions": selectedMenuOptions.toSet().toList(),
  };

  try {
    final res = await Api.send(
      profile == null ? 'POST' : 'PUT',
      '/accessprofiles${profile == null ? '' : ''}',
      payload: profile == null ? payload : {...payload, "_id": profile["_id"]},
    );

    final body = jsonDecode(res.body);

    // ✨ VALIDATION ERROR?
    if (body["code"] != "success") {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Validation Error"),
          content: Text(body["detail"]?.toString() ?? "Unknown validation issue"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return; // ❌ Do NOT close the modal
    }

    // 🌿 SUCCESS → close modal + reload
    Navigator.pop(context);
    loadProfiles();

  } catch (e) {
    // unexpected server crash or network issue
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Unexpected Error"),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

    return Scaffold(
      appBar: const Navbar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ------------------------------------------------------
                  // HEADER
                  // ------------------------------------------------------
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
                      ElevatedButton(
                        onPressed: () => openProfileModal(),
                        child: const Text("Create Profile"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------------
                  // TABLE
                  // ------------------------------------------------------
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
                        rows: profiles.map((p) {
                          final menuIds = (p["menuOptions"] ?? []) as List;

                          final names = menuIds.map((id) {
                            final found = menuOptions.firstWhere(
                              (m) => m["_id"] == id,
                              orElse: () => {},
                            );
                            return found["name"] ?? "Unknown";
                          }).join(", ");

                          return DataRow(
                            cells: [
                              DataCell(Text(p["name"] ?? "")),
                              DataCell(Text(p["description"] ?? "")),
                              DataCell(Text(p["referenceCode"] ?? "")),
                              DataCell(
                                  Text((p["isActive"] == true) ? "Yes" : "No")),
                              DataCell(Text(names)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        openProfileModal(profile: p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        deleteProfile(p["_id"]),
                                  ),
                                ],
                              )),
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
