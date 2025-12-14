import 'dart:convert';
import 'package:flutter/material.dart';

import 'api.dart';
import 'navbar.dart';

class MeetingRoomsPage extends StatefulWidget {
  const MeetingRoomsPage({super.key});

  @override
  State<MeetingRoomsPage> createState() => _MeetingRoomsPageState();
}

class _MeetingRoomsPageState extends State<MeetingRoomsPage> {
  List<Map<String, dynamic>> rooms = [];
  bool loading = true;

  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = '';
  bool showActiveOnly = false;
  bool showInactiveOnly = false;

  @override
  void initState() {
    super.initState();
    loadRooms();

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
  // LOAD MEETING ROOMS
  // --------------------------------------------------------------------------
  Future<void> loadRooms() async {
    try {
      final response = await Api.send(
        'POST',
        '/meetingrooms/search',
        payload: {},
      );

      final body = jsonDecode(response.body);
      final List detail = body['detail'] ?? [];

      setState(() {
        rooms = detail.map((e) => Map<String, dynamic>.from(e)).toList();
        loading = false;
      });
    } catch (e) {
      loading = false;
    }
  }

  // --------------------------------------------------------------------------
  // FILTER ROOMS
  // --------------------------------------------------------------------------
  List<Map<String, dynamic>> get filteredRooms {
    return rooms.where((r) {
      if (searchQuery.isNotEmpty) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        final location = (r['location'] ?? '').toString().toLowerCase();

        if (!name.contains(searchQuery) &&
            !location.contains(searchQuery)) {
          return false;
        }
      }

      final isActive = r['isActive'] == true;
      if (showActiveOnly && !isActive) return false;
      if (showInactiveOnly && isActive) return false;

      return true;
    }).toList();
  }

  // --------------------------------------------------------------------------
  // OPEN CREATE / EDIT MODAL
  // --------------------------------------------------------------------------
  void openRoomModal({Map<String, dynamic>? room}) {
    final bool isEdit = room != null;

    final nameCtrl = TextEditingController(text: room?['name'] ?? '');
    final locationCtrl =
        TextEditingController(text: room?['location'] ?? '');
    final chairsCtrl =
        TextEditingController(text: room?['chairs']?.toString() ?? '');

    bool isActive = room?['isActive'] ?? true;

    List<Map<String, dynamic>> schedule =
        List<Map<String, dynamic>>.from(room?['schedule'] ?? []);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setSB) {
          return AlertDialog(
            title: Text(isEdit ? "Edit Meeting Room" : "Create Meeting Room"),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: "Room Name"),
                    ),
                    TextField(
                      controller: locationCtrl,
                      decoration:
                          const InputDecoration(labelText: "Location"),
                    ),
                    TextField(
                      controller: chairsCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: "Number of Chairs"),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Schedule",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...schedule.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            DropdownButton<int>(
                              value: s['day'],
                              items: List.generate(7, (d) {
                                return DropdownMenuItem(
                                  value: d + 1,
                                  child: Text("Day ${d + 1}"),
                                );
                              }),
                              onChanged: (v) =>
                                  setSB(() => schedule[i]['day'] = v),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                    labelText: "Start"),
                                controller: TextEditingController(
                                    text: s['startingHour']),
                                onChanged: (v) => schedule[i]['startingHour'] = v,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration:
                                    const InputDecoration(labelText: "End"),
                                controller: TextEditingController(
                                    text: s['endingHour']),
                                onChanged: (v) => schedule[i]['endingHour'] = v,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  setSB(() => schedule.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Add Schedule"),
                        onPressed: () {
                          setSB(() {
                            schedule.add({
                              "day": 1,
                              "startingHour": "09:00",
                              "endingHour": "17:00",
                            });
                          });
                        },
                      ),
                    ),

                    const Divider(),
                    SwitchListTile(
                      title: const Text("Active"),
                      value: isActive,
                      onChanged: (v) => setSB(() => isActive = v),
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
                    "name": nameCtrl.text,
                    "location": locationCtrl.text,
                    "chairs": int.tryParse(chairsCtrl.text) ?? 0,
                    "schedule": schedule,
                    "isActive": isActive,
                  };

                  if (isEdit) {
                    payload["_id"] = room!["_id"];
                    await Api.send('PUT', '/meetingrooms', payload: payload);
                  } else {
                    await Api.send('POST', '/meetingrooms', payload: payload);
                  }

                  Navigator.pop(context);
                  loadRooms();
                },
                child: Text(isEdit ? "Save" : "Create"),
              ),
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
  final displayRooms = filteredRooms;

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
                                'Meeting Rooms',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Manage available meeting rooms.',
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
                              onPressed: () => openRoomModal(),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Create'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // FILTERS (NOW MATCH USERS)
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
                                    labelText: 'Search',
                                    isDense: true,
                                    prefixIcon:
                                        const Icon(Icons.search, size: 18),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilterChip(
                                label: const Text('Active'),
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
                                label: const Text('Inactive'),
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

                      // TABLE (NOW MATCH USERS)
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
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Location')),
                                  DataColumn(label: Text('Chairs')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: displayRooms.map((r) {
                                  final active = r['isActive'] == true;

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(r['name'] ?? '')),
                                      DataCell(Text(r['location'] ?? '')),
                                      DataCell(
                                          Text('${r['chairs'] ?? 0}')),
                                      DataCell(
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            color: active
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                          ),
                                          child: Text(
                                            active
                                                ? 'Active'
                                                : 'Inactive',
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
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              openRoomModal(room: r),
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
