import 'package:flutter/material.dart';
import 'package:test_project/data/constants.dart';

class ContainerWidget extends StatelessWidget {
  const ContainerWidget({super.key, required this.title, required this.description});

  final String title;
  final String description;
  @override
  Widget build(BuildContext context) {
    return Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 2.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(title,style: KTextStyle.titleTealText), Text(description,style: KTextStyle.descText,)],
                  ),
                ),
              ),
            );
  }
}