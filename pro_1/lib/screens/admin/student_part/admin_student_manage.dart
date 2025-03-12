import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/screens/admin/student_part/add%20studentuser/bulk_student_upload.dart';
import 'package:pro_1/screens/admin/student_part/add%20studentuser/single_student_upload.dart';


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
  
  // Sample data for years
  final List<String> years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];
  
  // Track visibility of each section
  bool _isViewStudentsSectionVisible = false;
  bool _isAddStudentsSectionVisible = false;
  
  // Track which add student tab is active
  int _selectedAddStudentTab = 0;

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
                if (_isViewStudentsSectionVisible) 
                  // Replace with StudentListPage when you have it
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Student List Would Appear Here',
                        style: GoogleFonts.raleway(),
                      ),
                    ),
                  ),
                
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
                
                // Add Students Section with tabs (visible only when clicked)
                if (_isAddStudentsSectionVisible) 
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildAddStudentTabs(),
                        SizedBox(height: 24),
                        // Show different content based on selected tab
                        _selectedAddStudentTab == 0
                            ? SingleStudentForm()
                            : BulkUploadForm(),
                      ],
                    ),
                  ),
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
  
  // Add student tabs (Single Upload / Bulk Upload)
  Widget _buildAddStudentTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF1B5E20).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildTabButton(
            icon: Icons.person_add,
            title: 'Single Student', 
            isSelected: _selectedAddStudentTab == 0,
            onPressed: () {
              setState(() {
                _selectedAddStudentTab = 0;
              });
            },
          ),
          Container(
            width: 1, 
            height: 40, 
            color: Color(0xFF1B5E20).withOpacity(0.3),
          ),
          _buildTabButton(
            icon: Icons.group_add,
            title: 'Bulk Upload', 
            isSelected: _selectedAddStudentTab == 1,
            onPressed: () {
              setState(() {
                _selectedAddStudentTab = 1;
              });
            },
          ),
        ],
      ),
    );
  }
  
  // Tab button widget
  Widget _buildTabButton({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            isSelected ? Color(0xFFE8F5E9) : Colors.transparent,
          ),
          foregroundColor: MaterialStateProperty.all(
            Color(0xFF1B5E20),
          ),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(vertical: 16),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.raleway(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:pro_1/screens/admin/student_part/addstudent.dart';
// import 'package:pro_1/screens/admin/student_part/viewstudent.dart';

// class StudentManagementPage extends StatefulWidget {
//   @override
//   _StudentManagementPageState createState() => _StudentManagementPageState();
// }

// class _StudentManagementPageState extends State<StudentManagementPage> {
//   // Sample data for departments
//   final List<String> departments = [
//     'Computer Science',
//     'Electrical Engineering',
//     'Mechanical Engineering',
//     'Civil Engineering',
//     'Chemical Engineering',
//   ];
  
//   // Track visibility of each section
//   bool _isViewStudentsSectionVisible = false;
//   bool _isAddStudentsSectionVisible = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Student Management',
//           style: GoogleFonts.playfairDisplay(
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1B5E20),
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               const Color.fromARGB(255, 223, 243, 225),
//               Colors.white,
//             ],
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // View Students Button
//                 _buildSectionButton(
//                   title: 'View Students',
//                   isExpanded: _isViewStudentsSectionVisible,
//                   onPressed: () {
//                     setState(() {
//                       _isViewStudentsSectionVisible = !_isViewStudentsSectionVisible;
//                       if (_isViewStudentsSectionVisible) {
//                         _isAddStudentsSectionVisible = false;
//                       }
//                     });
//                   },
//                 ),
                
//                 // View Students Section (visible only when clicked)
//                 if (_isViewStudentsSectionVisible) StudentListPage(departments: departments),
                
//                 SizedBox(height: 24),
//                 Divider(color: Color(0xFF1B5E20), thickness: 1),
//                 SizedBox(height: 24),
                
//                 // Add Students Button
//                 _buildSectionButton(
//                   title: 'Add Students',
//                   isExpanded: _isAddStudentsSectionVisible,
//                   onPressed: () {
//                     setState(() {
//                       _isAddStudentsSectionVisible = !_isAddStudentsSectionVisible;
//                       if (_isAddStudentsSectionVisible) {
//                         _isViewStudentsSectionVisible = false;
//                       }
//                     });
//                   },
//                 ),
                
//                 // Add Students Section (visible only when clicked)
//                 if (_isAddStudentsSectionVisible) AddStudentPage(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Section button widget
//   Widget _buildSectionButton({
//     required String title,
//     required bool isExpanded,
//     required VoidCallback onPressed,
//   }) {
//     return Container(
//       width: double.infinity,
//       margin: EdgeInsets.only(bottom: 16),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: isExpanded ? Color(0xFF1B5E20) : Colors.white,
//           foregroundColor: isExpanded ? Colors.white : Color(0xFF1B5E20),
//           elevation: 2,
//           padding: EdgeInsets.symmetric(vertical: 16),
//           textStyle: GoogleFonts.raleway(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(color: Color(0xFF1B5E20)),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(title),
//             SizedBox(width: 8),
//             Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }