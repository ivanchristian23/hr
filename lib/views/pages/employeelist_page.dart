import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test_project/views/pages/employeedetails_page.dart';

class EmployeeListPage extends StatefulWidget {
  @override
  _EmployeeListPageState createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  List employees = [];

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    final res = await http.get(Uri.parse("http://10.0.2.2:3000/userslist"));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        employees = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Employees"),
        centerTitle: true,
      ),
      body: employees.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                var emp = employees[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        emp['first_name'][0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      "${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(emp['job_title'] ?? "No Job Title"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      if (emp['id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EmployeeDetailsPage(userId: emp['id']),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
