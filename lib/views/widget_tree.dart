import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/data/constants.dart';
import 'package:test_project/data/notifiers.dart';
import 'package:test_project/views/pages/admin_settings_page.dart';
import 'package:test_project/views/pages/approve_req_page.dart';
import 'package:test_project/views/pages/leave_page.dart';
import 'package:test_project/views/pages/home_page.dart';
import 'package:test_project/views/pages/profile_page.dart';
import 'package:test_project/views/pages/welcome_page.dart';
import 'package:test_project/views/widgets/navbar_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

List<Widget> getPagesForRole(String role) {
  if (role == 'admin') {
    return [HomePage(), ApproveRequestPage(), AdminSettingsPage()];
  } else {
    return [HomePage(), LeavePage(), ProfilePage()];
  }
}

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Proztec Employee App"),
        actions: [
          IconButton(
            onPressed: () async {
              isDarkModeNotifier.value =
                  !isDarkModeNotifier.value; // Toggle dark mode
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(
                KConstants.themeModeKey,
                isDarkModeNotifier.value,
              );
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDarkMode, child) {
                return Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode);
              },
            ),
          ),
          const SizedBox(width: 8), // 👈 Adds spacing before logout button
          // Logout button
          IconButton(
            onPressed: () async {
              const storage = FlutterSecureStorage();

              // Delete the stored token
              await storage.delete(key: 'auth_token');

              // Optionally, reset selected page index
              selectedPageNotifier.value = 0;

              // Navigate back to Welcome/Login page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const WelcomePage(), // Make sure to import WelcomePage
                ),
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
          // IconButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) {
          //           return AdminSettingsPage();
          //         },
          //       ),
          //     );
          //   },
          //   icon: Icon(Icons.settings),
          // ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: userRoleNotifier,
        builder: (context, role, _) {
          final pages = getPagesForRole(role);
          return ValueListenableBuilder(
            valueListenable: selectedPageNotifier,
            builder: (context, selectedPage, _) {
              return pages.elementAt(selectedPage);
            },
          );
        },
      ),
      bottomNavigationBar: NavbarWidget(),
    );
  }
}
