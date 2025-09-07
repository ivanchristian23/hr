import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateLineManagerPage extends StatefulWidget {
  const CreateLineManagerPage({super.key});

  @override
  _CreateLineManagerPageState createState() => _CreateLineManagerPageState();
}

class _CreateLineManagerPageState extends State<CreateLineManagerPage> {
  final _formKey = GlobalKey<FormState>();
  int? selectedManagerId;
  String name = '';
  String department = '';
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse("http://10.0.2.2:3000/users")); // Replace with your server IP
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load users")),
      );
    }
  }

  Future<void> createLineManager() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final response = await http.post(
      Uri.parse("http://10.0.2.2:3000/line-managers"), // Replace with your server IP
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "manager_id": selectedManagerId,
        "name": name,
        "department": department,
      }),
    );

    final data = json.decode(response.body);
    if (data["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Line Manager created successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${data["error"] ?? "Unknown error"}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Line Manager")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: "Select Manager"),
                value: selectedManagerId,
                items: users.map<DropdownMenuItem<int>>((user) {
                  return DropdownMenuItem<int>(
                    value: user["id"],
                    child: Text(user["name"]),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedManagerId = value;
                  });
                },
                validator: (value) =>
                    value == null ? "Please select a manager" : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Name"),
                onSaved: (val) => name = val!,
                validator: (val) => val!.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Department"),
                onSaved: (val) => department = val!,
                validator: (val) => val!.isEmpty ? "Enter department" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: createLineManager,
                child: Text("Create"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
