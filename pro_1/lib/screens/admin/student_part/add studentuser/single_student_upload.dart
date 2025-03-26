import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SingleStudentForm extends StatefulWidget {
  @override
  _SingleStudentFormState createState() => _SingleStudentFormState();
}

class _SingleStudentFormState extends State<SingleStudentForm> {
  // Form keys and controllers for adding a student
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final admissionNoController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  int _selectedSemester = 1;
  String _selectedBatch = 'A';
  bool _isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    admissionNoController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Student',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
              fontSize: 18,
            ),
          ),
          SizedBox(height: 16),
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
            controller: admissionNoController,
            decoration: InputDecoration(
              labelText: 'Admission No.',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter admission number';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email ID (Optional)',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
              helperText: 'If not provided, will be generated automatically',
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number (Optional)',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester',
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      value: _selectedSemester,
                      items: List.generate(8, (index) => 
                        DropdownMenuItem(
                          value: index + 1,
                          child: Text('Semester ${index + 1}', style: GoogleFonts.raleway()),
                        )
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedSemester = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a semester';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch',
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      value: _selectedBatch,
                      items: ['A', 'B', 'C', 'D'].map((batch) => 
                        DropdownMenuItem(
                          value: batch,
                          child: Text('Batch $batch', style: GoogleFonts.raleway()),
                        )
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBatch = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a batch';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: _isSubmitting 
                ? Text('Processing...')
                : Text('Add Student & Generate Credentials'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.raleway(
                  fontWeight: FontWeight.w600,
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: _isSubmitting 
                ? null
                : _createStudentAccount,
            ),
          ),
        ],
      ),
    );
  }

  // Generate credentials just like in bulk upload
  Map<String, String> _generateCredentials(String admissionNo, String name) {
    String username = '$admissionNo@gmail.com';
    String password = name.toLowerCase().replaceAll(' ', '') + '123'; // name+123 as password similar to bulk upload

    return {
      'username': username,
      'password': password,
    };
  }

  // Method to create student account
  Future<void> _createStudentAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String name = nameController.text.trim();
      final String admissionNo = admissionNoController.text.trim();
      
      // Generate credentials (username/password)
      final credentials = _generateCredentials(admissionNo, name);
      final String username = credentials['username']!;
      final String password = credentials['password']!;
      
      // Use provided email or default to generated username
      final String email = emailController.text.isNotEmpty 
          ? emailController.text.trim() 
          : username;
          
      final String? phone = phoneController.text.isNotEmpty 
          ? phoneController.text.trim() 
          : null;

      // Create student data structure
      final studentData = {
        'name': name,
        'admissionNo': admissionNo,
        'email': email,
        'phone': phone,
        'semester': _selectedSemester,
        'batch': _selectedBatch,
        'username': username,
        'password': password, // This will be used for initial login
      };

      // Upload to Firebase
      await _uploadToFirebase(studentData);

      setState(() {
        _isSubmitting = false;
      });

      // Show success dialog
      _showSuccessMessage(username, password);
      
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating student account: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload student data to Firebase
  Future<void> _uploadToFirebase(Map<String, dynamic> studentData) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;

      // Extract data
      String generatedPassword = studentData['password'];
      String email = studentData['email'];
      String admissionNo = studentData['admissionNo'];

      // Step 1: Create user in Firebase Authentication
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: generatedPassword,
      );
      
      String uid = userCredential.user!.uid;
      print("User created in Firebase Auth: $uid");

      // Step 2: Store student details in classes collection with admissionNo as document ID
      await firestore
        .collection('classes')
        .doc('Sem${studentData['semester']}')
        .collection('students')
        .doc(admissionNo) // Using admissionNo as document ID
        .set({
          'name': studentData['name'],
          'admissionNo': admissionNo,
          'semester': studentData['semester'],
          'batch': 'Batch ${studentData['batch']}', // Format as "Batch A", "Batch B", etc.
          'username': studentData['username'],
          'email': email,
          'phone': studentData['phone'],
          'authUID': uid, // Reference to Auth UID
        });

      print("Added student to classes: ${studentData['name']} - $admissionNo");

      // Step 3: Store user in users collection with AUTH UID as document ID
      await firestore
          .collection('users')
          .doc(uid) // Using Firebase Auth UID as document ID
          .set({
            'name': studentData['name'],
            'admissionNo': admissionNo,
            'email': email,
            'role': 'student',
            'semester': studentData['semester'],
            'batch': studentData['batch'],
            'createdAt': FieldValue.serverTimestamp(),
          });

      print("Added student to users with Firebase Auth UID: $uid");
    } catch (e) {
      print('Error in Firebase upload process: $e');
      throw e;
    }
  }
  
  // Method to show success message after adding a student
  void _showSuccessMessage(String username, String password) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Student Added Successfully',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student has been added to Semester $_selectedSemester, Batch $_selectedBatch successfully.',
                style: GoogleFonts.raleway(),
              ),
              SizedBox(height: 16),
              Text(
                'Login credentials have been generated:',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Username: $username',
                      style: GoogleFonts.raleway(),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Password: $password',
                      style: GoogleFonts.raleway(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear form fields
                nameController.clear();
                admissionNoController.clear();
                emailController.clear();
                phoneController.clear();
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



















// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class SingleStudentForm extends StatefulWidget {
//   @override
//   _SingleStudentFormState createState() => _SingleStudentFormState();
// }

// class _SingleStudentFormState extends State<SingleStudentForm> {
//   // Sample data for departments
//   final List<String> departments = [
//     'Computer Science',
//     'Electrical Engineering',
//     'Mechanical Engineering',
//     'Civil Engineering',
//     'Chemical Engineering',
//   ];
  
//   // Sample data for years
//   final List<String> years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  
//   // Form keys and controllers for adding a student
//   final _formKey = GlobalKey<FormState>();
//   final nameController = TextEditingController();
//   final idController = TextEditingController();
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   String? selectedDepartment;
//   String? selectedYear;
//   String? selectedSection;
//   final usernameController = TextEditingController();
//   final passwordController = TextEditingController();
//   bool autoGenerateCredentials = true;

//   @override
//   void dispose() {
//     nameController.dispose();
//     idController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//     usernameController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _buildSingleStudentForm();
//   }
  
//   // Form for adding a single student
//   Widget _buildSingleStudentForm() {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           TextFormField(
//             controller: nameController,
//             decoration: InputDecoration(
//               labelText: 'Full Name',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter student name';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           TextFormField(
//             controller: idController,
//             decoration: InputDecoration(
//               labelText: 'Admission No',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter student ID';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           TextFormField(
//             controller: emailController,
//             decoration: InputDecoration(
//               labelText: 'Email ID',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter email';
//               }
//               if (!value.contains('@')) {
//                 return 'Please enter a valid email';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           TextFormField(
//             controller: phoneController,
//             decoration: InputDecoration(
//               labelText: 'Phone Number',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             keyboardType: TextInputType.phone,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter phone number';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           DropdownButtonFormField<String>(
//             decoration: InputDecoration(
//               labelText: 'Department',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             value: selectedDepartment,
//             items: departments.map((String department) {
//               return DropdownMenuItem<String>(
//                 value: department,
//                 child: Text(department),
//               );
//             }).toList(),
//             onChanged: (String? newValue) {
//               setState(() {
//                 selectedDepartment = newValue;
//               });
//             },
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please select a department';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           DropdownButtonFormField<String>(
//             decoration: InputDecoration(
//               labelText: 'Batch / Year',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             value: selectedYear,
//             items: years.map((String year) {
//               return DropdownMenuItem<String>(
//                 value: year,
//                 child: Text(year),
//               );
//             }).toList(),
//             onChanged: (String? newValue) {
//               setState(() {
//                 selectedYear = newValue;
//               });
//             },
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please select a year';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           DropdownButtonFormField<String>(
//             decoration: InputDecoration(
//               labelText: 'Section / Class (Optional)',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             value: selectedSection,
//             items: ['A', 'B', 'C', 'D'].map((String section) {
//               return DropdownMenuItem<String>(
//                 value: section,
//                 child: Text('Section $section'),
//               );
//             }).toList(),
//             onChanged: (String? newValue) {
//               setState(() {
//                 selectedSection = newValue;
//               });
//             },
//           ),
//           SizedBox(height: 16),
//           SwitchListTile(
//             title: Text(
//               'Auto-generate Credentials',
//               style: GoogleFonts.raleway(),
//             ),
//             value: autoGenerateCredentials,
//             activeColor: Color(0xFF1B5E20),
//             onChanged: (bool value) {
//               setState(() {
//                 autoGenerateCredentials = value;
//               });
//             },
//           ),
//           if (!autoGenerateCredentials) ...[
//             SizedBox(height: 16),
//             TextFormField(
//               controller: usernameController,
//               decoration: InputDecoration(
//                 labelText: 'Username',
//                 border: OutlineInputBorder(),
//                 labelStyle: GoogleFonts.raleway(),
//               ),
//               validator: (value) {
//                 if (!autoGenerateCredentials && (value == null || value.isEmpty)) {
//                   return 'Please enter username';
//                 }
//                 return null;
//               },
//             ),
//             SizedBox(height: 16),
//             TextFormField(
//               controller: passwordController,
//               decoration: InputDecoration(
//                 labelText: 'Password',
//                 border: OutlineInputBorder(),
//                 labelStyle: GoogleFonts.raleway(),
//               ),
//               obscureText: true,
//               validator: (value) {
//                 if (!autoGenerateCredentials && (value == null || value.isEmpty)) {
//                   return 'Please enter password';
//                 }
//                 return null;
//               },
//             ),
//           ],
//           SizedBox(height: 24),
//           Center(
//             child: ElevatedButton.icon(
//               icon: Icon(Icons.save),
//               label: Text('Save & Send Credentials'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF1B5E20),
//                 foregroundColor: Colors.white,
//                 textStyle: GoogleFonts.raleway(
//                   fontWeight: FontWeight.w600,
//                 ),
//                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//               ),
//               onPressed: () {
//                 if (_formKey.currentState!.validate()) {
//                   // Add your logic to save the student
//                   _showSuccessMessage();
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   // Method to show success message after adding a student
//   void _showSuccessMessage() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Success',
//             style: GoogleFonts.raleway(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1B5E20),
//             ),
//           ),
//           content: Text(
//             'Student added successfully. Credentials have been sent to their email.',
//             style: GoogleFonts.raleway(),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 // Clear form fields
//                 nameController.clear();
//                 idController.clear();
//                 emailController.clear();
//                 phoneController.clear();
//                 setState(() {
//                   selectedDepartment = null;
//                   selectedYear = null;
//                   selectedSection = null;
//                 });
//                 usernameController.clear();
//                 passwordController.clear();
//               },
//               child: Text(
//                 'OK',
//                 style: TextStyle(color: Color(0xFF1B5E20)),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }