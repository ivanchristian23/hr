import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final int userId;
  const EmployeeDetailsPage({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _EmployeeDetailsPageState createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final res = await http.get(
      Uri.parse("http://10.0.2.2:3000/users/userslist/${widget.userId}"),
    );
    if (res.statusCode == 200) {
      setState(() {
        userData = json.decode(res.body);
      });
    }
  }

  /// Format date as "dd MMM yyyy"
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "Not Available";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat("dd MMM yyyy").format(date);
    } catch (e) {
      return dateString; // fallback in case parsing fails
    }
  }

  Widget buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value ?? "Not Available",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Employee Details")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final leaves = userData!['leaves'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${userData!['first_name'] ?? ''} ${userData!['last_name'] ?? ''}",
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Personal Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    buildInfoRow("Job Title", userData!['job_title']),
                    SizedBox(height: 10),
                    buildInfoRow("Line Manager", userData!['line_manager']),
                    SizedBox(height: 10),
                    buildInfoRow(
                      "Date of Joining",
                      formatDate(userData!['date_of_joining']),
                      
                    ),SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // 🔹 Leave Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Leave Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    buildInfoRow(
                      "Allowed Leave",
                      "${leaves['allowed_leave'] ?? 'HR needs to update information'}",
                    ),SizedBox(height: 10),
                    buildInfoRow(
                      "Consumed Annual Leave",
                      "${leaves['consumed_annual_leave'] ?? 'HR needs to update information'}",
                    ),SizedBox(height: 10),
                    buildInfoRow(
                      "Sick Leave Balance",
                      "${leaves['sick_leave_balance'] ?? 'HR needs to update information'}",
                    ),SizedBox(height: 10),
                    buildInfoRow(
                      "Consumed Sick Leave",
                      "${leaves['consumed_sick_leave'] ?? 'HR needs to update information'}",
                    ),SizedBox(height: 10),
                    buildInfoRow(
                      "Compassionate Leave",
                      "${leaves['compassionate_leave_consumed'] ?? 'HR needs to update information'}",
                    ),SizedBox(height: 10),
                    buildInfoRow(
                      "Maternity Leaves",
                      "${leaves['maternity_leaves_consumed'] ?? 'HR needs to update information'}",
                    ),SizedBox(height: 10),
                    buildInfoRow(
                      "Balance",
                      "${leaves['balance'] ?? 'HR needs to update information'}",
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to edit personal info page
                  },
                  icon: Icon(Icons.edit),
                  label: Text("Edit Personal Info"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to edit leave info page
                  },
                  icon: Icon(Icons.edit_calendar),
                  label: Text("Edit Leave Info"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
