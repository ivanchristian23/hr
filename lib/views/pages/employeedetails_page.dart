import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:test_project/views/pages/employee_leave_audit_page.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final int userId;
  const EmployeeDetailsPage({super.key, required this.userId});

  @override
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
      Uri.parse("https://coolbuffs.com/api/users/userslist/${widget.userId}"),
    );
    if (res.statusCode == 200) {
      setState(() {
        final decoded = json.decode(res.body);
        userData = Map<String, dynamic>.from(decoded);
        if (userData!['leaves'] != null) {
          userData!['leaves'] = Map<String, dynamic>.from(userData!['leaves']);
        }
      });
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "Not Available";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat("dd MMM yyyy").format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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

  void showEditPersonalInfoModal(BuildContext context) {
    final jobTitleController = TextEditingController(
      text: userData?['job_title'] ?? '',
    );
    final lineManagerController = TextEditingController(
      text: userData?['line_manager'] ?? '',
    );
    final userTypeController = TextEditingController(
      text: userData?['user_type'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ), // for keyboard
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Edit Personal Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: jobTitleController,
              decoration: InputDecoration(labelText: "Job Title"),
            ),
            TextField(
              controller: lineManagerController,
              decoration: InputDecoration(labelText: "Line Manager"),
            ),
            TextField(
              controller: userTypeController,
              decoration: InputDecoration(labelText: "User Type"),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await updatePersonalInfo(
                  jobTitleController.text,
                  lineManagerController.text,
                  userTypeController.text,
                );
                Navigator.pop(context);
              },
              icon: Icon(Icons.save),
              label: Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  void showEditLeaveInfoModal(
    BuildContext context,
    Map<String, dynamic> leaves,
  ) {
    final allowedLeave = TextEditingController(
      text: leaves['allowed_leave']?.toString() ?? '',
    );
    final consumedAnnual = TextEditingController(
      text: leaves['consumed_annual_leave']?.toString() ?? '',
    );
    final sickBalance = TextEditingController(
      text: leaves['sick_leave_balance']?.toString() ?? '',
    );
    final consumedSick = TextEditingController(
      text: leaves['consumed_sick_leave']?.toString() ?? '',
    );
    final compassionate = TextEditingController(
      text: leaves['compassionate_leave_consumed']?.toString() ?? '',
    );
    final maternity = TextEditingController(
      text: leaves['maternity_leaves_consumed']?.toString() ?? '',
    );
    final balance = TextEditingController(
      text: leaves['balance']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Leave Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: allowedLeave,
                decoration: InputDecoration(labelText: "Allowed Leave"),
              ),
              TextField(
                controller: consumedAnnual,
                decoration: InputDecoration(labelText: "Consumed Annual Leave"),
              ),
              TextField(
                controller: sickBalance,
                decoration: InputDecoration(labelText: "Sick Leave Balance"),
              ),
              TextField(
                controller: consumedSick,
                decoration: InputDecoration(labelText: "Consumed Sick Leave"),
              ),
              TextField(
                controller: compassionate,
                decoration: InputDecoration(labelText: "Compassionate Leave"),
              ),
              TextField(
                controller: maternity,
                decoration: InputDecoration(labelText: "Maternity Leave"),
              ),
              TextField(
                controller: balance,
                decoration: InputDecoration(labelText: "Balance"),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await updateLeaveInfo({
                    "allowed_leave": allowedLeave.text,
                    "consumed_annual_leave": consumedAnnual.text,
                    "sick_leave_balance": sickBalance.text,
                    "consumed_sick_leave": consumedSick.text,
                    "compassionate_leave_consumed": compassionate.text,
                    "maternity_leaves_consumed": maternity.text,
                    "balance": balance.text,
                  });
                  Navigator.pop(context);
                },
                icon: Icon(Icons.save),
                label: Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updatePersonalInfo(
    String jobTitle,
    String manager,
    String userType,
  ) async {
    final response = await http.put(
      Uri.parse(
        "https://coolbuffs.com/api/users/edit_user_info/${widget.userId}",
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'job_title': jobTitle,
        'line_manager': manager,
        'user_type': userType,
      }),
    );
    if (response.statusCode == 200) {
      fetchUserDetails();
    }
  }

  Future<void> updateLeaveInfo(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(
        "https://coolbuffs.com/api/users/edit_user_leave/${widget.userId}",
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      fetchUserDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Employee Details")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final leaves = Map<String, dynamic>.from(userData!['leaves'] ?? {});

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
                    buildInfoRow("Line Manager", userData!['line_manager']),
                    buildInfoRow("Employment Type", userData!['user_type']),
                    buildInfoRow(
                      "Date of Joining",
                      formatDate(userData!['date_of_joining']),
                    ),
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
                      "${leaves['allowed_leave'] ?? 'HR needs to update'}",
                    ),
                    buildInfoRow(
                      "Consumed Annual Leave",
                      "${leaves['consumed_annual_leave'] ?? 'HR needs to update'}",
                    ),
                    buildInfoRow(
                      "Sick Leave Balance",
                      "${leaves['sick_leave_balance'] ?? 'HR needs to update'}",
                    ),
                    buildInfoRow(
                      "Consumed Sick Leave",
                      "${leaves['consumed_sick_leave'] ?? 'HR needs to update'}",
                    ),
                    buildInfoRow(
                      "Compassionate Leave",
                      "${leaves['compassionate_leave_consumed'] ?? 'HR needs to update'}",
                    ),
                    buildInfoRow(
                      "Maternity Leave",
                      "${leaves['maternity_leaves_consumed'] ?? 'HR needs to update'}",
                    ),
                    buildInfoRow(
                      "Balance",
                      "${leaves['balance'] ?? 'HR needs to update'}",
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            SizedBox(height: 20),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => showEditPersonalInfoModal(context),
                  icon: Icon(Icons.edit),
                  label: Text("Edit Personal Info"),
                ),
                ElevatedButton.icon(
                  onPressed: () => showEditLeaveInfoModal(context, leaves),
                  icon: Icon(Icons.edit_calendar),
                  label: Text("Edit Leave Info"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EmployeeLeaveAuditPage(userId: widget.userId, userName: "${userData!['first_name']} ${userData!['last_name']}",),
                      ),
                    );
                  },
                  icon: Icon(Icons.history),
                  label: Text("Leave Audit"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
