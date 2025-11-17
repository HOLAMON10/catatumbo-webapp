import 'package:flutter/material.dart';
import 'session.dart';
import 'user.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final displayName =
        "${UserData.firstName ?? ''} ${UserData.lastName ?? ''}".trim();

    return AppBar(
      backgroundColor: Colors.blueGrey,
      title: const Text("My App", style: TextStyle(color: Colors.white)),
      actions: [
        // HOME BUTTON
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          child: const Text(
            "Home",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),

        // CONFIGURATION DROPDOWN
        PopupMenuButton<String>(
          tooltip: "Configuration",
          offset: const Offset(0, 40),
          position: PopupMenuPosition.under,
          onSelected: (value) {
            if (value == "users") {
              Navigator.pushReplacementNamed(context, '/users');
            } else if (value == "access") {
              Navigator.pushReplacementNamed(context, '/access-profiles');
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "Configuration",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "users",
              child: Text("Users"),
            ),
            const PopupMenuItem(
              value: "access",
              child: Text("Access Profiles"),
            ),
          ],
        ),

        // EMPLOYEES BUTTON
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/employees');
          },
          child: const Text(
            "Employees",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),

        // USER MENU
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: PopupMenuButton<String>(
            tooltip: "",
            position: PopupMenuPosition.under,
            onSelected: (value) async {
              if (value == "logout") {
                await Session.clear();
                UserData.clear();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "logout",
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text("Log Out"),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    displayName.isEmpty ? "User" : displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
