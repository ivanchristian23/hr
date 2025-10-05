import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MyDetailsPage extends StatefulWidget {
  const MyDetailsPage({super.key});

  @override
  State<MyDetailsPage> createState() => _MyDetailsPageState();
}

class _MyDetailsPageState extends State<MyDetailsPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late Future<Map<String, dynamic>> futureUserData;

  void testToken() async {
    final token = await storage.read(key: 'auth_token');
    print("DEBUG TOKEN: $token");
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final String? token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception("No auth token found");

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/users/user/home'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user data: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    testToken();
    futureUserData = fetchUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Details"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureUserData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final String fullName = '${data['first_name']} ${data['last_name']}';
          final String jobTitle = data['job_title'] ?? 'N/A';
          final String dateOfJoining = data['date_of_joining'] ?? 'N/A';

          String formattedDate = 'N/A';
          if (dateOfJoining != 'N/A') {
            try {
              final DateTime parsedDate = DateTime.parse(dateOfJoining);
              formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
            } catch (e) {
              formattedDate = 'Invalid Date';
            }
          }

          final String lineManager = data['line_manager'] ?? 'N/A';
          final String annualLeave = data['balance']?.toString() ?? 'N/A';
          final int sickLeave = data['sick_leave_balance'] ?? 0;

          final List<Map<String, String>> details = [
            {'title': 'Date of Joining', 'value': formattedDate},
            {'title': 'Line Manager', 'value': lineManager},
            {'title': 'Annual Leave Balance', 'value': '$annualLeave days'},
            {'title': 'Sick Leave Balance', 'value': '$sickLeave days'},
          ];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header card with name and job title
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      jobTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Details list
              ...details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          detail['title']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          detail['value']!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
