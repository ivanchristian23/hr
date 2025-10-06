import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:test_project/views/pages/create_leave_page.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<dynamic> leaves = [];
  List<dynamic> filteredLeaves = [];

  String selectedStatus = "All";
  String selectedLeaveType = "All";

  Future<void> fetchLeaves() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) return;

    final res = await http.get(
      Uri.parse("https://coolbuffs.com/api/leaves/user/leaves"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      List<dynamic> data = jsonDecode(res.body);

      // Sort by start_date descending
      data.sort((a, b) => DateTime.parse(b['start_date'])
          .compareTo(DateTime.parse(a['start_date'])));

      setState(() {
        leaves = data;
        applyFilters();
      });
    }
  }

  void applyFilters() {
    setState(() {
      filteredLeaves = leaves.where((leave) {
        bool statusMatch =
            selectedStatus == "All" || leave['status'] == selectedStatus;
        bool typeMatch =
            selectedLeaveType == "All" || leave['leave_type'] == selectedLeaveType;
        return statusMatch && typeMatch;
      }).toList();
    });
  }

  String formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('MMMM-dd-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeaves();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Leaves", style: TextStyle(fontSize: 20))),
      body: Column(
        children: [
          // Filters (Stacked vertically)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: ["All", "Pending", "Approved", "Rejected"]
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    selectedStatus = value!;
                    applyFilters();
                  },
                  decoration: const InputDecoration(labelText: "Status")
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLeaveType,
                  items: [
                    "All",
                    "Annual Leave",
                    "Sick Leave",
                    "Compassionate Leave",
                    "Maternity Leave"
                  ]
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    selectedLeaveType = value!;
                    applyFilters();
                  },
                  decoration: const InputDecoration(labelText: "Leave Type"),
                ),
              ],
            ),
          ),

          // Leaves List
          Expanded(
            child: filteredLeaves.isEmpty
                ? const Center(child: Text("No leaves found."))
                : ListView.builder(
                    itemCount: filteredLeaves.length,
                    itemBuilder: (context, index) {
                      final leave = filteredLeaves[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: ListTile(
                          title: Text(
                            "${leave['leave_type']} (${leave['status']})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "From: ${formatDate(leave['start_date'])}\n"
                            "To: ${formatDate(leave['end_date'])}\n"
                            "New Balance: ${leave['balance']} days",
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateLeavePage()),
          );
          if (result == true) fetchLeaves();
        },
      ),
    );
  }
}
