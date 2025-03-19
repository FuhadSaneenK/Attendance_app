import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:csv/csv.dart'; // Add this import for CSV parsing
import 'dart:convert'; // For UTF8 handling
import 'dart:typed_data' show Uint8List;
import 'dart:math' show min;
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';


class BulkUploadForm extends StatefulWidget {
  @override
  _BulkUploadFormState createState() => _BulkUploadFormState();
}

class _BulkUploadFormState extends State<BulkUploadForm> {
  // Variables for bulk upload
  File? _selectedFile;
  Uint8List? _fileBytes; // For web platform
  bool _isUploading = false;
  int _selectedSemester = 1;
  String _selectedBatch = 'A';
  
  // List to store processed student data
  List<Map<String, dynamic>> _processedStudents = [];

  @override
  Widget build(BuildContext context) {
    return _buildBulkUploadForm();
  }
  
  // Form for bulk uploading students
  Widget _buildBulkUploadForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please upload a CSV file with the following columns: Admission No., Name, Email (optional), Phone (optional). Usernames and passwords will be generated automatically.',
                  style: GoogleFonts.raleway(),
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 1: Select Semester & Batch',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 2: Upload File',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Upload your CSV file containing student data for the selected batch.',
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.upload_file),
                    label: Text('Select File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.raleway(),
                    ),
                    onPressed: _pickFile,
                  ),
                ),
                if (_selectedFile != null || _fileBytes != null) // Show file name when selected
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Selected file: ${_selectedFile?.path.split('/').last ?? "students.csv"}',
                      style: GoogleFonts.raleway(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 3: Process & Upload',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'The system will process the CSV file, generate usernames (admissionNo@gmail.com) and passwords (student name in lowercase).',
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.cloud_upload),
                    label: _isUploading 
                        ? Text('Processing...')
                        : Text('Process & Upload Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.raleway(
                        fontWeight: FontWeight.w600,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: (_selectedFile != null || _fileBytes != null) && !_isUploading
                        ? _processAndUploadStudents
                        : null, // Disable button if no file is selected or if uploading
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Method to pick and select a file
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        // Make sure to enable this for web
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        // For web platform
        if (kIsWeb) {
          if (result.files.single.bytes != null) {
            setState(() {
              _fileBytes = result.files.single.bytes;
              _selectedFile = null; // Clear file path as we're using bytes
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File selected: ${result.files.single.name}'),
                backgroundColor: Color(0xFF1B5E20),
              ),
            );
          }
        } 
        // For other platforms that support file paths
        else if (result.files.single.path != null) {
          setState(() {
            _selectedFile = File(result.files.single.path!);
            _fileBytes = null; // Clear bytes as we're using file path
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: ${result.files.single.name}'),
              backgroundColor: Color(0xFF1B5E20),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to process CSV and generate credentials
  Future<List<Map<String, dynamic>>> _processCSV() async {
    List<Map<String, dynamic>> students = [];
    
    try {
      List<List<dynamic>> csvData;
      
      // Read CSV data from either file or bytes
      if (kIsWeb && _fileBytes != null) {
        String csvString = utf8.decode(_fileBytes!);
        // Remove BOM if present
        if (csvString.startsWith('\uFEFF')) {
          csvString = csvString.substring(1);
        }
        // Print for debugging
        print('CSV content (first 100 chars): ${csvString.substring(0, min(100, csvString.length))}');
        csvData = const CsvToListConverter().convert(csvString);
      } else if (_selectedFile != null) {
        String csvString = await _selectedFile!.readAsString();
        // Remove BOM if present
        if (csvString.startsWith('\uFEFF')) {
          csvString = csvString.substring(1);
        }
        // Print for debugging
        print('CSV content (first 100 chars): ${csvString.substring(0, min(100, csvString.length))}');
        csvData = const CsvToListConverter().convert(csvString);
      } else {
        throw Exception('No file selected');
      }
      
      // Print the parsed data for debugging
      print('CSV rows found: ${csvData.length}');
      if (csvData.isNotEmpty) {
        print('First row: ${csvData[0]}');
      }
      
      // Skip header row and process data
      if (csvData.length > 1) {
        // Get the headers (first row)
        List<String> headers = csvData[0].map((e) => e.toString()).toList();
        print('Headers found: $headers');
        
        // Find the indices of required columns with more flexible matching
        int admNoIndex = headers.indexWhere((h) => 
            h.toLowerCase().contains('admission') || 
            h.toLowerCase().contains('adm') || 
            h.toLowerCase().contains('no'));
            
        int nameIndex = headers.indexWhere((h) => 
            h.toLowerCase().contains('name') || 
            h.toLowerCase().contains('student'));
        
        print('Admission No. index: $admNoIndex, Name index: $nameIndex');
        
        if (admNoIndex == -1 || nameIndex == -1) {
          // If we couldn't find the columns by name, try using a fixed position approach
          // Assuming your CSV always has Admission No. in column 0 and Name in column 1
          admNoIndex = 0;
          nameIndex = 1;
          print('Using fixed column positions: Admission No. at $admNoIndex, Name at $nameIndex');
        }
        
        // Process each row (skip header)
        for (int i = 1; i < csvData.length; i++) {
          if (csvData[i].length >= max(admNoIndex, nameIndex) + 1) {
            // Extract data
            String admissionNo = csvData[i][admNoIndex].toString().trim();
            String name = csvData[i][nameIndex].toString().trim();
            
            // Skip if empty
            if (admissionNo.isEmpty || name.isEmpty) {
              continue;
            }
            
            // Generate credentials
            String username = '$admissionNo@gmail.com';
            String password = name.toLowerCase().replaceAll(' ', '') + '123'; //name+123 is password
            
            // Create student record
            Map<String, dynamic> student = {
              'admissionNo': admissionNo,
              'name': name,
              'username': username,
              'password': password,
              'semester': _selectedSemester,
              'batch': _selectedBatch,
            };
            
            students.add(student);
          }
        }
      }
      
      // If we still have no students, try an alternative parsing method
      if (students.isEmpty && csvData.length > 1) {
        print('Trying alternative parsing method...');
        
        // Direct approach
        for (int i = 1; i < csvData.length; i++) {
          if (csvData[i].length >= 2) {
            String admissionNo = csvData[i][0].toString().trim();
            String name = csvData[i][1].toString().trim();
            
            // Skip if empty
            if (admissionNo.isEmpty || name.isEmpty) {
              continue;
            }
            
            // Generate credentials
            String username = '$admissionNo@gmail.com';
            String password = name.toLowerCase().replaceAll(' ', '');
            
            // Create student record
            Map<String, dynamic> student = {
              'admissionNo': admissionNo,
              'name': name,
              'username': username,
              'password': password,
              'semester': _selectedSemester,
              'batch': _selectedBatch,
            };
            
            students.add(student);
          }
        }
      }
      
      print('Processed students: ${students.length}');
      return students;
    } catch (e) {
      print('Error processing CSV: $e');
      // Try one more approach if we get an error
      try {
        if (_selectedFile != null) {
          // Try with Latin-1 encoding which is more permissive
          List<int> bytes = await _selectedFile!.readAsBytes();
          String csvString = latin1.decode(bytes);
          List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
          
          if (csvData.length > 1) {
            for (int i = 1; i < csvData.length; i++) {
              if (csvData[i].length >= 2) {
                String admissionNo = csvData[i][0].toString().trim();
                String name = csvData[i][1].toString().trim();
                
                // Skip if empty
                if (admissionNo.isEmpty || name.isEmpty) {
                  continue;
                }
                
                // Generate credentials
                String username = '$admissionNo@gmail.com';
                String password = name.toLowerCase().replaceAll(' ', '');
                
                // Create student record
                Map<String, dynamic> student = {
                  'admissionNo': admissionNo,
                  'name': name,
                  'username': username,
                  'password': password,
                  'semester': _selectedSemester,
                  'batch': _selectedBatch,
                };
                
                students.add(student);
              }
            }
          }
          
          if (students.isNotEmpty) {
            return students;
          }
        }
      } catch (e2) {
        print('Error in fallback CSV processing: $e2');
      }
      
      rethrow;
    }
  }

  // Method to process and upload students
  Future<void> _processAndUploadStudents() async {
    if (_selectedFile == null && _fileBytes == null) return;
    
    try {
      // Show loading indicator
      setState(() {
        _isUploading = true;
      });
      
      // Process the CSV file
      _processedStudents = await _processCSV();
      
      if (_processedStudents.isEmpty) {
        throw Exception('No valid student records found in the CSV file');
      }
      
      // Here you would send the processed students to Firebase
      // This is a placeholder - you'll need to implement your Firebase logic
      await _uploadToFirebase(_processedStudents);
      
      // Hide loading indicator
      setState(() {
        _isUploading = false;
        _selectedFile = null;
        _fileBytes = null;
      });
      
      // Show success dialog
      _showUploadSuccessMessage(_processedStudents.length);
      
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isUploading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing students: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  

Future<void> _uploadToFirebase(List<Map<String, dynamic>> students) async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    for (var student in students) {
      String generatedPassword = student['password']; // Use dynamically generated password
      String email = student['username']; // Assuming username is the email

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
        .doc('Sem${student['semester']}')
        .collection('students')
        .doc(student['admissionNo']) // Using admissionNo as document ID
        .set({
          'name': student['name'],
          'admissionNo': student['admissionNo'],
          'semester': student['semester'],
          'batch': 'Batch ${student['batch']}', // Format as "Batch A", "Batch B", etc.
          'username': student['username'],
          'email': email,
          'authUID': uid, // Reference to Auth UID
        });

      print("Added student to classes: ${student['name']} - ${student['admissionNo']}");

      // Step 3: Store user in users collection with AUTH UID as document ID
      await firestore
          .collection('users')
          .doc(uid) // Using Firebase Auth UID as document ID
          .set({
            'name': student['name'],
            'admissionNo': student['admissionNo'],
            'email': email,
            'role': 'student',
            'semester': student['semester'],
            'batch': student['batch'],
            'createdAt': FieldValue.serverTimestamp(),
          });

      print("Added student to users with Firebase Auth UID: $uid");
    }

    print('Completed uploading ${students.length} students to Firebase');
  } catch (e) {
    print('Error in Firebase upload process: $e');
    throw e;
  }
}



  // Method to show success message after bulk upload
  void _showUploadSuccessMessage(int count) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Upload Successful',
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
                '$count students from Semester $_selectedSemester, Batch $_selectedBatch have been processed successfully.',
                style: GoogleFonts.raleway(),
              ),
              SizedBox(height: 16),
              Text(
                'Usernames and passwords have been generated:',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: 150,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _processedStudents.length > 5 ? 5 : _processedStudents.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${_processedStudents[index]['name']}',
                        style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Username: ${_processedStudents[index]['username']}\nPassword: ${_processedStudents[index]['password']}',
                        style: GoogleFonts.raleway(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              if (_processedStudents.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '... and ${_processedStudents.length - 5} more students',
                    style: GoogleFonts.raleway(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
  
  // Helper function for max
  int max(int a, int b) {
    return a > b ? a : b;
  }
}






//method 2
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:csv/csv.dart'; // Add this import for CSV parsing
// import 'dart:convert'; // For UTF8 handling
// import 'dart:typed_data' show Uint8List;

// class BulkUploadForm extends StatefulWidget {
//   @override
//   _BulkUploadFormState createState() => _BulkUploadFormState();
// }

// class _BulkUploadFormState extends State<BulkUploadForm> {
//   // Variables for bulk upload
//   File? _selectedFile;
//   Uint8List? _fileBytes; // For web platform
//   bool _isUploading = false;
//   int _selectedSemester = 1;
//   String _selectedBatch = 'A';
  
//   // List to store processed student data
//   List<Map<String, dynamic>> _processedStudents = [];

//   @override
//   Widget build(BuildContext context) {
//     return _buildBulkUploadForm();
//   }
  
//   // Form for bulk uploading students
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
//                   'Please upload a CSV file with the following columns: Admission No., Name, Email (optional), Phone (optional). Usernames and passwords will be generated automatically.',
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
//                   'Upload your CSV file containing student data for the selected batch.',
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
//                 if (_selectedFile != null || _fileBytes != null) // Show file name when selected
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8.0),
//                     child: Text(
//                       'Selected file: ${_selectedFile?.path.split('/').last ?? "students.csv"}',
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
//                   'Step 3: Process & Upload',
//                   style: GoogleFonts.raleway(
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1B5E20),
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'The system will process the CSV file, generate usernames (admissionNo@gmail.com) and passwords (student name in lowercase).',
//                   style: GoogleFonts.raleway(),
//                 ),
//                 SizedBox(height: 12),
//                 Center(
//                   child: ElevatedButton.icon(
//                     icon: Icon(Icons.cloud_upload),
//                     label: _isUploading 
//                         ? Text('Processing...')
//                         : Text('Process & Upload Students'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF1B5E20),
//                       foregroundColor: Colors.white,
//                       textStyle: GoogleFonts.raleway(
//                         fontWeight: FontWeight.w600,
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                     ),
//                     onPressed: (_selectedFile != null || _fileBytes != null) && !_isUploading
//                         ? _processAndUploadStudents
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
//         allowedExtensions: ['csv'],
//         // Make sure to enable this for web
//         withData: true,
//       );
      
//       if (result != null && result.files.isNotEmpty) {
//         // For web platform
//         if (kIsWeb) {
//           if (result.files.single.bytes != null) {
//             setState(() {
//               _fileBytes = result.files.single.bytes;
//               _selectedFile = null; // Clear file path as we're using bytes
//             });
            
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('File selected: ${result.files.single.name}'),
//                 backgroundColor: Color(0xFF1B5E20),
//               ),
//             );
//           }
//         } 
//         // For other platforms that support file paths
//         else if (result.files.single.path != null) {
//           setState(() {
//             _selectedFile = File(result.files.single.path!);
//             _fileBytes = null; // Clear bytes as we're using file path
//           });
          
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('File selected: ${result.files.single.name}'),
//               backgroundColor: Color(0xFF1B5E20),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       print('Error picking file: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error selecting file: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Method to process CSV and generate credentials
//   Future<List<Map<String, dynamic>>> _processCSV() async {
//     List<Map<String, dynamic>> students = [];
    
//     try {
//       List<List<dynamic>> csvData;
      
//       // Read CSV data from either file or bytes
//       if (kIsWeb && _fileBytes != null) {
//         String csvString = utf8.decode(_fileBytes!);
//         csvData = const CsvToListConverter().convert(csvString);
//       } else if (_selectedFile != null) {
//         String csvString = await _selectedFile!.readAsString();
//         csvData = const CsvToListConverter().convert(csvString);
//       } else {
//         throw Exception('No file selected');
//       }
      
//       // Skip header row and process data
//       if (csvData.length > 1) {
//         // Get the headers (first row)
//         List<String> headers = csvData[0].map((e) => e.toString()).toList();
        
//         // Find the indices of required columns
//         int admNoIndex = headers.indexWhere((h) => h.toLowerCase().contains('admission'));
//         int nameIndex = headers.indexWhere((h) => h.toLowerCase().contains('name'));
        
//         if (admNoIndex == -1 || nameIndex == -1) {
//           throw Exception('CSV missing required columns (Admission No. or Name)');
//         }
        
//         // Process each row (skip header)
//         for (int i = 1; i < csvData.length; i++) {
//           if (csvData[i].length >= headers.length) {
//             // Extract data
//             String admissionNo = csvData[i][admNoIndex].toString().trim();
//             String name = csvData[i][nameIndex].toString().trim();
            
//             // Generate credentials
//             String username = '$admissionNo@gmail.com';
//             String password = name.toLowerCase().replaceAll(' ', '');
            
//             // Create student record
//             Map<String, dynamic> student = {
//               'admissionNo': admissionNo,
//               'name': name,
//               'username': username,
//               'password': password,
//               'semester': _selectedSemester,
//               'batch': _selectedBatch,
//             };
            
//             students.add(student);
//           }
//         }
//       }
      
//       return students;
//     } catch (e) {
//       print('Error processing CSV: $e');
//       rethrow;
//     }
//   }

//   // Method to process and upload students
//   Future<void> _processAndUploadStudents() async {
//     if (_selectedFile == null && _fileBytes == null) return;
    
//     try {
//       // Show loading indicator
//       setState(() {
//         _isUploading = true;
//       });
      
//       // Process the CSV file
//       _processedStudents = await _processCSV();
      
//       if (_processedStudents.isEmpty) {
//         throw Exception('No valid student records found in the CSV file');
//       }
      
//       // Here you would send the processed students to Firebase
//       // This is a placeholder - you'll need to implement your Firebase logic
//       await _uploadToFirebase(_processedStudents);
      
//       // Hide loading indicator
//       setState(() {
//         _isUploading = false;
//         _selectedFile = null;
//         _fileBytes = null;
//       });
      
//       // Show success dialog
//       _showUploadSuccessMessage(_processedStudents.length);
      
//     } catch (e) {
//       // Hide loading indicator
//       setState(() {
//         _isUploading = false;
//       });
      
//       // Show error message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error processing students: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
  
//   // Method to upload processed student data to Firebase
//   Future<void> _uploadToFirebase(List<Map<String, dynamic>> students) async {
//     // This is where you would implement your Firebase upload logic
//     // For example:
    
//     // 1. Create user accounts with Firebase Authentication
//     // 2. Add students to Firestore in the classes collection
    
//     // For demonstration, we'll just simulate a network delay
//     await Future.delayed(Duration(seconds: 2));
    
//     // Return the method here - you'll replace this with actual Firebase code
//     return;
    
//     /* Example Firebase implementation (uncomment and modify as needed):
    
//     final FirebaseAuth auth = FirebaseAuth.instance;
//     final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
//     for (var student in students) {
//       try {
//         // 1. Create user in Firebase Auth (you might need admin SDK or Cloud Functions)
//         // This is just pseudocode - actual implementation depends on your backend
        
//         // 2. Add student to Firestore in the classes collection
//         await firestore
//           .collection('classes')
//           .doc('sem${student['semester']}')
//           .collection('batch${student['batch'].toLowerCase()}')
//           .doc(student['admissionNo'])
//           .set({
//             'name': student['name'],
//             'admissionNo': student['admissionNo'],
//             'username': student['username'],
//             // Don't store passwords in Firestore for security reasons
//             // Add any other student fields
//           });
//       } catch (e) {
//         print('Error adding student ${student['admissionNo']}: $e');
//       }
//     }
//     */
//   }

//   // Method to show success message after bulk upload
//   void _showUploadSuccessMessage(int count) {
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
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '$count students from Semester $_selectedSemester, Batch $_selectedBatch have been processed successfully.',
//                 style: GoogleFonts.raleway(),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Usernames and passwords have been generated:',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               Container(
//                 height: 150,
//                 width: double.maxFinite,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: _processedStudents.length > 5 ? 5 : _processedStudents.length,
//                   itemBuilder: (context, index) {
//                     return ListTile(
//                       dense: true,
//                       title: Text(
//                         '${_processedStudents[index]['name']}',
//                         style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
//                       ),
//                       subtitle: Text(
//                         'Username: ${_processedStudents[index]['username']}\nPassword: ${_processedStudents[index]['password']}',
//                         style: GoogleFonts.raleway(fontSize: 12),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               if (_processedStudents.length > 5)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8.0),
//                   child: Text(
//                     '... and ${_processedStudents.length - 5} more students',
//                     style: GoogleFonts.raleway(fontStyle: FontStyle.italic),
//                   ),
//                 ),
//             ],
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




// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;

// class BulkUploadForm extends StatefulWidget {
//   @override
//   _BulkUploadFormState createState() => _BulkUploadFormState();
// }

// class _BulkUploadFormState extends State<BulkUploadForm> {
//   // Variables for bulk upload
//   File? _selectedFile;
//   bool _isUploading = false;
//   int _selectedSemester = 1;
//   String _selectedBatch = 'A';

//   @override
//   Widget build(BuildContext context) {
//     return _buildBulkUploadForm();
//   }
  
//   // Form for bulk uploading students
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
// Future<void> _pickFile() async {
//   try {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['csv', 'pdf'],
//       // Make sure to enable this for web
//       withData: true,
//     );
    
//     if (result != null && result.files.isNotEmpty) {
//       // For web platform
//       if (kIsWeb) {
//         if (result.files.single.bytes != null) {
//           // Here you would handle the bytes directly
//           // You might need to store this differently than a File object
//           // For example, you might want to create a class that can handle both cases
          
//           // Just for the snackbar notification
//           setState(() {
//             // You'll need a different approach to store the file data
//             // This is just a placeholder for the UI update
//             _selectedFile = File("dummy_path"); // Just for UI state
//           });
          
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('File selected: ${result.files.single.name}'),
//               backgroundColor: Color(0xFF1B5E20),
//             ),
//           );
//         }
//       } 
//       // For other platforms that support file paths
//       else if (result.files.single.path != null) {
//         setState(() {
//           _selectedFile = File(result.files.single.path!);
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('File selected: ${result.files.single.name}'),
//             backgroundColor: Color(0xFF1B5E20),
//           ),
//         );
//       }
//     }
//   } catch (e) {
//     print('Error picking file: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Error selecting file: ${e.toString()}'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }
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