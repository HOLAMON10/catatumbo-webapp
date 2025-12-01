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

  late String baseUrl;
  late String dashboardId;

  Timer? _filterDebounce;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    final dashboardUrl = UserData.dashboard;

    
      if (dashboardUrl == null || dashboardUrl.isEmpty) {
        return; // stop setup gracefully
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
                  ).then(() => {
                    console.log("Dashboard rendered successfully");
                  }).catch((err) => {
                    console.error("Dashboard render error:", err);
                  });

                  window.addEventListener("message", (event) => {
                    if (event.data?.type === "APPLY_FILTERS") {
                      if (window._filterBusy) return;

                      const filters = event.data.filters;
                      window._filterBusy = true;

                      dashboard.setFilter(filters)
                        .then(() => {
                          console.log("Filters applied safely");
                          window._filterBusy = false;
                        })
                        .catch((err) => {
                          console.error("Filter error:", err);
                          window._filterBusy = false;

                          dashboard.refresh().catch(() => {
                            setTimeout(() => dashboard.refresh(), 1000);
                          });
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
    if (!_isRegistered) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const Navbar(),
      body: Container(
        color: const Color(0xFFF4F6FA),
        child: Column(
          children: [

            // 🌿 FILTER BAR (CONTAINED)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _styledDropdown(
                          label: "Status",
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
                      const SizedBox(width: 20),
                      Expanded(
                        child: _styledDropdown(
                          label: "Province",
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
            ),

            // 🌒 DASHBOARD (CENTERED CARD)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Material(
                        elevation: 12,
                        color: Colors.white,
                        child: HtmlElementView(viewType: viewId),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
