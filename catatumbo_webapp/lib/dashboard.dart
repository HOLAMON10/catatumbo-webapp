import 'dart:async';
import 'dart:ui_web' as ui;
import 'dart:html';

import 'package:flutter/material.dart';
import 'models/user.dart';
import 'navbar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedStatus = "ALL";
  String selectedProvince = "ALL";

  final String viewId = "mongo-dashboard-sdk";
  bool _isRegistered = false;
  bool _hasDashboard = true;

  late String baseUrl;
  late String dashboardId;

  Timer? _filterDebounce;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    final dashboardUrl = UserData.dashboard;

    if (dashboardUrl == null || dashboardUrl.isEmpty) {
      _hasDashboard = false;
      setState(() {});
      return;
    }

    final uri = Uri.parse(dashboardUrl);
    baseUrl = "${uri.scheme}://${uri.host}/${uri.pathSegments[0]}";
    dashboardId = uri.pathSegments[1];

    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (_isRegistered) return;

    ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final containerId = "dashboard-container-$id";

      final container = DivElement()
        ..id = containerId
        ..style.width = "100%"
        ..style.height = "100%"
        ..style.overflow = "hidden"
        ..style.pointerEvents = "auto";

      final sdkScript = ScriptElement()
        ..src = "https://unpkg.com/@mongodb-js/charts-embed-dom"
        ..type = "text/javascript";

      sdkScript.onLoad.listen((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          final initScript = ScriptElement()
            ..type = "text/javascript"
            ..text = '''
              (function() {
                try {
                  const sdk = new ChartsEmbedSDK({
                    baseUrl: "$baseUrl"
                  });

                  const dashboard = sdk.createDashboard({
                    dashboardId: "$dashboardId",
                    heightMode: "fixed",
                    widthMode: "scale"
                  });

                  window._mongoDashboard = dashboard;
                  window._filterBusy = false;

                  dashboard.render(
                    document.getElementById("$containerId")
                  ).catch((err) => {
                    console.error("Dashboard render error:", err);
                  });

                  window.addEventListener("message", (event) => {
                    if (event.data?.type === "APPLY_FILTERS") {
                      if (window._filterBusy) return;

                      const filters = event.data.filters;
                      window._filterBusy = true;

                      dashboard.setFilter(filters)
                        .then(() => window._filterBusy = false)
                        .catch((err) => {
                          console.error("Filter error:", err);
                          window._filterBusy = false;
                          dashboard.refresh();
                        });
                    }
                  });
                } catch (err) {
                  console.error("SDK initialization error:", err);
                }
              })();
            ''';

          document.head!.append(initScript);
        });
      });

      sdkScript.onError.listen((error) {
        print("Failed to load MongoDB Charts SDK: $error");
      });

      document.head!.append(sdkScript);

      return container;
    });

    _isRegistered = true;
    setState(() {});
  }

  void applyFilters() {
    if (_filterDebounce?.isActive ?? false) {
      _filterDebounce!.cancel();
    }

    _filterDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_isRefreshing) return;
      _isRefreshing = true;

      final filters = <String, dynamic>{};

      if (selectedStatus != "ALL") {
        filters["status"] = selectedStatus;
      }

      if (selectedProvince != "ALL") {
        filters["addressProvince"] = selectedProvince;
      }

      window.postMessage({
        "type": "APPLY_FILTERS",
        "filters": filters
      }, "*");

      Future.delayed(const Duration(seconds: 1), () {
        _isRefreshing = false;
      });
    });
  }

  void setDashboardPointerEvents(bool enabled) {
    final elements = document.querySelectorAll('[id^="dashboard-container"]');
    for (final el in elements) {
      (el as DivElement).style.pointerEvents = enabled ? "auto" : "none";
    }
  }

  @override
  Widget build(BuildContext context) {
    // ESTADO SIN DASHBOARD CONFIGURADO
    if (!_hasDashboard) {
      return Scaffold(
        appBar: const Navbar(),
        body: Container(
          color: const Color(0xFFF4F5F7),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.dashboard_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No hay dashboard conectado",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Contacta al administrador para configurar la vista de analíticos.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ESTADO CARGANDO SDK
    if (!_isRegistered) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // DASHBOARD ACTIVO
    return Scaffold(
      appBar: const Navbar(),
      body: Container(
        color: const Color(0xFFF4F5F7),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // HEADER
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Panel general",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Visualiza métricas clave de empleados y actividad.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD FILTROS
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _styledDropdown(
                              label: "Estado",
                              value: selectedStatus,
                              items: const [
                                "ALL",
                                "HIRED",
                                "PROBATION",
                                "ON_LEAVE",
                                "SEPARATED",
                                "TERMINATED"
                              ],
                              onChanged: (value) {
                                setState(() => selectedStatus = value);
                                applyFilters();
                                setDashboardPointerEvents(true);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _styledDropdown(
                              label: "Provincia",
                              value: selectedProvince,
                              items: const [
                                "ALL",
                                "Gauteng",
                                "Western Cape",
                                "KwaZulu-Natal",
                                "Eastern Cape",
                                "Free State"
                              ],
                              onChanged: (value) {
                                setState(() => selectedProvince = value);
                                applyFilters();
                                setDashboardPointerEvents(true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD PRINCIPAL CON EL DASHBOARD EMBEBIDO
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.dashboard_outlined, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  "Dashboard de analíticos",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.more_horiz,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Material(
                                  elevation: 0,
                                  color: Colors.white,
                                  child: HtmlElementView(viewType: viewId),
                                ),
                              ),
                            ),
                          ],
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

  Widget _styledDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e.replaceAll("_", " ")),
            ),
          )
          .toList(),
      onTap: () => setDashboardPointerEvents(false),
      onChanged: (val) => onChanged(val!),
    );
  }
}
