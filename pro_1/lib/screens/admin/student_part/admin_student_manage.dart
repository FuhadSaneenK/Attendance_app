import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_1/screens/admin/student_part/add_timetable.dart';
import 'package:pro_1/screens/admin/student_part/add%20studentuser/bulk_student_upload.dart';
import 'package:pro_1/screens/admin/student_part/add%20studentuser/single_student_upload.dart';
import 'package:pro_1/screens/admin/student_part/semester_details.dart';
// Import the StudentListPage
import 'package:pro_1/screens/admin/student_part/view_students/viewstudent.dart';

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
  bool _isAddTimetableSectionVisible = false;
  bool _isAddSemesterDetailsSectionVisible = false;
  
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
                        _isAddTimetableSectionVisible = false;
                        _isAddSemesterDetailsSectionVisible = false;
                      }
                    });
                  },
                ),
                
                // View Students Section (visible only when clicked)
                if (_isViewStudentsSectionVisible) 
                  Container(
                    height: 500, // Set a fixed height for the student list view
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
                    // Use the StudentListPage here
                    child: StudentListPage(),
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
                        _isAddTimetableSectionVisible = false;
                        _isAddSemesterDetailsSectionVisible = false;
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

                SizedBox(height: 24),
                Divider(color: Color(0xFF1B5E20), thickness: 1),
                SizedBox(height: 24),
                

                //add timetable
                _buildSectionButton(
                  title: 'Add Timetable',
                  isExpanded: _isAddTimetableSectionVisible,
                  onPressed: () {
                    setState(() {
                      _isAddTimetableSectionVisible = !_isAddTimetableSectionVisible;
                      if (_isAddTimetableSectionVisible) {
                        _isViewStudentsSectionVisible = false;
                        _isAddStudentsSectionVisible = false;
                        _isAddSemesterDetailsSectionVisible = false;
                      }
                    });
                  },
                ),

                // Add Timetable Section (visible only when clicked)
                if (_isAddTimetableSectionVisible) 
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
                    child: TimetableForm(),
                  ),

                  SizedBox(height: 24),
                  Divider(color: Color(0xFF1B5E20), thickness: 1),
                  SizedBox(height: 24),


                // Add Semester Details Button
                _buildSectionButton(
                  title: 'Add Current Semester Details',
                  isExpanded: _isAddSemesterDetailsSectionVisible,
                  onPressed: () {
                    setState(() {
                      _isAddSemesterDetailsSectionVisible = !_isAddSemesterDetailsSectionVisible;
                      if (_isAddSemesterDetailsSectionVisible) {
                        _isViewStudentsSectionVisible = false;
                        _isAddStudentsSectionVisible = false;
                        _isAddTimetableSectionVisible = false;
                      }
                    });
                  },
                ),

                // Add Semester Details Section (visible only when clicked)
                if (_isAddSemesterDetailsSectionVisible) 
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
                    child: SemesterDetailsForm(),
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
// import 'package:pro_1/screens/admin/student_part/add_timetable.dart';
// import 'package:pro_1/screens/admin/student_part/add%20studentuser/bulk_student_upload.dart';
// import 'package:pro_1/screens/admin/student_part/add%20studentuser/single_student_upload.dart';
// import 'package:pro_1/screens/admin/student_part/semester_details.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// // Import StudentListPage
// // Note: This class should be placed in a separate file and imported properly
// // For the purpose of this integration, I'm including the partial StudentListPage code

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
  
//   // Sample data for years
//   final List<String> years = [
//     '1st Year',
//     '2nd Year',
//     '3rd Year',
//     '4th Year',
//   ];
  
//   // Track visibility of each section
//   bool _isViewStudentsSectionVisible = false;
//   bool _isAddStudentsSectionVisible = false;
//   bool _isAddTimetableSectionVisible = false;
//   bool _isAddSemesterDetailsSectionVisible = false;
  
//   // Track which add student tab is active
//   int _selectedAddStudentTab = 0;

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
//                         _isAddTimetableSectionVisible = false;
//                         _isAddSemesterDetailsSectionVisible = false;
//                       }
//                     });
//                   },
//                 ),
                
//                 // View Students Section (visible only when clicked)
//                 if (_isViewStudentsSectionVisible) 
//                   Container(
//                     height: 500, // Set a fixed height for the student list view
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     // Use the StudentListPage here
//                     child: StudentListPage(),
//                   ),
                
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
//                         _isAddTimetableSectionVisible = false;
//                         _isAddSemesterDetailsSectionVisible = false;
//                       }
//                     });
//                   },
//                 ),
                
//                 // Add Students Section with tabs (visible only when clicked)
//                 if (_isAddStudentsSectionVisible) 
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         _buildAddStudentTabs(),
//                         SizedBox(height: 24),
//                         // Show different content based on selected tab
//                         _selectedAddStudentTab == 0
//                             ? SingleStudentForm()
//                             : BulkUploadForm(),
//                       ],
//                     ),
//                   ),

//                 SizedBox(height: 24),
//                 Divider(color: Color(0xFF1B5E20), thickness: 1),
//                 SizedBox(height: 24),
                

//               //add timetable
//                 _buildSectionButton(
//                   title: 'Add Timetable',
//                   isExpanded: _isAddTimetableSectionVisible,
//                   onPressed: () {
//                     setState(() {
//                       _isAddTimetableSectionVisible = !_isAddTimetableSectionVisible;
//                       if (_isAddTimetableSectionVisible) {
//                         _isViewStudentsSectionVisible = false;
//                         _isAddStudentsSectionVisible = false;
//                         _isAddSemesterDetailsSectionVisible = false;
//                       }
//                     });
//                   },
//                 ),

//                 // Add Timetable Section (visible only when clicked)
//                 if (_isAddTimetableSectionVisible) 
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: TimetableForm(),
//                   ),

//                   SizedBox(height: 24),
//                   Divider(color: Color(0xFF1B5E20), thickness: 1),
//                   SizedBox(height: 24),


//               // Add Semester Details Button
//                 _buildSectionButton(
//                   title: 'Add Current  Semester Details',
//                   isExpanded: _isAddSemesterDetailsSectionVisible,
//                   onPressed: () {
//                     setState(() {
//                       _isAddSemesterDetailsSectionVisible = !_isAddSemesterDetailsSectionVisible;
//                       if (_isAddSemesterDetailsSectionVisible) {
//                         _isViewStudentsSectionVisible = false;
//                         _isAddStudentsSectionVisible = false;
//                         _isAddTimetableSectionVisible = false;
//                       }
//                     });
//                   },
//                 ),

//                 // Add Semester Details Section (visible only when clicked)
//                 if (_isAddSemesterDetailsSectionVisible) 
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: SemesterDetailsForm(),
//                   ),
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
  
//   // Add student tabs (Single Upload / Bulk Upload)
//   Widget _buildAddStudentTabs() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Color(0xFF1B5E20).withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           _buildTabButton(
//             icon: Icons.person_add,
//             title: 'Single Student', 
//             isSelected: _selectedAddStudentTab == 0,
//             onPressed: () {
//               setState(() {
//                 _selectedAddStudentTab = 0;
//               });
//             },
//           ),
//           Container(
//             width: 1, 
//             height: 40, 
//             color: Color(0xFF1B5E20).withOpacity(0.3),
//           ),
//           _buildTabButton(
//             icon: Icons.group_add,
//             title: 'Bulk Upload', 
//             isSelected: _selectedAddStudentTab == 1,
//             onPressed: () {
//               setState(() {
//                 _selectedAddStudentTab = 1;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
  
//   // Tab button widget
//   Widget _buildTabButton({
//     required IconData icon,
//     required String title,
//     required bool isSelected,
//     required VoidCallback onPressed,
//   }) {
//     return Expanded(
//       child: TextButton(
//         onPressed: onPressed,
//         style: ButtonStyle(
//           backgroundColor: MaterialStateProperty.all(
//             isSelected ? Color(0xFFE8F5E9) : Colors.transparent,
//           ),
//           foregroundColor: MaterialStateProperty.all(
//             Color(0xFF1B5E20),
//           ),
//           padding: MaterialStateProperty.all(
//             EdgeInsets.symmetric(vertical: 16),
//           ),
//           shape: MaterialStateProperty.all(
//             RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 20),
//             SizedBox(width: 8),
//             Text(
//               title,
//               style: GoogleFonts.raleway(
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Simplified version of the StudentListPage for integration
// class StudentListPage extends StatefulWidget {
//   const StudentListPage({Key? key}) : super(key: key);

//   @override
//   _StudentListPageState createState() => _StudentListPageState();
// }

// class _StudentListPageState extends State<StudentListPage> {
//   // Loading state
//   bool _isLoading = true;
  
//   // Store semesters and student data
//   List<int> _semesters = [];
//   Map<int, List<String>> _semesterBatches = {};
//   Map<int, Map<String, List<Map<String, dynamic>>>> _studentData = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchStudentData();
//   }
  
//   // Helper method to load dummy data for testing
//   Future<void> _loadDummyData() async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });
      
//       // Create dummy data for semester 1 and batch A
//       _semesters = [1];
//       _semesterBatches = {
//         1: ['A'],
//       };
//       _studentData = {
//         1: {
//           'A': [
//             {
//               'id': 'CS001',
//               'name': 'John Smith',
//               'email': 'CS001@gmail.com',
//               'phone': '9876543210',
//               'batch': 'A',
//               'semester': 1,
//               'attendance': 93.5,
//               'authUID': 'dummy-uid-1',
//             },
//             {
//               'id': 'CS002',
//               'name': 'Mary Johnson',
//               'email': 'CS002@gmail.com',
//               'phone': '8765432109',
//               'batch': 'A',
//               'semester': 1,
//               'attendance': 87.2,
//               'authUID': 'dummy-uid-2',
//             },
//           ],
//         },
//       };
      
//       setState(() {
//         _isLoading = false;
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Test data loaded successfully'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error loading test data: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Fetch student data from Firebase directly matching the way bulkupload stores it
//   Future<void> _fetchStudentData() async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       print("Starting to fetch student data from Firebase...");
      
//       // Get reference to Firestore
//       final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
//       // Create a hardcoded list of possible semesters since we know the structure
//       _semesters = [];
      
//       // Initialize data structures
//       _semesterBatches = {};
//       _studentData = {};
      
//       // Check each semester from 1 to 8
//       for (int semester = 1; semester <= 8; semester++) {
//         print("Checking if Semester $semester exists");
        
//         // Create a reference to the semester document
//         final semesterRef = firestore.collection('classes').doc('Sem$semester');
        
//         // Check if the semester document exists
//         final semesterDoc = await semesterRef.get();
//         if (!semesterDoc.exists) {
//           print("Semester $semester document doesn't exist");
//           continue;
//         }
        
//         // If we reach here, this semester exists
//         _semesters.add(semester);
        
//         // Initialize semester in data structures
//         _semesterBatches[semester] = [];
//         _studentData[semester] = {};
        
//         // Get all students in this semester
//         final studentsCollection = await semesterRef.collection('students').get();
//         print("Semester $semester has ${studentsCollection.docs.length} student documents");
            
//         if (studentsCollection.docs.isEmpty) continue;
        
//         // Track batches for this semester
//         Map<String, List<Map<String, dynamic>>> batchStudents = {};
        
//         // Process each student
//         for (var studentDoc in studentsCollection.docs) {
//           final studentData = studentDoc.data();
//           print("Processing student: ${studentData['name']} (${studentDoc.id})");
          
//           // Extract batch (removing "Batch " prefix if it exists)
//           String batchWithPrefix = studentData['batch'] ?? 'Batch A';
//           String batch = batchWithPrefix.replaceAll('Batch ', '');
          
//           print("Student batch: $batch (original: $batchWithPrefix)");
          
//           // Initialize batch in map if needed
//           if (!batchStudents.containsKey(batch)) {
//             batchStudents[batch] = [];
//           }
          
//           // Add student to the batch
//           batchStudents[batch]!.add({
//             'id': studentData['admissionNo'] ?? studentDoc.id,
//             'name': studentData['name'] ?? 'Unknown',
//             'email': studentData['email'] ?? studentData['username'] ?? 'Not provided',
//             'phone': studentData['phone'] ?? 'Not provided',
//             'batch': batch,
//             'semester': semester,
//             'authUID': studentData['authUID'] ?? '',
//           });
          
//           print("Added student ${studentData['name']} to batch $batch");
//         }
        
//         // Update semester data
//         _semesterBatches[semester] = batchStudents.keys.toList()..sort();
//         _studentData[semester] = batchStudents;
        
//         print("Semester $semester has batches: ${_semesterBatches[semester]}");
        
//         // Print count of students in each batch for debugging
//         batchStudents.forEach((batch, students) {
//           print("Batch $batch has ${students.length} students");
//         });
//       }
      
//       // Sort semesters
//       _semesters.sort();
      
//       setState(() {
//         _isLoading = false;
//       });
      
//       print("Finished fetching student data. Found ${_semesters.length} semesters with students.");
      
//       // If no students found, load demo data
//       if (_semesters.isEmpty) {
//         print("No students found in any semester. Consider using the 'Load Test Data' button.");
//       }
//     } catch (e) {
//       print('Error fetching student data: $e');
//       setState(() {
//         _isLoading = false;
//       });
      
//       // Show error snackbar
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error loading students: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(
//               color: Color(0xFF1B5E20),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Loading students...',
//               style: GoogleFonts.raleway(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
    
//     if (_semesters.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.warning_amber_rounded,
//               size: 48,
//               color: Colors.orange,
//             ),
//             SizedBox(height: 16),
//             Text(
//               'No student data available',
//               style: GoogleFonts.raleway(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _fetchStudentData,
//                   icon: Icon(Icons.refresh),
//                   label: Text('Refresh'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFF1B5E20),
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 ElevatedButton.icon(
//                   onPressed: _loadDummyData,
//                   icon: Icon(Icons.admin_panel_settings),
//                   label: Text('Load Test Data'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Student Directory',
//               style: GoogleFonts.raleway(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1B5E20),
//               ),
//             ),
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: _fetchStudentData,
//               color: Color(0xFF1B5E20),
//               tooltip: 'Refresh student data',
//             ),
//           ],
//         ),
//         SizedBox(height: 16),
//         Expanded(
//           child: ListView.builder(
//             itemCount: _semesters.length,
//             itemBuilder: (context, index) {
//               final semester = _semesters[index];
//               final batches = _semesterBatches[semester] ?? [];
              
//               return Card(
//                 elevation: 2,
//                 margin: EdgeInsets.only(bottom: 12),
//                 child: ExpansionTile(
//                   title: Text(
//                     'Semester $semester',
//                     style: GoogleFonts.raleway(
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF1B5E20),
//                     ),
//                   ),
//                   children: batches.map((batch) {
//                     final hasStudents = 
//                         (_studentData[semester]?[batch]?.isNotEmpty ?? false);
                    
//                     // Debug info about this batch
//                     print("Batch $batch in Semester $semester has ${_studentData[semester]?[batch]?.length ?? 0} students");
                    
//                     return ListTile(
//                       title: Text(
//                         'Batch $batch',
//                         style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             '${_studentData[semester]?[batch]?.length ?? 0} students',
//                             style: GoogleFonts.raleway(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           SizedBox(width: 8),
//                           Icon(Icons.arrow_forward_ios, size: 16),
//                         ],
//                       ),
//                       enabled: hasStudents,
//                       onTap: hasStudents
//                           ? () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => StudentDetailPage(
//                                     semester: semester,
//                                     batch: batch,
//                                     students: _studentData[semester]?[batch] ?? [],
//                                   ),
//                                 ),
//                               );
//                             }
//                           : null,
//                     );
//                   }).toList(),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// // Student Detail Page to display students by semester and batch
// class StudentDetailPage extends StatelessWidget {
//   final int semester;
//   final String batch;
//   final List<Map<String, dynamic>> students;

//   const StudentDetailPage({
//     Key? key,
//     required this.semester,
//     required this.batch,
//     required this.students,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Semester $semester - Batch $batch',
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
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Student List (${students.length} students)',
//                 style: GoogleFonts.raleway(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1B5E20),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search by name or admission number',
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 onChanged: (value) {
//                   // Implement search functionality here if needed
//                 },
//               ),
//               SizedBox(height: 16),
//               Expanded(
//                 child: students.isEmpty 
//                     ? Center(
//                         child: Text(
//                           'No students found in this batch',
//                           style: GoogleFonts.raleway(
//                             fontSize: 16,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       )
//                     : ListView.builder(
//                         itemCount: students.length,
//                         itemBuilder: (context, index) {
//                           final student = students[index];
//                           return Card(
//                             elevation: 2,
//                             margin: EdgeInsets.only(bottom: 12),
//                             child: ExpansionTile(
//                               title: Text(
//                                 student['name'] ?? 'Unknown',
//                                 style: GoogleFonts.raleway(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               subtitle: Text(
//                                 'Adm No: ${student['id']}',
//                                 style: GoogleFonts.raleway(
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.all(16.0),
//                                   child: Column(
//                                     children: [
//                                       _buildDetailRow('Email', student['email'] ?? 'Not provided'),
//                                       _buildDetailRow('Phone', student['phone'] ?? 'Not provided'),
//                                       if (student['attendance'] != null)
//                                         _buildDetailRow(
//                                           'Attendance',
//                                           '${student['attendance']}%',
//                                           valueColor: _getAttendanceColor(
//                                             student['attendance'] is double 
//                                                 ? student['attendance'] 
//                                                 : double.tryParse(student['attendance'].toString()) ?? 0.0
//                                           ),
//                                         ),
//                                       SizedBox(height: 8),
//                                       Row(
//                                         mainAxisAlignment: MainAxisAlignment.end,
//                                         children: [
//                                           TextButton.icon(
//                                             icon: Icon(Icons.edit, size: 18),
//                                             label: Text('Edit'),
//                                             onPressed: () {
//                                               // Implement edit functionality
//                                             },
//                                             style: TextButton.styleFrom(
//                                               foregroundColor: Color(0xFF1B5E20),
//                                             ),
//                                           ),
//                                           SizedBox(width: 8),
//                                           TextButton.icon(
//                                             icon: Icon(Icons.delete_outline, size: 18),
//                                             label: Text('Remove'),
//                                             onPressed: () {
//                                               // Implement delete functionality
//                                             },
//                                             style: TextButton.styleFrom(
//                                               foregroundColor: Colors.red,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         children: [
//           Text(
//             '$label: ',
//             style: GoogleFonts.raleway(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: GoogleFonts.raleway(
//                 color: valueColor,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getAttendanceColor(double attendance) {
//     if (attendance >= 90) {
//       return Colors.green;
//     } else if (attendance >= 75) {
//       return Colors.orange;
//     } else {
//       return Colors.red;
//     }
//   }
// }

