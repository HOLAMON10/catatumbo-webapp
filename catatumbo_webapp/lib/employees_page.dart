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
        return AlertDialog(
          title: const Text('Crear empleado'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(labelText: 'Área'),
                ),
                const SizedBox(height: 8),
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
                  decoration:
                      const InputDecoration(labelText: 'Status', isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Guardar'),
            ),
          ],
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
        return AlertDialog(
          title: const Text('Editar empleado'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(labelText: 'Área'),
                ),
                const SizedBox(height: 8),
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
                  decoration:
                      const InputDecoration(labelText: 'Status', isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Guardar'),
            ),
          ],
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
        return AlertDialog(
          title: const Text('Dar de baja'),
          content: Text(
            '¿Deseas dar de baja a ${employee.firstName} ${employee.lastName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Aceptar'),
            ),
          ],
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
          return AlertDialog(
            title: const Text('Historial'),
            content: SizedBox(
              width: 400,
              height: 300,
              child: ListView.builder(
                itemCount: raw.length,
                itemBuilder: (context, index) {
                  final item = raw[index] as Map<String, dynamic>;
                  final ts = item['modifiedAt'] ?? item['date'];
                  final by = item['modifiedBy'] is Map
                      ? (item['modifiedBy']['email'] ??
                          item['modifiedBy']['username'] ??
                          '')
                      : (item['modifiedBy']?.toString() ?? '');
                  return ListTile(
                    dense: true,
                    title: Text(by),
                    subtitle: Text(ts.toString()),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (_) {}
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Área',
              isDense: true,
            ),
            onChanged: (val) {
              _filterArea = val.trim().isEmpty ? null : val.trim();
            },
            onSubmitted: (_) => _loadEmployees(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
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
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _loadEmployees,
          child: const Text('Filtrar'),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_employees.isEmpty) {
      return const Center(child: Text('Sin empleados'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Área')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: _employees.map((e) {
          final fullName = '${e.firstName} ${e.lastName}';
          return DataRow(
            cells: [
              DataCell(Text(fullName)),
              DataCell(Text(e.email)),
              DataCell(Text(e.area ?? '')),
              DataCell(Text(e.status ?? (e.isActive ? 'active' : 'inactive'))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editEmployee(e),
                    ),
                    IconButton(
                      tooltip: 'Historial',
                      icon: const Icon(Icons.history),
                      onPressed: () => _showHistory(e),
                    ),
                    IconButton(
                      tooltip: 'Dar de baja',
                      icon: const Icon(Icons.block),
                      onPressed: e.isActive ? () => _deactivateEmployee(e) : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Navbar(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Empleados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _exportCsv,
                  child: const Text('Exportar CSV'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _exportPdf,
                  child: const Text('Exportar PDF'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createEmployee,
                  child: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 12),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }
}
