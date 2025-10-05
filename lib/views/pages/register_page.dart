import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/views/pages/login_page.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController controllerFirstName = TextEditingController();
  final TextEditingController controllerLastName = TextEditingController();
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();
  final TextEditingController controllerJobTitle = TextEditingController();

  DateTime? _dateOfJoin;
  String? _selectedManager;
  String? _selectedUserType;

  final List<String> _userTypes = [
    "Head office Employee",
    "External Employee"
  ];

  
  List<Map<String, dynamic>> _lineManagers = [];

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> fetchLineManagers() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/line_managers'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        print(data);
        _lineManagers = List<Map<String, dynamic>>.from(data['line_managers']);
      });
    }
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfJoin == null || _selectedManager == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': controllerFirstName.text,
        'last_name': controllerLastName.text,
        'email': controllerEmail.text,
        'password': controllerPassword.text,
        'job_title': controllerJobTitle.text,
        'date_of_join': _dateOfJoin!.toIso8601String(),
        'line_manager_id': _selectedManager,
        'user_type': _selectedUserType,
      }),
    );

    setState(() {
      isLoading = false;
    });

    final result = jsonDecode(response.body);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(title: 'Login')),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLineManagers();
  }

  @override
  void dispose() {
    controllerFirstName.dispose();
    controllerLastName.dispose();
    controllerEmail.dispose();
    controllerPassword.dispose();
    controllerJobTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: controllerFirstName,
                decoration: InputDecoration(labelText: "First Name"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter first name'
                    : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: controllerLastName,
                decoration: InputDecoration(labelText: "Last Name"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter last name'
                    : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: controllerEmail,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: controllerPassword,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Minimum 6 characters'
                    : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: controllerJobTitle,
                decoration: InputDecoration(labelText: "Job Title"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter job title'
                    : null,
              ),
              SizedBox(height: 15),
              // Date Picker for Date of Join
              ListTile(
                title: Text("Date of Join"),
                subtitle: Text(_dateOfJoin == null
                    ? 'Select date'
                    : _dateOfJoin!.toLocal().toString().split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _dateOfJoin ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _dateOfJoin = selectedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 15),
              // Dropdown for Line Manager
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Line Manager"),
                value: _selectedManager,
                items: _lineManagers.map((manager) {
                  return DropdownMenuItem<String>(
                    value: manager['manager_id'].toString(),
                    child: Text(manager['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedManager = value;
                  });
                },
                validator: (value) => value == null ? 'Select a manager' : null,
              ),
              SizedBox(height: 30),SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "User Type"),
                value: _selectedUserType,
                items: _userTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value;
                  });
                },
                validator: (value) => value == null ? 'Select user type' : null,
              ),SizedBox(height: 60),

              isLoading
                  ? CircularProgressIndicator()
                  : FilledButton(
                      onPressed: registerUser,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
