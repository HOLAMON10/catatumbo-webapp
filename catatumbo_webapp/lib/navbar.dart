import 'package:flutter/material.dart';
import 'session.dart';
import 'models/user.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final displayName =
        "${UserData.firstName ?? ''} ${UserData.lastName ?? ''}".trim();

    Widget navItem({
      required String label,
      required String route,
      IconData? icon,
    }) {
      final bool isActive = currentRoute == route;

      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: currentRoute == route
            ? null
            : () {
                Navigator.pushReplacementNamed(context, route);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? Colors.black : Colors.black54,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.black : Colors.black54,
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget configMenu() {
      return PopupMenuButton<String>(
        tooltip: "Configuración",
        offset: const Offset(0, 30),
        position: PopupMenuPosition.under,
        onSelected: (value) {
          if (value == "users") {
            Navigator.pushReplacementNamed(context, '/users');
          } else if (value == "access") {
            Navigator.pushReplacementNamed(context, '/access-profiles');
          }
          else if (value == "meetingrooms") {
            Navigator.pushReplacementNamed(context, '/meeting-rooms');
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: "users",
            child: Text("Usuarios"),
          ),
          PopupMenuItem(
            value: "access",
            child: Text("Perfiles de acceso"),
          ),
          PopupMenuItem(
            value: "meetingrooms",
            child: Text("Salas de Reuniones"),
          ),
        ],
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: Colors.black54,
                ),
                SizedBox(width: 6),
                Text(
                  'Configuración',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    // Logo / marca
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'C',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Catatumbo Panel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 32),

                    // Centro: navegación
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          navItem(
                            label: 'Dashboard',
                            route: '/dashboard',
                            icon: Icons.dashboard_outlined,
                          ),
                          navItem(
                            label: 'Empleados',
                            route: '/employees',
                            icon: Icons.group_outlined,
                          ),
                          navItem(
                            label: 'Reservaciones',
                            route: '/reservations',
                            icon: Icons.group_outlined,
                          ),
                          const SizedBox(width: 4),
                          configMenu(), // solo una vez "Configuración"
                        ],
                      ),
                    ),

                    // Derecha: usuario + logout
                    PopupMenuButton<String>(
                      tooltip: "",
                      position: PopupMenuPosition.under,
                      onSelected: (value) async {
                        if (value == "logout") {
                          await Session.clear();
                          UserData.clear();
                          // ignore: use_build_context_synchronously
                          Navigator.pushReplacementNamed(context, '/');
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "logout",
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18),
                              SizedBox(width: 8),
                              Text("Cerrar sesión"),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayName.isEmpty ? "Usuario" : displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ],
                        ),
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
}
