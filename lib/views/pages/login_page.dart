import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:test_project/data/notifiers.dart';
import 'package:test_project/views/pages/forget_password_page.dart';
import 'package:test_project/views/widget_tree.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();
  // @override
  // void initState() {
  //   print('initState called');
  //   super.initState();
  // }


  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // double screenWidth = MediaQuery.of(context).size.width; to know the width of the screen
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                //layoutbuilder to make it responsive for all the screens
                return FractionallySizedBox(
                  widthFactor: constraints.maxWidth > 500
                      ? 0.5
                      : 1.0, // can be put here the screenwidth just change the constraints.maxWidth
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/lotties/Wavey_Birdie.json',
                        height: 300.0,
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: controllerEmail,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        onEditingComplete: () {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: controllerPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),obscureText: true,
                        onEditingComplete: () {
                          setState(() {});
                        },
                      ),
                      TextButton(onPressed: () {
                        Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ForgotPasswordPage();
                        },
                      ),
                    );
                        
                      },style: TextButton.styleFrom(minimumSize: Size(double.infinity, 40.0),alignment: Alignment.bottomRight), child: Text('Reset Password'),),
                      FilledButton(
                        onPressed: () {
                          onLoginPressed();
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: Size(double.infinity, 40.0),
                        ),
                        child: Text(widget.title),
                      ),
                       const SizedBox(height: 20.0),

                      // Tagline below login button
                      const Text(
                        '"Success is a constant evolution"\n- Syed Rizwan Shah (CEO)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 40.0),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // void onLoginPressed() {
  //   if (confirmedEmail == controllerEmail.text &&
  //       confirmedPw == controllerPassword.text) {
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) {
      //       return WidgetTree();
      //     },
      //   ),
      //   (route) => false, // Remove all previous routes
      // );
  //   }
  // }
  void onLoginPressed() async {
    final storage = FlutterSecureStorage();
    final response = await http.post(
      Uri.parse('https://coolbuffs.com/api/auth/login'), // For Android Emulator
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': controllerEmail.text,
        'password': controllerPassword.text,
      }),
    );

    final result = jsonDecode(response.body);
    print(result);
    if (result['success'] == true) {
      userRoleNotifier.value = result['role']; // Save role in notifier
      await storage.write(key: 'auth_token', value: result['token']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WidgetTree()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid credentials')));
    }
  }
}
