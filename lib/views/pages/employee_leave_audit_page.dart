import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class EmployeeLeaveAuditPage extends StatefulWidget {
  final int userId;
  final String userName;

  const EmployeeLeaveAuditPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  _EmployeeLeaveAuditPageState createState() => _EmployeeLeaveAuditPageState();
}

class _EmployeeLeaveAuditPageState extends State<EmployeeLeaveAuditPage> {
  List<Map<String, dynamic>> auditData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaveAudit();
  }

  Future<void> fetchLeaveAudit() async {
    try {
      final res = await http.get(
        Uri.parse('https://coolbuffs.com/api/users/user_leave_audit/${widget.userId}'),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          auditData = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch leave audit (${res.statusCode})')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching leave audit: $e')),
      );
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.userName} - Leave Audit"),
        leading: const BackButton(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : auditData.isEmpty
              ? const Center(child: Text("No leave audit records found"))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: screenWidth),
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                            columns: const [
                              DataColumn(label: Text("Allowed Leave")),
                              DataColumn(label: Text("Consumed Annual")),
                              DataColumn(label: Text("Sick Balance")),
                              DataColumn(label: Text("Consumed Sick")),
                              DataColumn(label: Text("Compassionate")),
                              DataColumn(label: Text("Maternity")),
                              DataColumn(label: Text("Balance")),
                              DataColumn(label: Text("Created At")),
                              DataColumn(label: Text("Updated At")),
                            ],
                            rows: auditData.map((row) {
                              return DataRow(cells: [
                                DataCell(Text('${row['allowed_leave'] ?? '-'}')),
                                DataCell(Text('${row['consumed_annual_leave'] ?? '-'}')),
                                DataCell(Text('${row['sick_leave_balance'] ?? '-'}')),
                                DataCell(Text('${row['consumed_sick_leave'] ?? '-'}')),
                                DataCell(Text('${row['compassionate_leave_consumed'] ?? '-'}')),
                                DataCell(Text('${row['maternity_leaves_consumed'] ?? '-'}')),
                                DataCell(Text('${row['balance'] ?? '-'}')),
                                DataCell(Text(formatDate(row['created_at']))),
                                DataCell(Text(formatDate(row['updated_at']))),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
