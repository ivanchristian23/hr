import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:test_project/views/widgets/card_tile_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  void testToken() async {
    final token = await storage.read(key: 'auth_token');
    print("DEBUG TOKEN: $token");
  }
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late Future<Map<String, dynamic>> futureUserData;

  Future<Map<String, dynamic>> fetchUserData() async {
    final String? token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception("No auth token found");

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/user/home'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('Token: $token');
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
    return FutureBuilder<Map<String, dynamic>>(
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
        final DateTime parsedDate = DateTime.parse(dateOfJoining);
        final String formattedDate = DateFormat('dd MMM yyyy').format(parsedDate); 
        final String lineManager = data['line_manager'] ?? 'N/A';
        final String annualLeave = data['balance'] ?? 'N/A';
        final int sickLeave = data['sick_leave_balance'] ?? 0;

        final List<Map<String, String>> cards = [
          {'title': 'Employee Name', 'value': fullName},
          {'title': 'Job Title', 'value': jobTitle},
          {'title': 'Date of Joining', 'value': formattedDate},
          {'title': 'Line Manager', 'value': lineManager},
          {'title': 'Annual Leave Balance', 'value': '$annualLeave days'},
          {'title': 'Sick Leave Balance', 'value': '$sickLeave days'},
        ];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3 / 2,
            ),
            itemBuilder: (context, index) {
              return CardTile(
                title: cards[index]['title']!,
                value: cards[index]['value']!,
              );
            },
          ),
        );
      },
    );
  }
}
