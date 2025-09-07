import 'package:flutter/material.dart';

class ExpandedFlexiblePage extends StatelessWidget {
  const ExpandedFlexiblePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          // Expanded(child: Container(color: Colors.amber)),
          // Expanded(child: Container(color: Colors.teal), flex: 2), // for column need to add flex for much 
          // Row(                                                         space you want this container to have
          //   children: [
          //     Expanded(child: Container(color: Colors.amber,height: 20.0,)), for row you need to put heightt
          //     Expanded(child: Container(color: Colors.teal, height: 20.0,)),
          //   ],
          // )
           Row(                                                        
            children: [
              Expanded(child: Container(color: Colors.amber,height: 20.0,child: Text('data'),),),
              Flexible(child: Container(color: Colors.teal, height: 20.0, child: Text('data'),)), // Flexible will only take space based on the words provided
            ],
          )
          
        ],
      ),
    );
  }
}
