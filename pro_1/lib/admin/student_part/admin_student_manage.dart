import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/admin/student_part/addstudent.dart';
import 'package:pro_1/admin/student_part/viewstudent.dart';

class StudentManagementPage extends StatefulWidget {
  @override
  _StudentManagementPageState createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  // Sample data for departments
  final List<String> departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
  ];
  
  // Track visibility of each section
  bool _isViewStudentsSectionVisible = false;
  bool _isAddStudentsSectionVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Management',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 223, 243, 225),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // View Students Button
                _buildSectionButton(
                  title: 'View Students',
                  isExpanded: _isViewStudentsSectionVisible,
                  onPressed: () {
                    setState(() {
                      _isViewStudentsSectionVisible = !_isViewStudentsSectionVisible;
                      if (_isViewStudentsSectionVisible) {
                        _isAddStudentsSectionVisible = false;
                      }
                    });
                  },
                ),
                
                // View Students Section (visible only when clicked)
                if (_isViewStudentsSectionVisible) StudentListPage(departments: departments),
                
                SizedBox(height: 24),
                Divider(color: Color(0xFF1B5E20), thickness: 1),
                SizedBox(height: 24),
                
                // Add Students Button
                _buildSectionButton(
                  title: 'Add Students',
                  isExpanded: _isAddStudentsSectionVisible,
                  onPressed: () {
                    setState(() {
                      _isAddStudentsSectionVisible = !_isAddStudentsSectionVisible;
                      if (_isAddStudentsSectionVisible) {
                        _isViewStudentsSectionVisible = false;
                      }
                    });
                  },
                ),
                
                // Add Students Section (visible only when clicked)
                if (_isAddStudentsSectionVisible) AddStudentPage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Section button widget
  Widget _buildSectionButton({
    required String title,
    required bool isExpanded,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isExpanded ? Color(0xFF1B5E20) : Colors.white,
          foregroundColor: isExpanded ? Colors.white : Color(0xFF1B5E20),
          elevation: 2,
          padding: EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.raleway(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Color(0xFF1B5E20)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            SizedBox(width: 8),
            Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }
}