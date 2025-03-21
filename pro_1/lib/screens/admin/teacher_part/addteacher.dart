import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_1/services/approval_service.dart';
// Import TeacherService instead of AuthService

class TeacherApprovalPage extends StatefulWidget {
  @override
  _TeacherApprovalPageState createState() => _TeacherApprovalPageState();
}

class _TeacherApprovalPageState extends State<TeacherApprovalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TeacherService _teacherService = TeacherService(); // Use TeacherService instead of AuthService
  
  // Stats counters
  int _approvedToday = 0;
  int _rejectedToday = 0;
  
  // Loading state
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Data
  List<Map<String, dynamic>> pendingTeachers = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingApprovals();
    _fetchTodayStats();
  }

  // Fetch pending teacher approvals from Firestore
  Future<void> _fetchPendingApprovals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Query the pendingApprovals collection for documents with status 'pending'
      final QuerySnapshot querySnapshot = await _firestore
          .collection('pendingApprovals')
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> teachers = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        teachers.add({
          'id': data['teacherId'] ?? '',
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['contact'] ?? '',
          'department': data['department'] ?? '',
          'position': data['position'] ?? 'Faculty', // Default value if position is not available
          'status': data['status'] ?? 'pending',
          'uid': doc.id,  // Store the Firestore document ID (which is the user's UID)
        });
      }

      setState(() {
        pendingTeachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  // Fetch today's approval/rejection stats
  Future<void> _fetchTodayStats() async {
    try {
      // Get today's date (start and end of day)
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      // Query for approvals made today
      final approvedToday = await _firestore
          .collection('pendingApprovals')
          .where('status', isEqualTo: 'approved')
          .where('processedAt', isGreaterThanOrEqualTo: startOfDay)
          .where('processedAt', isLessThanOrEqualTo: endOfDay)
          .get();
          
      // Query for rejections made today
      final rejectedToday = await _firestore
          .collection('pendingApprovals')
          .where('status', isEqualTo: 'rejected')
          .where('processedAt', isGreaterThanOrEqualTo: startOfDay)
          .where('processedAt', isLessThanOrEqualTo: endOfDay)
          .get();
          
      setState(() {
        _approvedToday = approvedToday.size;
        _rejectedToday = rejectedToday.size;
      });
    } catch (e) {
      print('Error fetching today stats: $e');
      // Don't set error state here, as it's not a critical feature
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header for the approval section
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Registration Approvals',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Review and approve or reject teacher registration requests',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Statistics cards
          Row(
            children: [
              _buildStatCard('Pending Approvals', pendingTeachers.length.toString(), Icons.hourglass_empty, Colors.orange),
              SizedBox(width: 16),
              _buildStatCard('Approved Today', _approvedToday.toString(), Icons.check_circle_outline, Colors.green),
              SizedBox(width: 16),
              _buildStatCard('Rejected Today', _rejectedToday.toString(), Icons.cancel_outlined, Colors.red),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Pending approvals list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Requests',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (!_isLoading)
                IconButton(
                  icon: Icon(Icons.refresh, color: Color(0xFF1B5E20)),
                  onPressed: () {
                    _fetchPendingApprovals();
                    _fetchTodayStats();
                  },
                  tooltip: 'Refresh',
                ),
            ],
          ),
          SizedBox(height: 16),
          
          // Show loading, error, or data
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B5E20),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Column(
                children: [
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPendingApprovals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Try Again'),
                  ),
                ],
              ),
            )
          else if (pendingTeachers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No pending approval requests',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Table of teachers
            _buildPendingTeachersTable(),
        ],
      ),
    );
  }
  
  // Statistics card widget
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.raleway(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Pending teachers table
  Widget _buildPendingTeachersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columns: [
            DataColumn(
              label: Text(
                'ID',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Name',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Department',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Position',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: pendingTeachers.map((teacher) {
            return DataRow(
              cells: [
                DataCell(Text(
                  teacher['id'],
                  style: GoogleFonts.raleway(),
                )),
                DataCell(Text(
                  teacher['name'],
                  style: GoogleFonts.raleway(),
                )),
                DataCell(Text(
                  teacher['email'],
                  style: GoogleFonts.raleway(),
                )),
                DataCell(Text(
                  teacher['department'],
                  style: GoogleFonts.raleway(),
                )),
                DataCell(Text(
                  teacher['position'],
                  style: GoogleFonts.raleway(),
                )),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () => _approveTeacher(teacher['uid']),
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () => _showRejectDialog(teacher['uid']),
                      ),
                      IconButton(
                        icon: Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Details',
                        onPressed: () => _showTeacherDetails(teacher),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Method to approve a teacher - Now using TeacherService
  Future<void> _approveTeacher(String uid) async {
    try {
      bool success = await _teacherService.approveTeacher(uid);
      
      if (success) {
        setState(() {
          // Remove the teacher from the local list
          pendingTeachers.removeWhere((teacher) => teacher['uid'] == uid);
          // Increment the approved count
          _approvedToday++;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teacher approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve teacher'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to show reject dialog
  void _showRejectDialog(String uid) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reject Registration',
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
                'Please provide a reason for rejection:',
                style: GoogleFonts.raleway(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason',
                  border: OutlineInputBorder(),
                  labelStyle: GoogleFonts.raleway(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rejectTeacher(uid, reasonController.text);
              },
              child: Text(
                'Reject',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to reject a teacher - Now using TeacherService
  Future<void> _rejectTeacher(String uid, String reason) async {
    try {
      bool success = await _teacherService.rejectTeacher(uid, reason);
      
      if (success) {
        setState(() {
          // Remove the teacher from the local list
          pendingTeachers.removeWhere((teacher) => teacher['uid'] == uid);
          // Increment the rejected count
          _rejectedToday++;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teacher registration rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject teacher registration'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to show teacher details
  void _showTeacherDetails(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Teacher Details',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', teacher['id']),
                _buildDetailRow('Name', teacher['name']),
                _buildDetailRow('Email', teacher['email']),
                _buildDetailRow('Phone', teacher['phone']),
                _buildDetailRow('Department', teacher['department']),
                _buildDetailRow('Position', teacher['position']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Color(0xFF1B5E20)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveTeacher(teacher['uid']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              child: Text('Approve'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showRejectDialog(teacher['uid']);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.raleway(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}










// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pro_1/services/authentication.dart'; // Assuming this path is correct

// class TeacherApprovalPage extends StatefulWidget {
//   @override
//   _TeacherApprovalPageState createState() => _TeacherApprovalPageState();
// }

// class _TeacherApprovalPageState extends State<TeacherApprovalPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthService _authService = AuthService();
  
//   // Stats counters
//   int _approvedToday = 0;
//   int _rejectedToday = 0;
  
//   // Loading state
//   bool _isLoading = true;
//   String _errorMessage = '';
  
//   // Data
//   List<Map<String, dynamic>> pendingTeachers = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchPendingApprovals();
//     _fetchTodayStats();
//   }

//   // Fetch pending teacher approvals from Firestore
//   Future<void> _fetchPendingApprovals() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       // Query the pendingApprovals collection for documents with status 'pending'
//       final QuerySnapshot querySnapshot = await _firestore
//           .collection('pendingApprovals')
//           .where('status', isEqualTo: 'pending')
//           .get();

//       List<Map<String, dynamic>> teachers = [];
      
//       for (var doc in querySnapshot.docs) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         teachers.add({
//           'id': data['teacherId'] ?? '',
//           'name': data['name'] ?? '',
//           'email': data['email'] ?? '',
//           'phone': data['contact'] ?? '',
//           'department': data['department'] ?? '',
//           'position': data['position'] ?? 'Faculty', // Default value if position is not available
//           'status': data['status'] ?? 'pending',
//           'uid': doc.id,  // Store the Firestore document ID (which is the user's UID)
//         });
//       }

//       setState(() {
//         pendingTeachers = teachers;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error fetching data: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   // Fetch today's approval/rejection stats
//   Future<void> _fetchTodayStats() async {
//     try {
//       // Get today's date (start and end of day)
//       DateTime now = DateTime.now();
//       DateTime startOfDay = DateTime(now.year, now.month, now.day);
//       DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
//       // Query for approvals made today
//       final approvedToday = await _firestore
//           .collection('pendingApprovals')
//           .where('status', isEqualTo: 'approved')
//           .where('processedAt', isGreaterThanOrEqualTo: startOfDay)
//           .where('processedAt', isLessThanOrEqualTo: endOfDay)
//           .get();
          
//       // Query for rejections made today
//       final rejectedToday = await _firestore
//           .collection('pendingApprovals')
//           .where('status', isEqualTo: 'rejected')
//           .where('processedAt', isGreaterThanOrEqualTo: startOfDay)
//           .where('processedAt', isLessThanOrEqualTo: endOfDay)
//           .get();
          
//       setState(() {
//         _approvedToday = approvedToday.size;
//         _rejectedToday = rejectedToday.size;
//       });
//     } catch (e) {
//       print('Error fetching today stats: $e');
//       // Don't set error state here, as it's not a critical feature
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header for the approval section
//           Container(
//             margin: EdgeInsets.only(bottom: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Teacher Registration Approvals',
//                   style: GoogleFonts.playfairDisplay(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1B5E20),
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Review and approve or reject teacher registration requests',
//                   style: GoogleFonts.raleway(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Statistics cards
//           Row(
//             children: [
//               _buildStatCard('Pending Approvals', pendingTeachers.length.toString(), Icons.hourglass_empty, Colors.orange),
//               SizedBox(width: 16),
//               _buildStatCard('Approved Today', _approvedToday.toString(), Icons.check_circle_outline, Colors.green),
//               SizedBox(width: 16),
//               _buildStatCard('Rejected Today', _rejectedToday.toString(), Icons.cancel_outlined, Colors.red),
//             ],
//           ),
          
//           SizedBox(height: 24),
          
//           // Pending approvals list
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Pending Requests',
//                 style: GoogleFonts.raleway(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               if (!_isLoading)
//                 IconButton(
//                   icon: Icon(Icons.refresh, color: Color(0xFF1B5E20)),
//                   onPressed: () {
//                     _fetchPendingApprovals();
//                     _fetchTodayStats();
//                   },
//                   tooltip: 'Refresh',
//                 ),
//             ],
//           ),
//           SizedBox(height: 16),
          
//           // Show loading, error, or data
//           if (_isLoading)
//             Center(
//               child: CircularProgressIndicator(
//                 color: Color(0xFF1B5E20),
//               ),
//             )
//           else if (_errorMessage.isNotEmpty)
//             Center(
//               child: Column(
//                 children: [
//                   Text(
//                     _errorMessage,
//                     style: TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _fetchPendingApprovals,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF1B5E20),
//                       foregroundColor: Colors.white,
//                     ),
//                     child: Text('Try Again'),
//                   ),
//                 ],
//               ),
//             )
//           else if (pendingTeachers.isEmpty)
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(32.0),
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.check_circle,
//                       size: 64,
//                       color: Colors.grey[400],
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       'No pending approval requests',
//                       style: GoogleFonts.raleway(
//                         fontSize: 16,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             // Table of teachers
//             _buildPendingTeachersTable(),
//         ],
//       ),
//     );
//   }
  
//   // Statistics card widget
//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Expanded(
//       child: Container(
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(
//               icon,
//               color: color,
//               size: 28,
//             ),
//             SizedBox(height: 8),
//             Text(
//               value,
//               style: GoogleFonts.raleway(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             SizedBox(height: 4),
//             Text(
//               title,
//               style: GoogleFonts.raleway(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   // Pending teachers table
//   Widget _buildPendingTeachersTable() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           columnSpacing: 20,
//           horizontalMargin: 16,
//           headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
//           columns: [
//             DataColumn(
//               label: Text(
//                 'ID',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Name',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Email',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Department',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Position',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Actions',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//           rows: pendingTeachers.map((teacher) {
//             return DataRow(
//               cells: [
//                 DataCell(Text(
//                   teacher['id'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['name'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['email'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['department'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['position'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.check_circle, color: Colors.green),
//                         tooltip: 'Approve',
//                         onPressed: () => _approveTeacher(teacher['uid']),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.cancel, color: Colors.red),
//                         tooltip: 'Reject',
//                         onPressed: () => _showRejectDialog(teacher['uid']),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.visibility, color: Colors.blue),
//                         tooltip: 'View Details',
//                         onPressed: () => _showTeacherDetails(teacher),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   // Method to approve a teacher
//   Future<void> _approveTeacher(String uid) async {
//     try {
//       bool success = await _authService.approveTeacher(uid);
      
//       if (success) {
//         setState(() {
//           // Remove the teacher from the local list
//           pendingTeachers.removeWhere((teacher) => teacher['uid'] == uid);
//           // Increment the approved count
//           _approvedToday++;
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Teacher approved successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to approve teacher'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Method to show reject dialog
//   void _showRejectDialog(String uid) {
//     final reasonController = TextEditingController();
    
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Reject Registration',
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
//                 'Please provide a reason for rejection:',
//                 style: GoogleFonts.raleway(),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: reasonController,
//                 decoration: InputDecoration(
//                   hintText: 'Enter rejection reason',
//                   border: OutlineInputBorder(),
//                   labelStyle: GoogleFonts.raleway(),
//                 ),
//                 maxLines: 3,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _rejectTeacher(uid, reasonController.text);
//               },
//               child: Text(
//                 'Reject',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Method to reject a teacher
//   Future<void> _rejectTeacher(String uid, String reason) async {
//     try {
//       bool success = await _authService.rejectTeacher(uid, reason);
      
//       if (success) {
//         setState(() {
//           // Remove the teacher from the local list
//           pendingTeachers.removeWhere((teacher) => teacher['uid'] == uid);
//           // Increment the rejected count
//           _rejectedToday++;
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Teacher registration rejected'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to reject teacher registration'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Method to show teacher details
//   void _showTeacherDetails(Map<String, dynamic> teacher) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Teacher Details',
//             style: GoogleFonts.raleway(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1B5E20),
//             ),
//           ),
//           content: Container(
//             width: double.maxFinite,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow('ID', teacher['id']),
//                 _buildDetailRow('Name', teacher['name']),
//                 _buildDetailRow('Email', teacher['email']),
//                 _buildDetailRow('Phone', teacher['phone']),
//                 _buildDetailRow('Department', teacher['department']),
//                 _buildDetailRow('Position', teacher['position']),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(
//                 'Close',
//                 style: TextStyle(color: Color(0xFF1B5E20)),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _approveTeacher(teacher['uid']);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF1B5E20),
//                 foregroundColor: Colors.white,
//               ),
//               child: Text('Approve'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _showRejectDialog(teacher['uid']);
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red,
//               ),
//               child: Text('Reject'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Helper method to build detail rows
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               '$label:',
//               style: GoogleFonts.raleway(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: GoogleFonts.raleway(
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



//teacher access--approval-reject done 
//import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pro_1/services/authentication.dart'; // Assuming this path is correct

// class TeacherApprovalPage extends StatefulWidget {
//   @override
//   _TeacherApprovalPageState createState() => _TeacherApprovalPageState();
// }

// class _TeacherApprovalPageState extends State<TeacherApprovalPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthService _authService = AuthService();
  
//   // Stats counters
//   int _approvedToday = 0;
//   int _rejectedToday = 0;
  
//   // Loading state
//   bool _isLoading = true;
//   String _errorMessage = '';
  
//   // Data
//   List<Map<String, dynamic>> pendingTeachers = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchPendingApprovals();
//     _fetchTodayStats();
//   }

//   // Fetch pending teacher approvals from Firestore
//   Future<void> _fetchPendingApprovals() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       // Query the pendingApprovals collection for documents with status 'pending'
//       final QuerySnapshot querySnapshot = await _firestore
//           .collection('pendingApprovals')
//           .where('status', isEqualTo: 'pending')
//           .get();

//       List<Map<String, dynamic>> teachers = [];
      
//       for (var doc in querySnapshot.docs) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         teachers.add({
//           'id': data['teacherId'] ?? '',
//           'name': data['name'] ?? '',
//           'email': data['email'] ?? '',
//           'phone': data['contact'] ?? '',
//           'department': data['department'] ?? '',
//           'position': data['position'] ?? 'Faculty', // Default value if position is not available
//           'status': data['status'] ?? 'pending',
//           'uid': doc.id,  // Store the Firestore document ID (which is the user's UID)
//         });
//       }

//       setState(() {
//         pendingTeachers = teachers;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error fetching data: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   // Fetch today's approval/rejection stats
//   Future<void> _fetchTodayStats() async {
//     try {
//       // Get today's date (start and end of day)
//       DateTime now = DateTime.now();
//       DateTime startOfDay = DateTime(now.year, now.month, now.day);
//       DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
//       // Query for approvals made today
//       final approvedToday = await _firestore
//           .collection('pendingApprovals')
//           .where('status', isEqualTo: 'approved')
//           .where('processedAt', isGreaterThanOrEqualTo: startOfDay)
//           .where('processedAt', isLessThanOrEqualTo: endOfDay)
//           .get();
          
//       // Query for rejections made today
//       final rejectedToday = await _firestore
//           .collection('pendingApprovals')
//           .where('status', isEqualTo: 'rejected')
//           .where('processedAt', isGreaterThanOrEqualTo: startOfDay)
//           .where('processedAt', isLessThanOrEqualTo: endOfDay)
//           .get();
          
//       setState(() {
//         _approvedToday = approvedToday.size;
//         _rejectedToday = rejectedToday.size;
//       });
//     } catch (e) {
//       print('Error fetching today stats: $e');
//       // Don't set error state here, as it's not a critical feature
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header for the approval section
//           Container(
//             margin: EdgeInsets.only(bottom: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Teacher Registration Approvals',
//                   style: GoogleFonts.playfairDisplay(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1B5E20),
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Review and approve or reject teacher registration requests',
//                   style: GoogleFonts.raleway(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Statistics cards
//           Row(
//             children: [
//               _buildStatCard('Pending Approvals', pendingTeachers.length.toString(), Icons.hourglass_empty, Colors.orange),
//               SizedBox(width: 16),
//               _buildStatCard('Approved Today', _approvedToday.toString(), Icons.check_circle_outline, Colors.green),
//               SizedBox(width: 16),
//               _buildStatCard('Rejected Today', _rejectedToday.toString(), Icons.cancel_outlined, Colors.red),
//             ],
//           ),
          
//           SizedBox(height: 24),
          
//           // Pending approvals list
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Pending Requests',
//                 style: GoogleFonts.raleway(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               if (!_isLoading)
//                 IconButton(
//                   icon: Icon(Icons.refresh, color: Color(0xFF1B5E20)),
//                   onPressed: () {
//                     _fetchPendingApprovals();
//                     _fetchTodayStats();
//                   },
//                   tooltip: 'Refresh',
//                 ),
//             ],
//           ),
//           SizedBox(height: 16),
          
//           // Show loading, error, or data
//           if (_isLoading)
//             Center(
//               child: CircularProgressIndicator(
//                 color: Color(0xFF1B5E20),
//               ),
//             )
//           else if (_errorMessage.isNotEmpty)
//             Center(
//               child: Column(
//                 children: [
//                   Text(
//                     _errorMessage,
//                     style: TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _fetchPendingApprovals,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF1B5E20),
//                       foregroundColor: Colors.white,
//                     ),
//                     child: Text('Try Again'),
//                   ),
//                 ],
//               ),
//             )
//           else if (pendingTeachers.isEmpty)
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(32.0),
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.check_circle,
//                       size: 64,
//                       color: Colors.grey[400],
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       'No pending approval requests',
//                       style: GoogleFonts.raleway(
//                         fontSize: 16,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             // Table of teachers
//             _buildPendingTeachersTable(),
//         ],
//       ),
//     );
//   }
  
//   // Statistics card widget
//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Expanded(
//       child: Container(
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(
//               icon,
//               color: color,
//               size: 28,
//             ),
//             SizedBox(height: 8),
//             Text(
//               value,
//               style: GoogleFonts.raleway(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             SizedBox(height: 4),
//             Text(
//               title,
//               style: GoogleFonts.raleway(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   // Pending teachers table
//   Widget _buildPendingTeachersTable() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           columnSpacing: 20,
//           horizontalMargin: 16,
//           headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
//           columns: [
//             DataColumn(
//               label: Text(
//                 'ID',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Name',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Email',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Department',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Position',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Actions',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//           rows: pendingTeachers.map((teacher) {
//             return DataRow(
//               cells: [
//                 DataCell(Text(
//                   teacher['id'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['name'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['email'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['department'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['position'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.check_circle, color: Colors.green),
//                         tooltip: 'Approve',
//                         onPressed: () => _approveTeacher(teacher['uid']),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.cancel, color: Colors.red),
//                         tooltip: 'Reject',
//                         onPressed: () => _showRejectDialog(teacher['uid']),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.visibility, color: Colors.blue),
//                         tooltip: 'View Details',
//                         onPressed: () => _showTeacherDetails(teacher),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   // Method to approve a teacher
//   Future<void> _approveTeacher(String uid) async {
//     try {
//       bool success = await _authService.approveTeacher(uid);
      
//       if (success) {
//         setState(() {
//           // Remove the teacher from the local list
//           pendingTeachers.removeWhere((teacher) => teacher['uid'] == uid);
//           // Increment the approved count
//           _approvedToday++;
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Teacher approved successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to approve teacher'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Method to show reject dialog
//   void _showRejectDialog(String uid) {
//     final reasonController = TextEditingController();
    
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Reject Registration',
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
//                 'Please provide a reason for rejection:',
//                 style: GoogleFonts.raleway(),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: reasonController,
//                 decoration: InputDecoration(
//                   hintText: 'Enter rejection reason',
//                   border: OutlineInputBorder(),
//                   labelStyle: GoogleFonts.raleway(),
//                 ),
//                 maxLines: 3,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _rejectTeacher(uid, reasonController.text);
//               },
//               child: Text(
//                 'Reject',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Method to reject a teacher
//   Future<void> _rejectTeacher(String uid, String reason) async {
//     try {
//       bool success = await _authService.rejectTeacher(uid, reason);
      
//       if (success) {
//         setState(() {
//           // Remove the teacher from the local list
//           pendingTeachers.removeWhere((teacher) => teacher['uid'] == uid);
//           // Increment the rejected count
//           _rejectedToday++;
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Teacher registration rejected'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to reject teacher registration'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Method to show teacher details
//   void _showTeacherDetails(Map<String, dynamic> teacher) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Teacher Details',
//             style: GoogleFonts.raleway(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1B5E20),
//             ),
//           ),
//           content: Container(
//             width: double.maxFinite,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow('ID', teacher['id']),
//                 _buildDetailRow('Name', teacher['name']),
//                 _buildDetailRow('Email', teacher['email']),
//                 _buildDetailRow('Phone', teacher['phone']),
//                 _buildDetailRow('Department', teacher['department']),
//                 _buildDetailRow('Position', teacher['position']),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(
//                 'Close',
//                 style: TextStyle(color: Color(0xFF1B5E20)),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _approveTeacher(teacher['uid']);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF1B5E20),
//                 foregroundColor: Colors.white,
//               ),
//               child: Text('Approve'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _showRejectDialog(teacher['uid']);
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red,
//               ),
//               child: Text('Reject'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Helper method to build detail rows
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               '$label:',
//               style: GoogleFonts.raleway(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: GoogleFonts.raleway(
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class TeacherApprovalPage extends StatefulWidget {
//   @override
//   _TeacherApprovalPageState createState() => _TeacherApprovalPageState();
// }

// class _TeacherApprovalPageState extends State<TeacherApprovalPage> {
//   // Sample data for pending teacher approvals
//   List<Map<String, dynamic>> pendingTeachers = [
//     {
//       'id': 'T1001',
//       'name': 'Dr. Sarah Johnson',
//       'email': 'sarah.johnson@university.edu',
//       'phone': '+1 (555) 123-4567',
//       'department': 'Computer Science',
//       'position': 'Assistant Professor',
//       'status': 'pending'
//     },
//     {
//       'id': 'T1002',
//       'name': 'Prof. Michael Chen',
//       'email': 'michael.chen@university.edu',
//       'phone': '+1 (555) 234-5678',
//       'department': 'Electrical Engineering',
//       'position': 'Associate Professor',
//       'status': 'pending'
//     },
//     {
//       'id': 'T1003',
//       'name': 'Dr. Emily Rodriguez',
//       'email': 'emily.rodriguez@university.edu',
//       'phone': '+1 (555) 345-6789',
//       'department': 'Mechanical Engineering',
//       'position': 'Professor',
//       'status': 'pending'
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header for the approval section
//           Container(
//             margin: EdgeInsets.only(bottom: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Teacher Registration Approvals',
//                   style: GoogleFonts.playfairDisplay(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1B5E20),
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Review and approve or reject teacher registration requests',
//                   style: GoogleFonts.raleway(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Statistics cards
//           Row(
//             children: [
//               _buildStatCard('Pending Approvals', pendingTeachers.length.toString(), Icons.hourglass_empty, Colors.orange),
//               SizedBox(width: 16),
//               _buildStatCard('Approved Today', '5', Icons.check_circle_outline, Colors.green),
//               SizedBox(width: 16),
//               _buildStatCard('Rejected Today', '2', Icons.cancel_outlined, Colors.red),
//             ],
//           ),
          
//           SizedBox(height: 24),
          
//           // Pending approvals list
//           Text(
//             'Pending Requests',
//             style: GoogleFonts.raleway(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[800],
//             ),
//           ),
//           SizedBox(height: 16),
          
//           // Table of teachers
//           _buildPendingTeachersTable(),
//         ],
//       ),
//     );
//   }
  
//   // Statistics card widget
//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Expanded(
//       child: Container(
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(
//               icon,
//               color: color,
//               size: 28,
//             ),
//             SizedBox(height: 8),
//             Text(
//               value,
//               style: GoogleFonts.raleway(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             SizedBox(height: 4),
//             Text(
//               title,
//               style: GoogleFonts.raleway(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   // Pending teachers table
//   Widget _buildPendingTeachersTable() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           columnSpacing: 20,
//           horizontalMargin: 16,
//           headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
//           columns: [
//             DataColumn(
//               label: Text(
//                 'ID',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Name',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Email',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Department',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Position',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//             DataColumn(
//               label: Text(
//                 'Actions',
//                 style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//           rows: pendingTeachers.map((teacher) {
//             return DataRow(
//               cells: [
//                 DataCell(Text(
//                   teacher['id'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['name'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['email'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['department'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(Text(
//                   teacher['position'],
//                   style: GoogleFonts.raleway(),
//                 )),
//                 DataCell(
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.check_circle, color: Colors.green),
//                         tooltip: 'Approve',
//                         onPressed: () => _approveTeacher(teacher['id']),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.cancel, color: Colors.red),
//                         tooltip: 'Reject',
//                         onPressed: () => _showRejectDialog(teacher['id']),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.visibility, color: Colors.blue),
//                         tooltip: 'View Details',
//                         onPressed: () => _showTeacherDetails(teacher),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   // Method to approve a teacher
//   void _approveTeacher(String teacherId) {
//     setState(() {
//       pendingTeachers.removeWhere((teacher) => teacher['id'] == teacherId);
//     });
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Teacher $teacherId approved successfully'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   // Method to show reject dialog
//   void _showRejectDialog(String teacherId) {
//     final reasonController = TextEditingController();
    
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Reject Registration',
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
//                 'Please provide a reason for rejection:',
//                 style: GoogleFonts.raleway(),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: reasonController,
//                 decoration: InputDecoration(
//                   hintText: 'Enter rejection reason',
//                   border: OutlineInputBorder(),
//                   labelStyle: GoogleFonts.raleway(),
//                 ),
//                 maxLines: 3,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _rejectTeacher(teacherId, reasonController.text);
//               },
//               child: Text(
//                 'Reject',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Method to reject a teacher
//   void _rejectTeacher(String teacherId, String reason) {
//     setState(() {
//       pendingTeachers.removeWhere((teacher) => teacher['id'] == teacherId);
//     });
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Teacher $teacherId registration rejected'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   // Method to show teacher details
//   void _showTeacherDetails(Map<String, dynamic> teacher) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Teacher Details',
//             style: GoogleFonts.raleway(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1B5E20),
//             ),
//           ),
//           content: Container(
//             width: double.maxFinite,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow('ID', teacher['id']),
//                 _buildDetailRow('Name', teacher['name']),
//                 _buildDetailRow('Email', teacher['email']),
//                 _buildDetailRow('Phone', teacher['phone']),
//                 _buildDetailRow('Department', teacher['department']),
//                 _buildDetailRow('Position', teacher['position']),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(
//                 'Close',
//                 style: TextStyle(color: Color(0xFF1B5E20)),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _approveTeacher(teacher['id']);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF1B5E20),
//                 foregroundColor: Colors.white,
//               ),
//               child: Text('Approve'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _showRejectDialog(teacher['id']);
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red,
//               ),
//               child: Text('Reject'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Helper method to build detail rows
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               '$label:',
//               style: GoogleFonts.raleway(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: GoogleFonts.raleway(
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:file_picker/file_picker.dart';

// class AddTeacherPage extends StatefulWidget {
//   @override
//   _AddTeacherPageState createState() => _AddTeacherPageState();
// }

// class _AddTeacherPageState extends State<AddTeacherPage> {
//   // Sample data for departments and positions
//   final List<String> departments = [
//     'Computer Science',
//     'Electrical Engineering',
//     'Mechanical Engineering',
//     'Civil Engineering',
//     'Chemical Engineering',
//   ];
  
//   final List<String> positions = [
//     'Assistant Professor',
//     'Associate Professor',
//     'Professor',
//     'Head of Department',
//     'Adjunct Faculty'
//   ];
  
//   // Form keys and controllers for adding a teacher
//   final _formKey = GlobalKey<FormState>();
//   final nameController = TextEditingController();
//   final idController = TextEditingController();
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final specializationController = TextEditingController();
//   final researchInterestsController = TextEditingController();
  
//   String? selectedDepartment;
//   String? selectedPosition;
  
//   // Current selected tab for Add Teachers section
//   int _currentAddTeacherTab = 0;

//   @override
//   void dispose() {
//     nameController.dispose();
//     idController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//     specializationController.dispose();
//     researchInterestsController.dispose();
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
//                   child: _buildAddTeacherTabButton(0, 'Single Teacher'),
//                 ),
//                 Expanded(
//                   child: _buildAddTeacherTabButton(1, 'Bulk Upload'),
//                 ),
//               ],
//             ),
//           ),
          
//           // Content based on selected tab
//           _currentAddTeacherTab == 0
//               ? _buildSingleTeacherForm()
//               : _buildBulkUploadForm(),
//         ],
//       ),
//     );
//   }
  
//   // Add Teacher Tab Button
//   Widget _buildAddTeacherTabButton(int index, String label) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _currentAddTeacherTab = index;
//         });
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           color: _currentAddTeacherTab == index
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
//             color: _currentAddTeacherTab == index ? Colors.white : Colors.grey,
//           ),
//         ),
//       ),
//     );
//   }
  
//   // Form for adding a single teacher
//   Widget _buildSingleTeacherForm() {
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
//                 return 'Please enter teacher name';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           TextFormField(
//             controller: idController,
//             decoration: InputDecoration(
//               labelText: 'Teacher ID',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter teacher ID';
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
//               labelText: 'Position',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//             value: selectedPosition,
//             items: positions.map((String position) {
//               return DropdownMenuItem<String>(
//                 value: position,
//                 child: Text(position),
//               );
//             }).toList(),
//             onChanged: (String? newValue) {
//               setState(() {
//                 selectedPosition = newValue;
//               });
//             },
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please select a position';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: 16),
//           TextFormField(
//             controller: specializationController,
//             decoration: InputDecoration(
//               labelText: 'Specialization',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//           ),
//           SizedBox(height: 16),
//           TextFormField(
//             controller: researchInterestsController,
//             decoration: InputDecoration(
//               labelText: 'Research Interests (comma-separated)',
//               border: OutlineInputBorder(),
//               labelStyle: GoogleFonts.raleway(),
//             ),
//           ),
//           SizedBox(height: 24),
//           Center(
//             child: ElevatedButton.icon(
//               icon: Icon(Icons.save),
//               label: Text('Save Teacher'),
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
//                   // Add your logic to save the teacher
//                   _showSuccessMessage();
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   // Form for bulk uploading teachers
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
//                   'Step 1: Download Template',
//                   style: GoogleFonts.raleway(
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1B5E20),
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Download our pre-formatted Excel template with required fields.',
//                   style: GoogleFonts.raleway(),
//                 ),
//                 SizedBox(height: 12),
//                 ElevatedButton.icon(
//                   icon: Icon(Icons.download),
//                   label: Text('Download Template'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFF1B5E20),
//                     foregroundColor: Colors.white,
//                     textStyle: GoogleFonts.raleway(),
//                   ),
//                   onPressed: _downloadTemplate,
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
//                   'Upload your filled CSV/Excel file with teacher data.',
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
//                   'Step 3: Data Validation',
//                   style: GoogleFonts.raleway(
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1B5E20),
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'The system will automatically validate your data.',
//                   style: GoogleFonts.raleway(),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   '• Checks if departments exist\n• Verifies required fields\n• Identifies duplicate IDs',
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
//                   'Step 4: Confirm & Add',
//                   style: GoogleFonts.raleway(
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1B5E20),
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Review and confirm the entries before adding them.',
//                   style: GoogleFonts.raleway(),
//                 ),
//                 SizedBox(height: 12),
//                 Center(
//                   child: ElevatedButton.icon(
//                     icon: Icon(Icons.check_circle),
//                     label: Text('Upload & Validate'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF1B5E20),
//                       foregroundColor: Colors.white,
//                       textStyle: GoogleFonts.raleway(
//                         fontWeight: FontWeight.w600,
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                     ),
//                     onPressed: () {
//                       // This would typically be enabled after a file is selected
//                       _showUploadSuccessMessage();
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Method to download the template
//   void _downloadTemplate() async {
//     // This would create an Excel file template in a real app
//     final snackBar = SnackBar(
//       content: Text('Template downloaded successfully'),
//       backgroundColor: Color(0xFF1B5E20),
//     );
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }

//   // Method to pick a file for bulk upload
//   void _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['xlsx', 'csv'],
//     );

//     if (result != null) {
//       // In a real app, you would process the file here
//       final snackBar = SnackBar(
//         content: Text('File selected: ${result.files.single.name}'),
//         backgroundColor: Color(0xFF1B5E20),
//       );
//       ScaffoldMessenger.of(context).showSnackBar(snackBar);
//     }
//   }

//   // Method to show success message after adding a teacher
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
//             'Teacher added successfully.',
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
//                 specializationController.clear();
//                 researchInterestsController.clear();
//                 setState(() {
//                   selectedDepartment = null;
//                   selectedPosition = null;
//                 });
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
//             'Teachers data validated and processed successfully. 10 new teachers were added.',
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