import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherListPage extends StatefulWidget {
  final String department;
  final List<Map<String, dynamic>>? teachers; // Keep for backward compatibility

  const TeacherListPage({
    Key? key,
    required this.department,
    this.teachers,
  }) : super(key: key);

  @override
  _TeacherListPageState createState() => _TeacherListPageState();
}

class _TeacherListPageState extends State<TeacherListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    // Always fetch from Firebase for real data
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Query the teachers collection for approved teachers in the specified department
      final QuerySnapshot querySnapshot = await _firestore
          .collection('teachers')
          .where('department', isEqualTo: widget.department)
          .where('status', isEqualTo: 'approved')
          .get();

      List<Map<String, dynamic>> fetchedTeachers = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        fetchedTeachers.add({
          'id': data['teacherId'] ?? '',
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['contact'] ?? 'Not available',
          'department': data['department'] ?? '',
          'position': data['position'] ?? 'Faculty',
          'specialization': data['specialization'] ?? 'Not specified',
          'researchInterests': data['researchInterests'] ?? [],
          'uid': doc.id,
        });
      }

      setState(() {
        _teachers = fetchedTeachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching teachers: $e';
        _isLoading = false;
      });
      print('Error in _fetchTeachers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.department} Teachers',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1B5E20)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF1B5E20)),
            onPressed: _fetchTeachers,
            tooltip: 'Refresh',
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Teacher List',
                    style: GoogleFonts.raleway(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    '${_teachers.length} Teachers',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildTeachersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeachersList() {
    if (_isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1B5E20),
          ),
        ),
      );
    } else if (_errorMessage.isNotEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTeachers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    } else if (_teachers.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No teachers found in ${widget.department} department',
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return Expanded(
        child: ListView.builder(
          itemCount: _teachers.length,
          itemBuilder: (context, index) {
            final teacher = _teachers[index];
            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text(
                  teacher['name'],
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${teacher['position']}',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
                  child: Text(
                    teacher['name'].isNotEmpty ? teacher['name'][0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('ID', teacher['id']),
                        _buildDetailRow('Email', teacher['email']),
                        _buildDetailRow('Phone', teacher['phone']),
                        _buildDetailRow('Specialization', 
                          teacher['specialization'] ?? 'Not specified'
                        ),
                        _buildResearchInterests(teacher['researchInterests'] ?? []),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: Icon(Icons.email, size: 16),
                              label: Text('Contact'),
                              onPressed: () {
                                // Email functionality could be implemented here
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF1B5E20),
                                side: BorderSide(color: Color(0xFF1B5E20)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label: ',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.raleway(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchInterests(List<dynamic> interests) {
    if (interests.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'Research Interests:',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: interests.map((interest) => Chip(
              label: Text(
                interest.toString(),
                style: GoogleFonts.raleway(fontSize: 12),
              ),
              backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class TeacherListPage extends StatelessWidget {
//   final String department;
//   final List<Map<String, dynamic>> teachers;

//   const TeacherListPage({
//     Key? key,
//     required this.department,
//     required this.teachers,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           '$department Teachers',
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
//                 'Teacher List',
//                 style: GoogleFonts.raleway(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF1B5E20),
//                 ),
//               ),
//               SizedBox(height: 16),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: teachers.length,
//                   itemBuilder: (context, index) {
//                     final teacher = teachers[index];
//                     return Card(
//                       elevation: 2,
//                       margin: EdgeInsets.only(bottom: 12),
//                       child: ExpansionTile(
//                         title: Text(
//                           teacher['name'],
//                           style: GoogleFonts.raleway(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         subtitle: Text(
//                           '${teacher['position']}',
//                           style: GoogleFonts.raleway(
//                             fontSize: 14,
//                           ),
//                         ),
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 _buildDetailRow('ID', teacher['id']),
//                                 _buildDetailRow('Email', teacher['email']),
//                                 _buildDetailRow('Phone', teacher['phone']),
//                                 _buildDetailRow('Specialization', 
//                                   teacher['specialization'] ?? 'Not specified'
//                                 ),
//                                 _buildResearchInterests(teacher['researchInterests'] ?? []),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
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
//               style: GoogleFonts.raleway(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResearchInterests(List<dynamic> interests) {
//     if (interests.isEmpty) return SizedBox.shrink();

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Research Interests:',
//             style: GoogleFonts.raleway(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 4),
//           Wrap(
//             spacing: 8,
//             runSpacing: 4,
//             children: interests.map((interest) => Chip(
//               label: Text(
//                 interest,
//                 style: GoogleFonts.raleway(fontSize: 12),
//               ),
//               backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
//             )).toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }