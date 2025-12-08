import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'api.dart';
import 'navbar.dart';

class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? area;
  final String? status;
  final bool isActive;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.area,
    this.status,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      area: json['area']?.toString() ?? json['department']?.toString(),
      status: json['status']?.toString(),
      isActive: json['isActive'] == null
          ? true
          : (json['isActive'] is bool
              ? json['isActive'] as bool
              : json['isActive'].toString() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'area': area,
      'status': status,
      'isActive': isActive,
    };
  }
}

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  bool _loading = false;
  List<Employee> _employees = [];

  String? _filterArea;
  String? _filterStatus;

  final List<String> _statusOptions = ['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    try {
      final queryParams = <String, String>{};
      if (_filterArea != null && _filterArea!.isNotEmpty) {
        queryParams['area'] = _filterArea!;
      }
      if (_filterStatus != null && _filterStatus!.isNotEmpty) {
        queryParams['status'] = _filterStatus!;
      }

      String query = '';
      if (queryParams.isNotEmpty) {
        final qp = queryParams.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
            .join('&');
        query = '?$qp';
      }

      final res = await Api.send('GET', '/employees$query');
      final body = jsonDecode(res.body);

      final List<dynamic> raw =
          body is List ? body : (body['detail'] as List? ?? []);
      final list = raw
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() => _employees = list);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createEmployee() async {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final areaController = TextEditingController();
    String? status = 'active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nuevo empleado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaController,
                    decoration: const InputDecoration(
                      labelText: 'Área',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: _statusOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => status = val,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
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
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final payload = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'area': areaController.text.trim(),
        'status': status,
        'isActive': status == 'inactive' ? false : true,
      };

      await Api.send('POST', '/employees', payload: payload);
      await _loadEmployees();
    } catch (_) {}
  }

  Future<void> _editEmployee(Employee employee) async {
    final firstNameController =
        TextEditingController(text: employee.firstName);
    final lastNameController = TextEditingController(text: employee.lastName);
    final emailController = TextEditingController(text: employee.email);
    final areaController = TextEditingController(text: employee.area ?? '');
    String? status =
        employee.status ?? (employee.isActive ? 'active' : 'inactive');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Editar empleado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaController,
                    decoration: const InputDecoration(
                      labelText: 'Área',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: _statusOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => status = val,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
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
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final payload = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'area': areaController.text.trim(),
        'status': status,
        'isActive': status == 'inactive' ? false : true,
      };

      await Api.send('PUT', '/employees/${employee.id}', payload: payload);
      await _loadEmployees();
    } catch (_) {}
  }

  Future<void> _deactivateEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dar de baja',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '¿Deseas dar de baja a ${employee.firstName} ${employee.lastName}?',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Dar de baja'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final payload = {
        'status': 'inactive',
        'isActive': false,
      };

      await Api.send('PUT', '/employees/${employee.id}', payload: payload);
      await _loadEmployees();
    } catch (_) {}
  }

  void _downloadFile(String content, String fileName, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)..download = fileName;
    anchor.click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportCsv() async {
    try {
      final res = await Api.send('GET', '/employees/export/csv');
      final csv = res.body;
      _downloadFile(csv, 'employees.csv', 'text/csv');
    } catch (_) {}
  }

  Future<void> _exportPdf() async {
    try {
      final res = await Api.send('GET', '/employees/export/pdf');
      final content = res.body;
      _downloadFile(content, 'employees.pdf', 'application/pdf');
    } catch (_) {}
  }

  Future<void> _showHistory(Employee employee) async {
    try {
      final res = await Api.send('GET', '/employees/${employee.id}/history');
      final body = jsonDecode(res.body);

      final List<dynamic> raw =
          body is List ? body : (body['detail'] as List? ?? []);
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            insetPadding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Historial de cambios',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: raw.isEmpty
                          ? const Center(
                              child: Text(
                                'Sin cambios registrados',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: raw.length,
                              itemBuilder: (context, index) {
                                final item =
                                    raw[index] as Map<String, dynamic>;
                                final ts = item['modifiedAt'] ?? item['date'];
                                final by = item['modifiedBy'] is Map
                                    ? (item['modifiedBy']['email'] ??
                                        item['modifiedBy']['username'] ??
                                        '')
                                    : (item['modifiedBy']?.toString() ?? '');

                                String formattedDate = '';
                                if (ts != null) {
                                  int? millis;
                                  if (ts is num) {
                                    millis = ts.toInt();
                                  } else {
                                    millis = int.tryParse(ts.toString());
                                  }
                                  if (millis != null) {
                                    final date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            millis);
                                    String two(int n) =>
                                        n.toString().padLeft(2, '0');
                                    formattedDate =
                                        '${two(date.day)}/${two(date.month)}/${date.year} '
                                        '${two(date.hour)}:${two(date.minute)}';
                                  } else {
                                    formattedDate = ts.toString();
                                  }
                                }

                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  title: Text(
                                    by.isEmpty ? 'Sistema' : by,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cerrar'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (_) {}
  }

  Widget _buildFiltersCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Área',
                  isDense: true,
                  prefixIcon: const Icon(Icons.apartment_outlined, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (val) {
                  _filterArea = val.trim().isEmpty ? null : val.trim();
                },
                onSubmitted: (_) => _loadEmployees(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _filterStatus,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ..._statusOptions.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _filterStatus = val;
                  });
                  _loadEmployees();
                },
                decoration: InputDecoration(
                  labelText: 'Status',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: _loadEmployees,
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard() {
    if (_loading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_employees.isEmpty) {
      return Expanded(
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Center(
            child: Text(
              'Sin empleados',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Área')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: _employees.map((e) {
                final fullName = '${e.firstName} ${e.lastName}';
                final statusText =
                    e.status ?? (e.isActive ? 'active' : 'inactive');
                final isInactive = statusText == 'inactive';

                return DataRow(
                  cells: [
                    DataCell(Text(fullName)),
                    DataCell(Text(e.email)),
                    DataCell(Text(e.area ?? '')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: isInactive
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isInactive
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                            ),
                            onPressed: () => _editEmployee(e),
                          ),
                          IconButton(
                            tooltip: 'Historial',
                            icon: const Icon(
                              Icons.history,
                              size: 20,
                            ),
                            onPressed: () => _showHistory(e),
                          ),
                          IconButton(
                            tooltip: 'Dar de baja',
                            icon: Icon(
                              Icons.block_outlined,
                              size: 20,
                              color:
                                  e.isActive ? Colors.red.shade400 : Colors.grey,
                            ),
                            onPressed: e.isActive
                                ? () => _deactivateEmployee(e)
                                : null,
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
    );
  }

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
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Empleados',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Registra, edita, filtra y exporta el catálogo de empleados.',
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
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.table_view_outlined, size: 18),
                          label: const Text('CSV'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 18),
                          label: const Text('PDF'),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          onPressed: _createEmployee,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Nuevo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFiltersCard(),
                  const SizedBox(height: 16),
                  _buildTableCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
