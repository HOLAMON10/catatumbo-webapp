import 'dart:convert';
import 'package:flutter/material.dart';

import 'api.dart';
import 'navbar.dart';

class MeetingRoomReservationsPage extends StatefulWidget {
  const MeetingRoomReservationsPage({super.key});

  @override
  State<MeetingRoomReservationsPage> createState() =>
      _MeetingRoomReservationsPageState();
}

class _MeetingRoomReservationsPageState
    extends State<MeetingRoomReservationsPage> {
  List<Map<String, dynamic>> reservations = [];
  List<Map<String, dynamic>> meetingRooms = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadReservations(),
      loadMeetingRooms(),
    ]);
    setState(() => loading = false);
  }

  // --------------------------------------------------------------------------
  // LOAD MEETING ROOMS
  // --------------------------------------------------------------------------
  Future<void> loadMeetingRooms() async {
    final res = await Api.send(
      'POST',
      '/meetingrooms/search',
      payload: {"isActive": true},

    );

    final body = jsonDecode(res.body);
    meetingRooms = (body['detail'] ?? [])
        .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // --------------------------------------------------------------------------
  // LOAD RESERVATIONS
  // --------------------------------------------------------------------------
  Future<void> loadReservations() async {
    final res = await Api.send(
      'POST',
      '/meetingroomreservations/search',
      payload: {"populateAll":true},
    );

    final body = jsonDecode(res.body);
    reservations = (body['detail'] ?? [])
        .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // --------------------------------------------------------------------------
  // VALIDATION HELPERS (MATCHES MONGODB FORMAT EXACTLY)
  // --------------------------------------------------------------------------
  int _weekdayFromDate(String date) {
    return DateTime.parse(date).weekday; // 1 = Monday ... 7 = Sunday
  }

  bool _timeWithin(String value, String start, String end) {
    return value.compareTo(start) >= 0 &&
        value.compareTo(end) <= 0;
  }

  bool _isReservationValid({
    required Map<String, dynamic> room,
    required String date,
    required String start,
    required String end,
  }) {
    if (date.isEmpty || start.isEmpty || end.isEmpty) return false;

    final weekday = _weekdayFromDate(date);
    final List schedule = room['schedule'] ?? [];

    final matchingDay = schedule.cast<Map<String, dynamic>>().firstWhere(
          (s) => s['day'] == weekday,
          orElse: () => {},
        );

    if (matchingDay.isEmpty) return false;

    return _timeWithin(
              start,
              matchingDay['startingHour'],
              matchingDay['endingHour'],
            ) &&
        _timeWithin(
              end,
              matchingDay['startingHour'],
              matchingDay['endingHour'],
            ) &&
        start.compareTo(end) < 0;
  }

  // --------------------------------------------------------------------------
  // OPEN CREATE / EDIT MODAL
  // --------------------------------------------------------------------------
  void openReservationModal({Map<String, dynamic>? reservation}) {
    final bool isEdit = reservation != null;

    Map<String, dynamic>? selectedRoom =
        reservation?['meetingRoom'];
    String? selectedRoomId = selectedRoom?['_id'];

    final dateCtrl = TextEditingController(
        text: reservation?['reservationDate'] ?? '');
    final startCtrl = TextEditingController(
        text: reservation?['reservationStartingHour'] ?? '');
    final endCtrl = TextEditingController(
        text: reservation?['reservationEndingHour'] ?? '');
    final descriptionCtrl =
        TextEditingController(text: reservation?['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setSB) {
          return AlertDialog(
            title: Text(
              isEdit ? "Edit Reservation" : "Reserve Meeting Room",
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ---------------- ROOM ----------------
                    DropdownButtonFormField<String>(
                      value: selectedRoomId,
                      decoration: const InputDecoration(
                        labelText: "Meeting Room",
                      ),
                      items: meetingRooms.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['_id'],
                          child: Text("${r['name']} (${r['location']})"),
                        );
                      }).toList(),
                      onChanged: (v) {
                        final room = meetingRooms
                            .firstWhere((r) => r['_id'] == v);
                        setSB(() {
                          selectedRoomId = v;
                          selectedRoom = room;
                        });
                      },
                    ),

                    // ---------------- DATE ----------------
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Reservation Date",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );

                        if (picked != null) {
                          dateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        }
                      },
                    ),

                    // ---------------- TIME ----------------
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: "Start Time",
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      alwaysUse24HourFormat: true,
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                final h =
                                    picked.hour.toString().padLeft(2, '0');
                                final m =
                                    picked.minute.toString().padLeft(2, '0');
                                startCtrl.text = "$h:$m"; // HH:mm
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: "End Time",
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      alwaysUse24HourFormat: true,
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                final h =
                                    picked.hour.toString().padLeft(2, '0');
                                final m =
                                    picked.minute.toString().padLeft(2, '0');
                                endCtrl.text = "$h:$m"; // HH:mm
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // ---------------- DESCRIPTION ----------------
                    TextField(
                      controller: descriptionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),

                    // ---------------- AVAILABILITY ----------------
                    if (selectedRoom != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Room availability:\n" +
                                (selectedRoom!['schedule'] as List)
                                    .map((s) =>
                                        "Day ${s['day']} ${s['startingHour']}–${s['endingHour']}")
                                    .join("\n"),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
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
                  if (selectedRoom == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Select a meeting room"),
                      ),
                    );
                    return;
                  }

                  final valid = _isReservationValid(
                    room: selectedRoom!,
                    date: dateCtrl.text,
                    start: startCtrl.text,
                    end: endCtrl.text,
                  );

                  if (!valid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Reservation is outside the room's allowed schedule.",
                        ),
                      ),
                    );
                    return;
                  }

                  final payload = {
                    "meetingRoom": selectedRoomId,
                    "reservationDate": dateCtrl.text,
                    "reservationStartingHour": startCtrl.text,
                    "reservationEndingHour": endCtrl.text,
                    "description": descriptionCtrl.text,
                  };

                  if (isEdit) {
                    payload["_id"] = reservation!["_id"];
                    await Api.send(
                      'PUT',
                      '/meetingroomreservations',
                      payload: payload,
                    );
                  } else {
                    await Api.send(
                      'POST',
                      '/meetingroomreservations',
                      payload: payload,
                    );
                  }

                  Navigator.pop(context);
                  loadReservations();
                },
                child: Text(isEdit ? "Save" : "Reserve"),
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
                        "Meeting Room Reservations",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => openReservationModal(),
                        child: const Text("New Reservation"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Room")),
                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("Start")),
                          DataColumn(label: Text("End")),
                          DataColumn(label: Text("Description")),
                          DataColumn(label: Text("Actions")),
                        ],
                        rows: reservations.map((r) {
                          final room = r['meetingRoom'];
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                  room != null ? room['name'] : "—")),
                              DataCell(Text(r['reservationDate'] ?? '')),
                              DataCell(Text(
                                  r['reservationStartingHour'] ?? '')),
                              DataCell(Text(
                                  r['reservationEndingHour'] ?? '')),
                              DataCell(Text(r['description'] ?? '')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      openReservationModal(reservation: r),
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
