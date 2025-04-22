import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pro_1/services/approval_service.dart';

class TeacherApprovalPage extends StatefulWidget {
  @override
  _TeacherApprovalPageState createState() => _TeacherApprovalPageState();
}

class _TeacherApprovalPageState extends State<TeacherApprovalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TeacherService _teacherService = TeacherService();
  
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
          'authProvider': data['authProvider'] ?? 'email' // Store auth provider
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
      // Get approved count from the service
      int approvedCount = await _teacherService.getApprovedTodayCount();
      
      // Get rejected count from the service
      int rejectedCount = await _teacherService.getRejectedTodayCount();
          
      setState(() {
        _approvedToday = approvedCount;
        _rejectedToday = rejectedCount;
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
                'Auth Type',
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
                    children: [
                      Icon(
                        teacher['authProvider'] == 'google' 
                            ? Icons.g_mobiledata 
                            : Icons.email,
                        color: teacher['authProvider'] == 'google' 
                            ? Colors.red 
                            : Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text(
                        teacher['authProvider'] == 'google' ? 'Google' : 'Email',
                        style: GoogleFonts.raleway(),
                      ),
                    ],
                  ),
                ),
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

  // Method to approve a teacher
  Future<void> _approveTeacher(String uid) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF1B5E20)),
                SizedBox(width: 20),
                Text("Approving teacher...", style: GoogleFonts.raleway()),
              ],
            ),
          ),
        );
      },
    );

    try {
      print('Calling approveTeacher with UID: $uid');
      bool success = await _teacherService.approveTeacher(uid);
      
      // Close the loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
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
            content: Text('Failed to approve teacher. Please check logs for details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      print('Error in _approveTeacher: $e');
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

  // Method to reject a teacher
  Future<void> _rejectTeacher(String uid, String reason) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(width: 20),
                Text("Rejecting registration...", style: GoogleFonts.raleway()),
              ],
            ),
          ),
        );
      },
    );
    
    try {
      bool success = await _teacherService.rejectTeacher(uid, reason);
      
      // Close the loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
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
      // Close the loading dialog
      // Close the loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
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
                _buildDetailRow('Auth Provider', teacher['authProvider'] == 'google' ? 'Google' : 'Email'),
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
