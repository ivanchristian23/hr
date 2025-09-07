import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:test_project/data/constants.dart';
import 'package:test_project/views/pages/register_page.dart';
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/lotties/Welcome_Onboard.json',height: 400.0),
                SizedBox(height: 20.0),
                Text('Proztec is one of the best workplace in Qatar wohoo!',style: KTextStyle.titleTealText,textAlign: TextAlign.justify,),
                 SizedBox(height: 20.0),
                FilledButton(
                  onPressed: () { 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return RegisterPage();
                        },
                      ),
                    );
                    
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: Size(double.infinity, 40.0),
                  ),
                  child: Text(title),
                ),
                SizedBox(height: 100.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
