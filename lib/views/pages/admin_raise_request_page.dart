import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminRaiseRequestPage extends StatefulWidget {
  const AdminRaiseRequestPage({super.key});

  @override
  State<AdminRaiseRequestPage> createState() => _AdminRaiseRequestPageState();
}

class _AdminRaiseRequestPageState extends State<AdminRaiseRequestPage> {
  List<dynamic> letterRequests = [];
  List<dynamic> reimbursementRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      const baseUrl =
          'https://www.coolbuffs.com/api/raiserequest'; // Change to your server IP/domain

      final letterResponse = await http.get(
        Uri.parse('$baseUrl/letter-request'),
      );
      final reimbursementResponse = await http.get(
        Uri.parse('$baseUrl/reimbursement-request'),
      );

      if (letterResponse.statusCode == 200 &&
          reimbursementResponse.statusCode == 200) {
        setState(() {
          letterRequests = jsonDecode(letterResponse.body);
          reimbursementRequests = jsonDecode(reimbursementResponse.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load requests");
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Requests Dashboard"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRequests,
              child: ListView(
                padding: const EdgeInsets.all(12.0),
                children: [
                  const Text(
                    "Letter Requests",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...letterRequests
                      .map((req) => _buildLetterCard(req))
                      .toList(),
                  const SizedBox(height: 24),
                  const Text(
                    "Reimbursement Requests",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...reimbursementRequests
                      .map((req) => _buildReimbursementCard(req))
                      .toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildLetterCard(dynamic req) {
    final fullName = "${req['first_name'] ?? ''} ${req['last_name'] ?? ''}"
        .trim();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.mail_outline, color: Colors.blueAccent),
        title: Text(req['letter_type'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (req['description'] != null) Text(req['description']),
            if (fullName.isNotEmpty)
              Text(
                "Requested by: $fullName",
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
        trailing: Text(
          _formatDate(req['created_at']),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildReimbursementCard(dynamic req) {
    final fullName = "${req['first_name'] ?? ''} ${req['last_name'] ?? ''}"
        .trim();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.green),
        title: Text("QAR ${req['amount']}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (req['description'] != null) Text(req['description']),
            if (fullName.isNotEmpty)
              Text(
                "Requested by: $fullName",
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
        trailing: Text(
          _formatDate(req['created_at']),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return "";
    final date = DateTime.parse(dateTimeString);
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
