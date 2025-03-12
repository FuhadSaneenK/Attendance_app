import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SingleStudentForm extends StatefulWidget {
  @override
  _SingleStudentFormState createState() => _SingleStudentFormState();
}

class _SingleStudentFormState extends State<SingleStudentForm> {
  // Sample data for departments
  final List<String> departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
  ];
  
  // Sample data for years
  final List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  
  // Form keys and controllers for adding a student
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  String? selectedDepartment;
  String? selectedYear;
  String? selectedSection;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool autoGenerateCredentials = true;

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    emailController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleStudentForm();
  }
  
  // Form for adding a single student
  Widget _buildSingleStudentForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter student name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: idController,
            decoration: InputDecoration(
              labelText: 'Student ID / Roll Number',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter student ID';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email ID',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            value: selectedDepartment,
            items: departments.map((String department) {
              return DropdownMenuItem<String>(
                value: department,
                child: Text(department),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedDepartment = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a department';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Batch / Year',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            value: selectedYear,
            items: years.map((String year) {
              return DropdownMenuItem<String>(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedYear = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a year';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Section / Class (Optional)',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            value: selectedSection,
            items: ['A', 'B', 'C', 'D'].map((String section) {
              return DropdownMenuItem<String>(
                value: section,
                child: Text('Section $section'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedSection = newValue;
              });
            },
          ),
          SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Auto-generate Credentials',
              style: GoogleFonts.raleway(),
            ),
            value: autoGenerateCredentials,
            activeColor: Color(0xFF1B5E20),
            onChanged: (bool value) {
              setState(() {
                autoGenerateCredentials = value;
              });
            },
          ),
          if (!autoGenerateCredentials) ...[
            SizedBox(height: 16),
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                labelStyle: GoogleFonts.raleway(),
              ),
              validator: (value) {
                if (!autoGenerateCredentials && (value == null || value.isEmpty)) {
                  return 'Please enter username';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                labelStyle: GoogleFonts.raleway(),
              ),
              obscureText: true,
              validator: (value) {
                if (!autoGenerateCredentials && (value == null || value.isEmpty)) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
          ],
          SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Save & Send Credentials'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.raleway(
                  fontWeight: FontWeight.w600,
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Add your logic to save the student
                  _showSuccessMessage();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Method to show success message after adding a student
  void _showSuccessMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Success',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: Text(
            'Student added successfully. Credentials have been sent to their email.',
            style: GoogleFonts.raleway(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear form fields
                nameController.clear();
                idController.clear();
                emailController.clear();
                phoneController.clear();
                setState(() {
                  selectedDepartment = null;
                  selectedYear = null;
                  selectedSection = null;
                });
                usernameController.clear();
                passwordController.clear();
              },
              child: Text(
                'OK',
                style: TextStyle(color: Color(0xFF1B5E20)),
              ),
            ),
          ],
        );
      },
    );
  }
}