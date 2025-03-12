import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

class AddTeacherPage extends StatefulWidget {
  @override
  _AddTeacherPageState createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  // Sample data for departments and positions
  final List<String> departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
  ];
  
  final List<String> positions = [
    'Assistant Professor',
    'Associate Professor',
    'Professor',
    'Head of Department',
    'Adjunct Faculty'
  ];
  
  // Form keys and controllers for adding a teacher
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final specializationController = TextEditingController();
  final researchInterestsController = TextEditingController();
  
  String? selectedDepartment;
  String? selectedPosition;
  
  // Current selected tab for Add Teachers section
  int _currentAddTeacherTab = 0;

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    emailController.dispose();
    phoneController.dispose();
    specializationController.dispose();
    researchInterestsController.dispose();
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
                  child: _buildAddTeacherTabButton(0, 'Single Teacher'),
                ),
                Expanded(
                  child: _buildAddTeacherTabButton(1, 'Bulk Upload'),
                ),
              ],
            ),
          ),
          
          // Content based on selected tab
          _currentAddTeacherTab == 0
              ? _buildSingleTeacherForm()
              : _buildBulkUploadForm(),
        ],
      ),
    );
  }
  
  // Add Teacher Tab Button
  Widget _buildAddTeacherTabButton(int index, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentAddTeacherTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _currentAddTeacherTab == index
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
            color: _currentAddTeacherTab == index ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
  
  // Form for adding a single teacher
  Widget _buildSingleTeacherForm() {
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
                return 'Please enter teacher name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: idController,
            decoration: InputDecoration(
              labelText: 'Teacher ID',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter teacher ID';
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
              labelText: 'Position',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
            value: selectedPosition,
            items: positions.map((String position) {
              return DropdownMenuItem<String>(
                value: position,
                child: Text(position),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedPosition = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a position';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: specializationController,
            decoration: InputDecoration(
              labelText: 'Specialization',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: researchInterestsController,
            decoration: InputDecoration(
              labelText: 'Research Interests (comma-separated)',
              border: OutlineInputBorder(),
              labelStyle: GoogleFonts.raleway(),
            ),
          ),
          SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Save Teacher'),
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
                  // Add your logic to save the teacher
                  _showSuccessMessage();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Form for bulk uploading teachers
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
                  'Upload your filled CSV/Excel file with teacher data.',
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
                  '• Checks if departments exist\n• Verifies required fields\n• Identifies duplicate IDs',
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

  // Method to show success message after adding a teacher
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
            'Teacher added successfully.',
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
                specializationController.clear();
                researchInterestsController.clear();
                setState(() {
                  selectedDepartment = null;
                  selectedPosition = null;
                });
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
            'Teachers data validated and processed successfully. 10 new teachers were added.',
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