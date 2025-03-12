import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/screens/admin/student_part/add%20studentuser/bulk_student_upload.dart';
import 'package:pro_1/screens/admin/student_part/add%20studentuser/single_student_upload.dart';


class AddStudentPage extends StatefulWidget {
  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  // Current selected tab for Add Students section
  int _currentAddStudentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs for Single/Bulk upload
          Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildAddStudentTabButton(0, 'Single Student'),
                ),
                Expanded(
                  child: _buildAddStudentTabButton(1, 'Bulk Upload'),
                ),
              ],
            ),
          ),
          
          // Content based on selected tab
          _currentAddStudentTab == 0
              ? SingleStudentForm()
              : BulkUploadForm(),
        ],
      ),
    );
  }
  
  // Add Student Tab Button
  Widget _buildAddStudentTabButton(int index, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentAddStudentTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _currentAddStudentTab == index
              ? Color(0xFF1B5E20)
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: index == 0 ? Radius.circular(8) : Radius.zero,
            right: index == 1 ? Radius.circular(8) : Radius.zero,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.w600,
            color: _currentAddStudentTab == index ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}




















// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// // import 'package:dio/dio.dart';

// class AddStudentPage extends StatefulWidget {
//   @override
//   _AddStudentPageState createState() => _AddStudentPageState();
// }

// class _AddStudentPageState extends State<AddStudentPage> {
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
  
//   // Current selected tab for Add Students section
//   int _currentAddStudentTab = 0;
  
//   // Variables for bulk upload
//   File? _selectedFile;
//   bool _isUploading = false;
//   int _selectedSemester = 1;
//   String _selectedBatch = 'A';

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
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Tabs for Single/Bulk upload
//           Container(
//             margin: EdgeInsets.only(bottom: 16),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade200,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _buildAddStudentTabButton(0, 'Single Student'),
//                 ),
//                 Expanded(
//                   child: _buildAddStudentTabButton(1, 'Bulk Upload'),
//                 ),
//               ],
//             ),
//           ),
          
//           // Content based on selected tab
//           _currentAddStudentTab == 0
//               ? _buildSingleStudentForm()
//               : _buildBulkUploadForm(),
//         ],
//       ),
//     );
//   }
  
//   // Add Student Tab Button
//   Widget _buildAddStudentTabButton(int index, String label) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _currentAddStudentTab = index;
//         });
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           color: _currentAddStudentTab == index
//               ? Color(0xFF1B5E20)
//               : Colors.transparent,
//           borderRadius: BorderRadius.horizontal(
//             left: index == 0 ? Radius.circular(8) : Radius.zero,
//             right: index == 1 ? Radius.circular(8) : Radius.zero,
//           ),
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           label,
//           style: GoogleFonts.raleway(
//             fontWeight: FontWeight.w600,
//             color: _currentAddStudentTab == index ? Colors.white : Colors.grey,
//           ),
//         ),
//       ),
//     );
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
//               labelText: 'Student ID / Roll Number',
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
  
//   // Form for bulk uploading students - Updated as per requirements
//   Widget _buildBulkUploadForm() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Card(
//           elevation: 2,
//           margin: EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Instructions',
//                   style: GoogleFonts.raleway(
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1B5E20),
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Please note that only CSV or PDF files can be uploaded. Ensure your file contains all required student data fields.',
//                   style: GoogleFonts.raleway(),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Card(
//           elevation: 2,
//           margin: EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Step 1: Select Semester & Batch',
//                   style: GoogleFonts.raleway(
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1B5E20),
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Semester',
//                             style: GoogleFonts.raleway(
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           DropdownButtonFormField<int>(
//                             decoration: InputDecoration(
//                               border: OutlineInputBorder(),
//                               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                             ),
//                             value: _selectedSemester,
//                             items: List.generate(8, (index) => 
//                               DropdownMenuItem(
//                                 value: index + 1,
//                                 child: Text('Semester ${index + 1}', style: GoogleFonts.raleway()),
//                               )
//                             ),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedSemester = value!;
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Batch',
//                             style: GoogleFonts.raleway(
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           DropdownButtonFormField<String>(
//                             decoration: InputDecoration(
//                               border: OutlineInputBorder(),
//                               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                             ),
//                             value: _selectedBatch,
//                             items: ['A', 'B', 'C', 'D'].map((batch) => 
//                               DropdownMenuItem(
//                                 value: batch,
//                                 child: Text('Batch $batch', style: GoogleFonts.raleway()),
//                               )
//                             ).toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedBatch = value!;
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Card(
//           elevation: 2,
//           margin: EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Step 2: Upload File',
//                   style: GoogleFonts.raleway(
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1B5E20),
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Upload your CSV or PDF file containing student data for the selected batch.',
//                   style: GoogleFonts.raleway(),
//                 ),
//                 SizedBox(height: 12),
//                 Center(
//                   child: ElevatedButton.icon(
//                     icon: Icon(Icons.upload_file),
//                     label: Text('Select File'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF1B5E20),
//                       foregroundColor: Colors.white,
//                       textStyle: GoogleFonts.raleway(),
//                     ),
//                     onPressed: _pickFile,
//                   ),
//                 ),
//                 if (_selectedFile != null) // Show file name when selected
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8.0),
//                     child: Text(
//                       'Selected file: ${_selectedFile!.path.split('/').last}',
//                       style: GoogleFonts.raleway(
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//         Card(
//           elevation: 2,
//           margin: EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Step 3: Confirm & Upload',
//                   style: GoogleFonts.raleway(
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1B5E20),
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Once a file is selected and confirmed, it will be processed and uploaded to the system.',
//                   style: GoogleFonts.raleway(),
//                 ),
//                 SizedBox(height: 12),
//                 Center(
//                   child: ElevatedButton.icon(
//                     icon: Icon(Icons.cloud_upload),
//                     label: _isUploading 
//                         ? Text('Uploading...')
//                         : Text('Upload Students'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF1B5E20),
//                       foregroundColor: Colors.white,
//                       textStyle: GoogleFonts.raleway(
//                         fontWeight: FontWeight.w600,
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                     ),
//                     onPressed: _selectedFile != null && !_isUploading
//                         ? _uploadStudents
//                         : null, // Disable button if no file is selected or if uploading
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Method to pick and select a file
//   Future<void> _pickFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['csv', 'pdf'],
//       );
      
//       if (result != null) {
//         setState(() {
//           _selectedFile = File(result.files.single.path!);
//         });
        
//         // Show a snackbar with the selected filename
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('File selected: ${result.files.single.name}'),
//             backgroundColor: Color(0xFF1B5E20),
//           ),
//         );
//       }
//     } catch (e) {
//       // Handle any errors
//       print('Error picking file: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error selecting file. Please try again.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
  
//   // Method to upload students from the selected file
//   Future<void> _uploadStudents() async {
//     if (_selectedFile == null) return;
    
//     try {
//       // Show loading indicator
//       setState(() {
//         _isUploading = true;
//       });
      
//       // In a real app, you would create form data and make an API call
//       // This is a placeholder for demonstration
//       await Future.delayed(Duration(seconds: 2)); // Simulate network delay
      
//       // Hide loading indicator
//       setState(() {
//         _isUploading = false;
//         _selectedFile = null; // Clear the selected file
//       });
      
//       // Show success dialog
//       _showUploadSuccessMessage();
      
//     } catch (e) {
//       // Hide loading indicator
//       setState(() {
//         _isUploading = false;
//       });
      
//       // Show error message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error uploading students: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
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

//   // Method to show success message after bulk upload
//   void _showUploadSuccessMessage() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Upload Successful',
//             style: GoogleFonts.raleway(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1B5E20),
//             ),
//           ),
//           content: Text(
//             'Students from Semester $_selectedSemester, Batch $_selectedBatch have been uploaded successfully.',
//             style: GoogleFonts.raleway(),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
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