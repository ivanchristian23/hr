import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_project/data/notifiers.dart';

// Import your existing pages
import 'package:test_project/views/pages/attendance_page.dart';
import 'package:test_project/views/pages/leave_page.dart';
import 'package:test_project/views/pages/mydetails_page.dart';
import 'package:test_project/views/pages/raise_request_page.dart';
import 'package:test_project/views/pages/admin_raise_request_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> newsletters = [];
  bool loadingImages = true;

  @override
  void initState() {
    super.initState();
    fetchNewsletterImages();
  }

  Future<void> fetchNewsletterImages() async {
    try {
      final response = await http.get(
        Uri.parse("https://coolbuffs.com/api/newsletter/"),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          newsletters = data
              .map(
                (e) => {
                  'title': e['title'].toString(),
                  'image_url': e['image_url'].toString(),
                },
              )
              .toList();
          loadingImages = false;
        });
      } else {
        setState(() {
          loadingImages = false;
        });
      }
    } catch (e) {
      setState(() {
        loadingImages = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = userRoleNotifier.value;

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'My Details', 'page': const MyDetailsPage()},
      {'title': 'Leaves', 'page': const LeavePage()},
      {
        'title': role == 'admin' ? 'Letter Requests' : 'Raise Request',
        'page': role == 'admin'
            ? const AdminRaiseRequestPage()
            : const RaiseRequestPage(),
      },
      {'title': 'Attendance', 'page': const AttendancePage()},
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "Workspace",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Grid of 4 cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 4 / 3,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => menuItems[index]['page'],
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Center(
                        child: Text(
                          menuItems[index]['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Newsletter section
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Newsletter",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Slideshow
                  SizedBox(
                    height: 260, // increased to fit image + title
                    child: loadingImages
                        ? const Center(child: CircularProgressIndicator())
                        : newsletters.isEmpty
                        ? const Center(child: Text("No newsletters available"))
                        : PageView.builder(
                            itemCount: newsletters.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          newsletters[index]['image_url'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      newsletters[index]['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
