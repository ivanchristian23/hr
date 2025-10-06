import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/views/pages/reset_password_page.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key,required this.email});
  final String email;
  @override
  _VerifyOtpPageState createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  // @override
  // void initState() {
  //   print(widget.email);
  //   super.initState();
  // }
  final otpController = TextEditingController();
  // late String email;

  // @override
  // void didChangeDependencies() {
  //   email = ModalRoute.of(context)!.settings.arguments as String;
  //   super.didChangeDependencies();
  // }

  Future<void> verifyOtp() async {
    print(widget.email);
    final res = await http.post(
      Uri.parse('https://coolbuffs.com/api/password/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.email, 'otp': otpController.text}),
    );

    if (res.statusCode == 200) {
      Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ResetPasswordPage(email: widget.email,);
                  },
                ),
              );
    } else {
      // Handle error
      print(otpController.text);
      print("Invalid OTP");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: otpController, decoration: InputDecoration(labelText: 'Enter OTP')),
            ElevatedButton(onPressed: () {
              verifyOtp();
            }, child: Text("Verify")),
          ],
        ),
      ),
    );
  }
}
