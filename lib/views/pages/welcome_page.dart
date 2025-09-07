import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
import 'package:test_project/views/pages/login_page.dart';
import 'package:test_project/views/pages/onboarding_page.dart';
import 'package:test_project/views/widgets/hero_widget.dart';
// import 'package:test_project/views/widget_tree.dart';
// import 'package:test_project/views/widgets/hero_widget.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeroWidget(title: 'Proztec'),
                // Lottie.asset('assets/lotties/Data_Management.json',height: 400.0),
                FittedBox(
                  child: Text(
                    'Proztec Employee Management System',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 50.0),
                  ),
                ),
                SizedBox(height: 20.0,),
                FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return OnboardingPage(title: 'Next',);
                        },
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 40.0)), //,backgroundColor: Colors.red[700]
                  child: Text('Get started'),
                ),
                 TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return LoginPage(title: 'Login',);
                        },
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 40.0)),
                  child: Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
