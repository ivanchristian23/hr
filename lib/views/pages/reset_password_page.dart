import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/views/pages/login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key,required this.email});
  final String email;
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  // late String email;

  // @override
  // void didChangeDependencies() {
  //   email = ModalRoute.of(context)!.settings.arguments as String;
  //   super.didChangeDependencies();
  // }

  Future<void> resetPassword() async {
    if (passwordController.text != confirmPasswordController.text) {
      print("Passwords don't match");
      return;
    }

    final res = await http.post(
      Uri.parse('https://coolbuffs.com/api/password/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.email, 'new_password': passwordController.text}),
    );

    if (res.statusCode == 200) {
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return LoginPage(title: 'Login',);
          },
        ),
        (route) => false, // Remove all previous routes
      );
    } else {
      print("Password reset failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: 'New Password')),
            TextField(controller: confirmPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'Confirm Password')),
            ElevatedButton(onPressed: resetPassword, child: Text("Change Password")),
          ],
        ),
      ),
    );
  }
}
