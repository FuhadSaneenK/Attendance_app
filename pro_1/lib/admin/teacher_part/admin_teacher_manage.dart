import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/admin/teacher_part/addteacher.dart';
import 'package:pro_1/admin/teacher_part/viewteacher.dart';


class TeacherManagementPage extends StatefulWidget {
  @override
  _TeacherManagementPageState createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  // Sample data for departments
  final List<String> departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
  ];
  
  // Sample data for teachers (would come from your database)
  final Map<String, List<Map<String, dynamic>>> teacherData = {
    'Computer Science': [
      {
        'id': 'CS001',
        'name': 'Dr. Sarah Johnson',
        'email': 'sarah.johnson@example.com',
        'phone': '1234567890',
        'position': 'Associate Professor',
        'specialization': 'Machine Learning',
        'researchInterests': ['AI', 'Deep Learning', 'Computer Vision']
      },
      {
        'id': 'CS002',
        'name': 'Prof. Michael Chen',
        'email': 'michael.chen@example.com',
        'phone': '9876543210',
        'position': 'Professor',
        'specialization': 'Network Security',
        'researchInterests': ['Cybersecurity', 'Cryptography']
      },
    ],
    'Electrical Engineering': [
      {
        'id': 'EE001',
        'name': 'Dr. Emma Rodriguez',
        'email': 'emma.rodriguez@example.com',
        'phone': '5556667777',
        'position': 'Assistant Professor',
        'specialization': 'Power Systems',
        'researchInterests': ['Renewable Energy', 'Smart Grids']
      },
    ],
  };
  
  // Track visibility of each section
  bool _isViewTeachersSectionVisible = false;
  bool _isAddTeachersSectionVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Teacher Management',
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
                // View Teachers Button
                _buildSectionButton(
                  title: 'View Teachers',
                  isExpanded: _isViewTeachersSectionVisible,
                  onPressed: () {
                    setState(() {
                      _isViewTeachersSectionVisible = !_isViewTeachersSectionVisible;
                      if (_isViewTeachersSectionVisible) {
                        _isAddTeachersSectionVisible = false;
                      }
                    });
                  },
                ),
                
                // View Teachers Section (visible only when clicked)
                if (_isViewTeachersSectionVisible) _buildViewTeachersSection(),
                
                SizedBox(height: 24),
                Divider(color: Color(0xFF1B5E20), thickness: 1),
                SizedBox(height: 24),
                
                // Add Teachers Button
                _buildSectionButton(
                  title: 'Add Teachers',
                  isExpanded: _isAddTeachersSectionVisible,
                  onPressed: () {
                    setState(() {
                      _isAddTeachersSectionVisible = !_isAddTeachersSectionVisible;
                      if (_isAddTeachersSectionVisible) {
                        _isViewTeachersSectionVisible = false;
                      }
                    });
                  },
                ),
                
                // Add Teachers Section (visible only when clicked)
                if (_isAddTeachersSectionVisible) AddTeacherPage(),
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
  
  // View Teachers Section
  Widget _buildViewTeachersSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse by Department',
            style: GoogleFonts.raleway(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1B5E20),
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final department = departments[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    department,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  children: [
                    ListTile(
                      title: Text(
                        'View Teachers',
                        style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherListPage(
                              department: department,
                              teachers: teacherData[department] ?? [],
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}