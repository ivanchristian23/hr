import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class CreateLeavePage extends StatefulWidget {
  const CreateLeavePage({super.key});

  @override
  State<CreateLeavePage> createState() => _CreateLeavePageState();
}

class _CreateLeavePageState extends State<CreateLeavePage> {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  DateTime? startDate;
  DateTime? endDate;
  String leaveType = 'Annual Leave';
  final countController = TextEditingController();
  final detailsController = TextEditingController();
  File? selectedFile;

  Future<void> pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  int? userId;
  int? lineManagerId;
  Map<String, dynamic>? leaveBalances;

  Future<void> fetchLeaveBalances() async {
    final token = await storage.read(key: 'auth_token');
    final res = await http.get(
      Uri.parse('https://coolbuffs.com/api/users/user/leave-balances'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      setState(() {
        leaveBalances = jsonDecode(res.body);
      });
    }
  }

  Future<void> fetchUserAndManager() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      print("❌ No token found");
      return;
    }

    print("🔑 Token found, fetching user ID...");

    // 1️⃣ Get user ID
    final userRes = await http.get(
      Uri.parse("https://coolbuffs.com/api/users/user/id"),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("📡 User ID API response: ${userRes.statusCode}");
    if (userRes.statusCode == 200) {
      final userData = jsonDecode(userRes.body);
      setState(() {
        userId = userData['id'];
      });
      print("✅ User ID loaded: $userId");

      // 2️⃣ Get line_manager_id
      print("🔍 Fetching line manager for user ID: $userId");
      final managerRes = await http.get(
        Uri.parse(
          "https://coolbuffs.com/api/users/user/line-manager/${userData['id']}",
        ),
      );
      print("📡 Line Manager API response: ${managerRes.statusCode}");
      print("📄 Line Manager Response Body: ${managerRes.body}");

      if (managerRes.statusCode == 200) {
        final managerData = jsonDecode(managerRes.body);
        setState(() {
          lineManagerId = managerData['line_manager_id'];
        });
        print("✅ Line Manager ID loaded: $lineManagerId");
      } else {
        print("❌ Failed to load line manager ID");
      }
    } else {
      print("❌ Failed to load user ID: ${userRes.body}");
    }
  }

  void calculateLeaveCount() {
    if (startDate != null && endDate != null) {
      if (endDate!.isBefore(startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End date cannot be before start date")),
        );
        countController.clear();
        return;
      }
      final days = endDate!.difference(startDate!).inDays + 1;
      countController.text = days.toString();
    }
  }

  Future<void> submitLeave() async {
    if (!_formKey.currentState!.validate()) return;
    if (userId == null || lineManagerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID or Manager ID not loaded")),
      );
      return;
    }

    // ✅ Validate leave count against available balance
    final count = int.tryParse(countController.text) ?? 0;
    if (leaveType == 'Annual Leave' &&
        leaveBalances != null &&
        count > (leaveBalances!['balance'] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You cannot request more than your annual leave balance (${leaveBalances!['balance']} days).",
          ),
        ),
      );
      return;
    }

    if (leaveType == 'Sick Leave' &&
        leaveBalances != null &&
        count > (leaveBalances!['sick_leave_balance'] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You cannot request more than your sick leave balance (${leaveBalances!['sick_leave_balance']} days).",
          ),
        ),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("https://coolbuffs.com/api/leaves/createleaves"),
    );

    request.fields['user_id'] = userId.toString();
    request.fields['line_manager_id'] = lineManagerId.toString();
    request.fields['start_date'] = startDate!.toIso8601String();
    request.fields['end_date'] = endDate!.toIso8601String();
    request.fields['leave_type'] = leaveType;
    request.fields['count'] = countController.text;
    request.fields['details'] = detailsController.text;
    request.fields['status'] = "Pending";

    if (selectedFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('attachment', selectedFile!.path),
      );
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            jsonDecode(responseData)['message'] ?? "Leave created successfully",
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            jsonDecode(responseData)['message'] ?? "Leave creation failed",
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserAndManager();
    fetchLeaveBalances();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply for Leave")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Start Date'),
              ListTile(
                title: Text(
                  startDate == null
                      ? "Select Start Date"
                      : startDate.toString().split(" ")[0],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(), // ✅ No past dates
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                    calculateLeaveCount();
                  }
                },
              ),
              Text('End Date'),
              ListTile(
                title: Text(
                  endDate == null
                      ? "Select End Date"
                      : endDate.toString().split(" ")[0],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  if (startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Select start date first")),
                    );
                    return;
                  }
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate!,
                    firstDate:
                        startDate!, // ✅ End date cannot be before start date
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                    calculateLeaveCount();
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: leaveType,
                items:
                    [
                          'Annual Leave',
                          'Sick Leave',
                          'Compassionate Leave',
                          'Maternity Leave',
                        ]
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => leaveType = value!),
                decoration: const InputDecoration(labelText: "Leave Type"),
              ),
              SizedBox(height: 10),
              if (leaveBalances != null) ...[
                Text(
                  "Annual Leave Balance: ${leaveBalances!['balance']} days",
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  "Sick Leave Balance: ${leaveBalances!['sick_leave_balance']} days",
                  style: TextStyle(fontSize: 15),
                ),
              ],
              TextFormField(
                controller: countController,
                readOnly: true, // ✅ Auto-calculated
                decoration: const InputDecoration(labelText: "Number of Days"),
              ),
              TextFormField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: "Details"),
                maxLines: 3,
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter details" : null,
              ),
              ElevatedButton.icon(
                onPressed: pickAttachment,
                icon: Icon(Icons.attach_file),
                label: Text(
                  selectedFile == null ? "Add Attachment" : "Change Attachment",
                ),
              ),
              if (selectedFile != null)
                Text("Selected: ${selectedFile!.path.split('/').last}"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitLeave,
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
