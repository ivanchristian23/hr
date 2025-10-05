import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/views/pages/verify_otp_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  Future<void> sendOTP() async {
    final res = await http.post(
      Uri.parse('http://10.0.2.2:3000/password/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailController.text}) ,
    );

    if (res.statusCode == 200) {
       Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    print(emailController.text);
                    return VerifyOtpPage(email: emailController.text,);
                  },
                ),
              );
    } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(
          res.statusCode == 404
              ? "Email not found. Please check and try again."
              : "Server error. Please try again later.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forgot Password")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            ElevatedButton(onPressed: () {
              sendOTP();
            }, child: Text("Send OTP")),
          ],
        ),
      ),
    );
  }
}
