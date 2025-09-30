import 'package:flutter/material.dart';
import 'package:test_project/views/pages/create_line_manager.dart';
import 'package:test_project/views/pages/employeelist_page.dart';

// import 'create_user_leave_page.dart'; // You’ll create this later

class AdminSettingsPage extends StatelessWidget {
  final List<_AdminOption> options = [
    _AdminOption(
      title: "Create Line Manager",
      icon: Icons.supervisor_account,
      page: CreateLineManagerPage(),
    ),
    _AdminOption(
      title: "View Employees",
      icon: Icons.person_3_outlined,
      page: EmployeeListPage(),  //Placeholder for now
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Settings")),
      body: ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(option.icon, color: Colors.blue),
              title: Text(option.title,
                  style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => option.page),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminOption {
  final String title;
  final IconData icon;
  final Widget page;

  _AdminOption({
    required this.title,
    required this.icon,
    required this.page,
  });
}
