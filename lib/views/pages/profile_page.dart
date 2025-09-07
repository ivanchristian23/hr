import 'package:flutter/material.dart';
import 'package:test_project/data/notifiers.dart';
import 'package:test_project/views/pages/welcome_page.dart';



class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(20.0),
      child: Column(children: [CircleAvatar(
        radius: 50.0,
        backgroundImage: AssetImage('assets/images/bg.jpg'),
      ),
        ListTile(
        title: Text('Logout'),
        onTap: () {
          selectedPageNotifier.value = 0; // Reset to the first page
          Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return WelcomePage();
                  },
                ),
              );
        },
      )]),
    );
  }
}
