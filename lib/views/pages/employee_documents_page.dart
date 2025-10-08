import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/views/pages/employee_document_page.dart';
import 'dart:convert';

class EmployeeDocumentsListPage extends StatefulWidget {
  @override
  _EmployeeDocumentsListPageState createState() =>
      _EmployeeDocumentsListPageState();
}

class _EmployeeDocumentsListPageState extends State<EmployeeDocumentsListPage> {
  List<dynamic> employees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    final res = await http.get(
      Uri.parse('https://coolbuffs.com/api/users/userslist'), // fetch all users
    );
    if (res.statusCode == 200) {
      setState(() {
        employees = json.decode(res.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      // handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text("Employee Documents")),
      body: ListView.builder(
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final emp = employees[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text("${emp['first_name']} ${emp['last_name']}"),
              subtitle: Text(emp['job_title'] ?? ""),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EmployeeDocumentsPage(userId: emp['id'],userName: emp['last_name'],),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
