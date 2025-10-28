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
  List<dynamic> filteredEmployees = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final res = await http.get(
        Uri.parse('https://coolbuffs.com/api/users/userslist'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          employees = data;
          filteredEmployees = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load employees (${res.statusCode})')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching employees: $e')),
      );
    }
  }

  void filterEmployees(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredEmployees = employees.where((emp) {
        final firstName = emp['first_name']?.toString().toLowerCase() ?? '';
        final lastName = emp['last_name']?.toString().toLowerCase() ?? '';
        return firstName.contains(lowerQuery) || lastName.contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Employee Documents")),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by First Name or Last Name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: filterEmployees,
            ),
          ),

          // 📋 List of employees
          Expanded(
            child: filteredEmployees.isEmpty
                ? const Center(child: Text("No employees found"))
                : ListView.builder(
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            "${emp['first_name']} ${emp['last_name']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(emp['job_title'] ?? ""),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeDocumentsPage(
                                  userId: emp['id'],
                                  userName:
                                      "${emp['first_name']} ${emp['last_name']}",
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
