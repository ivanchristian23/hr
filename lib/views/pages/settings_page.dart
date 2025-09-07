import 'package:flutter/material.dart';
import 'package:test_project/views/ref%20pages/expanded_flexible_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController controller = TextEditingController();
  bool? isChecked = false;
  bool isSwitched = false;
  double sliderValue = 0.0;
  String? menuItem = 'e1';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              ElevatedButton(onPressed: () {
                Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ExpandedFlexiblePage();
                        },
                      ),
                    );
              }, child: Text('Show Flexible and Expanded')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Snackbar'),duration: Duration(seconds: 5),behavior: SnackBarBehavior.floating,));
                },
                child: Text('Open Snackbar'),
              ),
              Divider(
                color: Colors.white,
                thickness: 5.0,
                endIndent: 200.0,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  showDialog(context: context, builder: (context) {
                   return AlertDialog(
                    content: Text('Alert Content'),
                    title: Text('Alert Content'),
                    actions: [
                      FilledButton(onPressed: () {
                        Navigator.pop(context); // Close the dialog
                      }, child: Text('Close'))
                    ],
                   ); 
                  },);
                },
                child: Text('Open Dialog'),
              ),
              DropdownButton(
                value: menuItem,
                items: [
                  DropdownMenuItem(value: 'e1', child: Text('Element 1')),
                  DropdownMenuItem(value: 'e2', child: Text('Element 2')),
                  DropdownMenuItem(value: 'e3', child: Text('Element 3')),
                ],
                onChanged: (String? value) {
                  setState(() {
                    menuItem = value; // Update the selected menu item
                  });
                },
              ),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: () {
                  setState(() {});
                },
              ),
              Text(controller.text),
              Checkbox(
                tristate: true,
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked = value; // Update the checkbox state
                  });
                },
              ),
              CheckboxListTile(
                tristate: true,
                title: Text('data'),
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked = value; // Update the checkbox state
                  });
                },
              ),
              Switch(
                value: isSwitched,
                onChanged: (bool value) {
                  setState(() {
                    isSwitched = value; // Update the switch state
                  });
                },
              ),
              SwitchListTile(
                title: Text('data'),
                value: isSwitched,
                onChanged: (bool value) {
                  setState(() {
                    isSwitched = value; // Update the switch state
                  });
                },
              ),
              Slider(
                max: 10.0,
                divisions: 10,
                value: sliderValue,
                onChanged: (double value) {
                  setState(() {
                    sliderValue = value; // Update the slider value
                  });
                  print(value);
                },
              ),
              InkWell(
                splashColor: Colors.black,
                onTap: () {
                  print('Image tapped!');
                },
                child: Container(
                  height: 50,
                  width: double.infinity,
                  color: Colors.white24,
                ),
              ),

              FilledButton(onPressed: () {}, child: Text('Click me')),
              TextButton(onPressed: () {}, child: Text('Click me')),
              OutlinedButton(onPressed: () {}, child: Text('Click me')),
              CloseButton(),
              BackButton(),
            ],
          ),
        ),
      ),
    );
  }
}
