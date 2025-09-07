import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/classes/activity_class.dart';
import 'package:test_project/views/widgets/hero_widget.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
 late Activity activity;
  @override
  void initState() {
    getData();
    super.initState();
  }
  Future getData() async{
    var url =
      Uri.https('bored-api.appbrewery.com', '/random'); //, {'q': '{http}'} for query parameters

  var response = await http.get(url);
  if (response.statusCode == 200) {
     activity = Activity.fromJson(convert.jsonDecode(response.body) as Map<String, dynamic>);
     print(activity.activity);
  } else {
    throw Exception('Failed to load album');
  }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(),
    body: FutureBuilder(future: getData(), builder: (context, AsyncSnapshot snapshot) {
      return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            FittedBox(child: HeroWidget(title: 'Home',)),
          ],
        ),
      ),
    );
    },));
    }
  }
