import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

class AddStudentPage extends StatefulWidget {
  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
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
  
  // Current selected tab for Add Students section
  int _currentAddStudentTab = 0;

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
              ? _buildSingleStudentForm()
              : _buildBulkUploadForm(),
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
                  'Step 1: Download Template',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Download our pre-formatted Excel template with required fields.',
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.download),
                  label: Text('Download Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.raleway(),
                  ),
                  onPressed: _downloadTemplate,
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
                  'Upload your filled CSV/Excel file with student data.',
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
                  'Step 3: Data Validation',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'The system will automatically validate your data.',
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 8),
                Text(
                  '• Checks if departments and batches exist\n• Verifies required fields\n• Identifies duplicate IDs',
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
                  'Step 4: Confirm & Add',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Review and confirm the entries before adding them.',
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.check_circle),
                    label: Text('Upload & Validate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.raleway(
                        fontWeight: FontWeight.w600,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () {
                      // This would typically be enabled after a file is selected
                      _showUploadSuccessMessage();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Method to download the template
  void _downloadTemplate() async {
    // This would create an Excel file template in a real app
    final snackBar = SnackBar(
      content: Text('Template downloaded successfully'),
      backgroundColor: Color(0xFF1B5E20),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Method to pick a file for bulk upload
  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );

    if (result != null) {
      // In a real app, you would process the file here
      final snackBar = SnackBar(
        content: Text('File selected: ${result.files.single.name}'),
        backgroundColor: Color(0xFF1B5E20),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
            'Students data validated and processed successfully. 15 new students were added.',
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