import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ApproveRequestPage extends StatefulWidget {
  const ApproveRequestPage({super.key});

  @override
  State<ApproveRequestPage> createState() => _ApproveRequestPageState();
}

class _ApproveRequestPageState extends State<ApproveRequestPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<dynamic> allLeaves = [];
  List<dynamic> filteredLeaves = [];
  bool isLoading = true; // 👈 added loading flag

  String? selectedStatus;
  String? selectedLeaveType;

  Future<void> fetchLeaves() async {
    setState(() => isLoading = true); // start loading
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final res = await http.get(
      Uri.parse("https://coolbuffs.com/api/managers/requests"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      List<dynamic> data = jsonDecode(res.body);

      // Fetch user names for each leave
      for (var leave in data) {
        leave['user_name'] = await fetchUserName(leave['user_id'], token);
      }

      setState(() {
        allLeaves = List.from(data);
        applyFilters();
        isLoading = false; // stop loading
      });
    } else {
      print("Failed to load manager requests: ${res.body}");
      setState(() => isLoading = false);
    }
  }

  Future<String> fetchUserName(int userId, String token) async {
    final res = await http.get(
      Uri.parse("https://coolbuffs.com/api/users/user/name/$userId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['name'] ?? "Unknown";
    }
    return "Unknown";
  }

  void applyFilters() {
    setState(() {
      filteredLeaves = allLeaves.where((leave) {
        final statusMatch = selectedStatus == null || leave['status'] == selectedStatus;
        final typeMatch = selectedLeaveType == null || leave['leave_type'] == selectedLeaveType;
        return statusMatch && typeMatch;
      }).toList()
        ..sort((a, b) => b['start_date'].compareTo(a['start_date']));
    });
  }

  String formatDate(String dateStr) {
    try {
      return DateFormat('MMMM dd, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> updateLeaveStatus(int leaveId, String status) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) return;

    final res = await http.put(
      Uri.parse("https://coolbuffs.com/api/leaves/$leaveId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'status': status}),
    );

    if (res.statusCode == 200) {
      Navigator.pop(context);
      fetchLeaves();
    } else {
      print("Failed to update leave: ${res.body}");
    }
  }

  Future<void> downloadAttachment(int leaveId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not authorized")),
      );
      return;
    }

    final url = 'https://coolbuffs.com/api/leaves/$leaveId/attachment';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        String filename = 'attachment_$leaveId';
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null) {
          final regex = RegExp(r'filename="(.+)"');
          final match = regex.firstMatch(contentDisposition);
          if (match != null) {
            filename = match.group(1)!;
          }
        }

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        await OpenFile.open(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading: $e')),
      );
    }
  }

  void showLeaveDetails(Map<String, dynamic> leave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${leave['leave_type']} (${leave['status']})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 16),
                _buildDetailRow("Employee", leave['user_name']),
                _buildDetailRow("From", formatDate(leave['start_date'])),
                _buildDetailRow("To", formatDate(leave['end_date'])),
                _buildDetailRow("Balance", "${leave['balance']} days"),
                _buildDetailRow("Reason", leave['user_details'] ?? "Not provided"),

                const SizedBox(height: 20),

                if (leave['attachment'] != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[100],
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text("Download Attachment"),
                    onPressed: () => downloadAttachment(leave['id']),
                  ),

                const SizedBox(height: 20),

                if (leave['status'] == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
                          onPressed: () => updateLeaveStatus(leave['id'], 'approved'),
                          child: const Text("Approve"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[200]),
                          onPressed: () => updateLeaveStatus(leave['id'], 'rejected'),
                          child: const Text("Reject"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchLeaves();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave Requests to Approve")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 👈 show loading spinner
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DropdownButton<String>(
                        hint: const Text("Filter by Status"),
                        value: selectedStatus,
                        items: ['pending', 'approved', 'rejected']
                            .map((status) =>
                                DropdownMenuItem(value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) {
                          selectedStatus = value;
                          applyFilters();
                        },
                      ),
                      DropdownButton<String>(
                        hint: const Text("Filter by Leave Type"),
                        value: selectedLeaveType,
                        items: [
                          'Annual Leave',
                          'Sick Leave',
                          'Compassionate Leave',
                          'Maternity Leave'
                        ]
                            .map((type) =>
                                DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          selectedLeaveType = value;
                          applyFilters();
                        },
                      ),
                      if (selectedStatus != null || selectedLeaveType != null)
                        TextButton(
                          onPressed: () {
                            selectedStatus = null;
                            selectedLeaveType = null;
                            applyFilters();
                          },
                          child: const Text("Clear Filters"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  filteredLeaves.isEmpty
                      ? const Text("No leave requests found.")
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: filteredLeaves.length,
                          itemBuilder: (context, index) {
                            final leave = filteredLeaves[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(
                                  "${leave['leave_type']} (${leave['status']})",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Employee: ${leave['user_name']}\n"
                                  "From: ${formatDate(leave['start_date'])}\n"
                                  "To: ${formatDate(leave['end_date'])}\n"
                                  "Balance: ${leave['balance']} days",
                                ),
                                onTap: () => showLeaveDetails(leave),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchLeaves,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
