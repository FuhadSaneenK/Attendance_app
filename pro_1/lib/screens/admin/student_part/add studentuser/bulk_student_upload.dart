import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class BulkUploadForm extends StatefulWidget {
  @override
  _BulkUploadFormState createState() => _BulkUploadFormState();
}

class _BulkUploadFormState extends State<BulkUploadForm> {
  // Variables for bulk upload
  File? _selectedFile;
  bool _isUploading = false;
  int _selectedSemester = 1;
  String _selectedBatch = 'A';

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
                  'Please note that only CSV or PDF files can be uploaded. Ensure your file contains all required student data fields.',
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
                  'Upload your CSV or PDF file containing student data for the selected batch.',
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
                if (_selectedFile != null) // Show file name when selected
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Selected file: ${_selectedFile!.path.split('/').last}',
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
                  'Step 3: Confirm & Upload',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Once a file is selected and confirmed, it will be processed and uploaded to the system.',
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.cloud_upload),
                    label: _isUploading 
                        ? Text('Uploading...')
                        : Text('Upload Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.raleway(
                        fontWeight: FontWeight.w600,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: _selectedFile != null && !_isUploading
                        ? _uploadStudents
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
      allowedExtensions: ['csv', 'pdf'],
      // Make sure to enable this for web
      withData: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      // For web platform
      if (kIsWeb) {
        if (result.files.single.bytes != null) {
          // Here you would handle the bytes directly
          // You might need to store this differently than a File object
          // For example, you might want to create a class that can handle both cases
          
          // Just for the snackbar notification
          setState(() {
            // You'll need a different approach to store the file data
            // This is just a placeholder for the UI update
            _selectedFile = File("dummy_path"); // Just for UI state
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
  // Method to upload students from the selected file
  Future<void> _uploadStudents() async {
    if (_selectedFile == null) return;
    
    try {
      // Show loading indicator
      setState(() {
        _isUploading = true;
      });
      
      // In a real app, you would create form data and make an API call
      // This is a placeholder for demonstration
      await Future.delayed(Duration(seconds: 2)); // Simulate network delay
      
      // Hide loading indicator
      setState(() {
        _isUploading = false;
        _selectedFile = null; // Clear the selected file
      });
      
      // Show success dialog
      _showUploadSuccessMessage();
      
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isUploading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading students: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to show success message after bulk upload
  void _showUploadSuccessMessage() {
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
          content: Text(
            'Students from Semester $_selectedSemester, Batch $_selectedBatch have been uploaded successfully.',
            style: GoogleFonts.raleway(),
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
}