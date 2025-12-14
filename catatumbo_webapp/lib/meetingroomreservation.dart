import 'dart:convert';
import 'package:flutter/material.dart';

import 'api.dart';
import 'navbar.dart';
import 'models/user.dart';

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

  // --------------------------------------------------------------------------
  // LOAD ALL DATA
  // --------------------------------------------------------------------------
  Future<void> loadData() async {
    setState(() => loading = true);
    await Future.wait([
      loadReservations(),
      loadMeetingRooms(),
    ]);
    setState(() => loading = false);
  }

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

  Future<void> loadReservations() async {
    final res = await Api.send(
      'POST',
      '/meetingroomreservations/search',
      payload: {"populateAll": true},
    );

    final body = jsonDecode(res.body);
    reservations = (body['detail'] ?? [])
        .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // --------------------------------------------------------------------------
  // CREATE / EDIT MODAL
  // --------------------------------------------------------------------------
  void openReservationModal({Map<String, dynamic>? reservation}) {
    final bool isEdit = reservation != null;

    Map<String, dynamic>? selectedRoom =
        reservation?['meetingRoom'];
    String? selectedRoomId = selectedRoom?['_id'];

    final dateCtrl =
        TextEditingController(text: reservation?['reservationDate'] ?? '');
    final startCtrl =
        TextEditingController(text: reservation?['reservationStartingHour'] ?? '');
    final endCtrl =
        TextEditingController(text: reservation?['reservationEndingHour'] ?? '');
    final descriptionCtrl =
        TextEditingController(text: reservation?['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setSB) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            insetPadding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isEdit ? 'Editar reserva' : 'Nueva reserva',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: selectedRoomId,
                      decoration: const InputDecoration(
                        labelText: "Sala",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: meetingRooms.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['_id'],
                          child: Text("${r['name']} (${r['location']})"),
                        );
                      }).toList(),
                      onChanged: (v) {
                        final room =
                            meetingRooms.firstWhere((r) => r['_id'] == v);
                        setSB(() {
                          selectedRoomId = v;
                          selectedRoom = room;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Fecha",
                        border: OutlineInputBorder(),
                        isDense: true,
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
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: "Hora inicio",
                              border: OutlineInputBorder(),
                              isDense: true,
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
                                startCtrl.text =
                                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
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
                              labelText: "Hora fin",
                              border: OutlineInputBorder(),
                              isDense: true,
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
                                endCtrl.text =
                                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descriptionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Descripción",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () async {
                            if (selectedRoom == null) return;

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
                                payload: {"payload": payload},
                              );
                            } else {
                              await Api.send(
                                'POST',
                                '/meetingroomreservations',
                                payload: {
                                  "payload": payload,
                                  "email": UserData.email,
                                },
                              );
                            }

                            Navigator.pop(context);
                            await loadReservations();
                            setState(() {});
                          },
                          child: Text(isEdit ? 'Guardar' : 'Reservar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------
@override
Widget build(BuildContext context) {
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
                                'Reservas de salas',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Consulta y administra las reservas de salas de juntas.',
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
                              onPressed: () => openReservationModal(),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Nueva'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // FILTERS (MATCH USERS PAGE STYLE)
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
                                  decoration: InputDecoration(
                                    labelText: 'Buscar',
                                    isDense: true,
                                    prefixIcon:
                                        const Icon(Icons.search, size: 18),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilterChip(
                                label: const Text("Hoy"),
                                selected: false,
                                onSelected: (_) {},
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text("Próximas"),
                                selected: false,
                                onSelected: (_) {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // TABLE (MATCH USERS PAGE STYLE)
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
                                  DataColumn(label: Text("Sala")),
                                  DataColumn(label: Text("Fecha")),
                                  DataColumn(label: Text("Inicio")),
                                  DataColumn(label: Text("Fin")),
                                  DataColumn(label: Text("Descripción")),
                                  DataColumn(label: Text("Acciones")),
                                ],
                                rows: reservations.map((r) {
                                  final room = r['meetingRoom'];
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(room?['name'] ?? '—')),
                                      DataCell(
                                          Text(r['reservationDate'] ?? '')),
                                      DataCell(Text(
                                          r['reservationStartingHour'] ?? '')),
                                      DataCell(Text(
                                          r['reservationEndingHour'] ?? '')),
                                      DataCell(Text(r['description'] ?? '')),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              openReservationModal(
                                                  reservation: r),
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
