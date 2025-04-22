import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pro_1/screens/teacher/add%20attendance/attendance_service.dart';


// Create a global key for navigator state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class StudentOperations {
  // Edit student details in Firebase
  static Future<bool> editStudent({
    required BuildContext context,
    required Map<String, dynamic> student,
    required int semester,
    required String batch,
  }) async {
    try {
      // Initialize controllers with existing data
      final nameController = TextEditingController(text: student['name']);
      final emailController = TextEditingController(text: student['email']);
      final phoneController = TextEditingController(text: student['phone']);
      
      // Fetch attendance data for this student to display
      Map<String, dynamic> attendanceData = {};
      List<Map<String, dynamic>> subjectAttendance = [];
      double overallAttendancePercentage = 0.0;
      
      try {
        attendanceData = await AttendanceService.getStudentAttendanceCounters(
          classId: 'Sem$semester',
          studentId: student['id'],
        );
        
        subjectAttendance = await AttendanceService.getStudentSubjectAttendance(
          classId: 'Sem$semester',
          studentId: student['id'],
        );
        
        int markedPeriods = attendanceData['markedPeriods'] ?? 0;
        int presentPeriods = attendanceData['presentPeriods'] ?? 0;
        
        if (markedPeriods > 0) {
          overallAttendancePercentage = (presentPeriods / markedPeriods * 100);
        }
      } catch (e) {
        print('Error fetching attendance: $e');
        // Continue with edit operation even if attendance fetch fails
      }
      
      bool result = false;
      
      // Show edit dialog
      await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(
              'Edit Student',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student ID: ${student['id']}',
              )],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  
                  // Create a dialog context variable to hold the loading dialog context
                  BuildContext? loadingDialogContext;
                  
                  // Show loading indicator with a saved context
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext dialogContext) {
                      loadingDialogContext = dialogContext;
                      return AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF1B5E20)),
                            SizedBox(width: 20),
                            Text('Updating student details...'),
                          ],
                        ),
                      );
                    },
                  );
                  
                  try {
                    // Get updated data
                    Map<String, dynamic> updatedData = {
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone': phoneController.text.trim(),
                    };
                    
                    // Update in Firestore
                    await _updateStudentInFirestore(student, semester, batch, updatedData);
                    
                    // Close the loading dialog using its specific context
                    if (loadingDialogContext != null) {
                      Navigator.of(loadingDialogContext!).pop();
                    }
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Student details updated successfully'),
                        backgroundColor: Color(0xFF1B5E20),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    result = true;
                  } catch (e) {
                    // Close the loading dialog using its specific context
                    if (loadingDialogContext != null) {
                      Navigator.of(loadingDialogContext!).pop();
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating student: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    
                    result = false;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                child: Text('Save Changes'),
              ),
            ],
          );
        },
      );
      
      // Clean up controllers
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      
      return result;
    } catch (e) {
      print('Error in edit student operation: $e');
      return false;
    }
  }
  
  // Remove student from Firebase with admin verification
  static Future<bool> removeStudent({
    required BuildContext context,
    required Map<String, dynamic> student,
    required int semester,
    required String batch,
  }) async {
    try {
      bool result = false;
      
      // Show confirmation dialog
      await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          final passwordController = TextEditingController();
          
          return AlertDialog(
            title: Text(
              'Remove Student',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to remove:',
                    style: GoogleFonts.raleway(),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${student['name']} (${student['id']})',
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This action cannot be undone. Please enter your admin password to verify:',
                    style: GoogleFonts.raleway(),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  
                  // Create a dialog context variable to hold the loading dialog context
                  BuildContext? loadingDialogContext;
                  
                  // Show loading indicator with a saved context
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext dialogContext) {
                      loadingDialogContext = dialogContext;
                      return AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF1B5E20)),
                            SizedBox(width: 20),
                            Text('Verifying and removing student...'),
                          ],
                        ),
                      );
                    },
                  );
                  
                  try {
                    // Verify admin credentials
                    final adminPassword = passwordController.text;
                    final isVerified = await _verifyAdminPassword(adminPassword);
                    
                    if (isVerified) {
                      // Delete student from Firebase
                      await _deleteStudentFromFirestore(student, semester, batch);
                      
                      // Close the loading dialog using its specific context
                      if (loadingDialogContext != null) {
                        Navigator.of(loadingDialogContext!).pop();
                      }
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Student removed successfully'),
                          backgroundColor: Color(0xFF1B5E20),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      result = true;
                    } else {
                      // Close the loading dialog using its specific context
                      if (loadingDialogContext != null) {
                        Navigator.of(loadingDialogContext!).pop();
                      }
                      
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Incorrect admin password. Student not removed.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      
                      result = false;
                    }
                  } catch (e) {
                    // Close the loading dialog using its specific context
                    if (loadingDialogContext != null) {
                      Navigator.of(loadingDialogContext!).pop();
                    }
                    
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error removing student: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    
                    result = false;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Verify & Remove'),
              ),
            ],
          );
        },
      );
      
      return result;
    } catch (e) {
      print('Error in remove student operation: $e');
      return false;
    }
  }
  
  // Helper method to update student in Firestore
  static Future<void> _updateStudentInFirestore(
    Map<String, dynamic> student,
    int semester,
    String batch,
    Map<String, dynamic> updatedData
  ) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String admissionNo = student['id'];
      final String authUID = student['authUID'];
      
      // Update in classes collection
      await firestore
          .collection('classes')
          .doc('Sem$semester')
          .collection('students')
          .doc(admissionNo)
          .update(updatedData);
      
      // If authUID exists, update in users collection too
      if (authUID.isNotEmpty) {
        await firestore
            .collection('users')
            .doc(authUID)
            .update(updatedData);
      }
    } catch (e) {
      print('Error updating student in Firestore: $e');
      throw e;
    }
  }
  
  // Helper method to delete student from Firestore
  static Future<void> _deleteStudentFromFirestore(
    Map<String, dynamic> student,
    int semester,
    String batch
  ) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      final String admissionNo = student['id'];
      final String authUID = student['authUID'];
      final String email = student['email'];
      
      // Start a batch operation for atomicity
      WriteBatch batch = firestore.batch();
      
      // Delete from classes collection
      final classesRef = firestore
          .collection('classes')
          .doc('Sem$semester')
          .collection('students')
          .doc(admissionNo);
      
      batch.delete(classesRef);
      
      // If authUID exists, delete from users collection too
      if (authUID.isNotEmpty) {
        final usersRef = firestore.collection('users').doc(authUID);
        batch.delete(usersRef);
      }
      
      // Also remove attendance records for this student
      try {
        // Get current semester type
        String semesterType = await _getCurrentSemesterType();
        
        // Delete from attendance_counters
        final attendanceCounterRef = firestore
            .collection('attendance_counters')
            .doc(semesterType)
            .collection('Sem$semester')
            .doc(admissionNo);
        
        batch.delete(attendanceCounterRef);
        
        // Delete from subject_attendance
        // Note: This is a collection group, so we need to get all documents first
        // and then delete them individually
        QuerySnapshot subjectDocsSnapshot = await firestore
            .collection('subject_attendance')
            .doc(semesterType)
            .collection('Sem$semester')
            .doc(admissionNo)
            .collection('subjects')
            .get();
        
        for (var doc in subjectDocsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        
        // Delete the student's subject_attendance document itself
        batch.delete(firestore
            .collection('subject_attendance')
            .doc(semesterType)
            .collection('Sem$semester')
            .doc(admissionNo));
            
      } catch (attendanceError) {
        print('Warning: Error deleting attendance records: $attendanceError');
        // Continue with deletion even if attendance records deletion fails
      }
      
      // Commit the batch
      await batch.commit();
      
      // Try to delete the authentication account if it exists
      try {
        // First, re-authenticate the admin
        User? adminUser = auth.currentUser;
        if (adminUser != null && email.isNotEmpty) {
          // We can't delete other users from client side directly
          // This would typically be handled by a Cloud Function
          // For now, we'll just log a message
          print('Note: Deleting authentication account requires server-side implementation with Cloud Functions');
        }
      } catch (authError) {
        print('Warning: Unable to delete authentication account: $authError');
        // Continue without throwing - we've already deleted the Firestore records
      }
    } catch (e) {
      print('Error deleting student from Firestore: $e');
      throw e;
    }
  }
  
  // Helper method to verify admin password
  static Future<bool> _verifyAdminPassword(String password) async {
    try {
      // Get current logged in admin user
      final FirebaseAuth auth = FirebaseAuth.instance;
      User? currentUser = auth.currentUser;
      
      if (currentUser == null) {
        throw Exception('No admin currently logged in');
      }
      
      // Get current admin email
      String email = currentUser.email ?? '';
      
      if (email.isEmpty) {
        throw Exception('Admin email not available');
      }
      
      try {
        // Try to reauthenticate with the provided password
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        
        await currentUser.reauthenticateWithCredential(credential);
        
        // If we reach here, reauthentication was successful
        return true;
      } catch (authError) {
        print('Reauthentication failed: $authError');
        return false;
      }
    } catch (e) {
      print('Error verifying admin password: $e');
      return false;
    }
  }
  
  // Helper method to get color based on attendance percentage
  static Color _getAttendanceColor(double attendance) {
    if (attendance >= 90) {
      return Colors.green;
    } else if (attendance >= 75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Helper method to get current semester type from Firestore
  static Future<String> _getCurrentSemesterType() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      DocumentSnapshot semesterDoc = await firestore
          .collection('attendance')
          .doc('current_semester')
          .get();
      
      if (semesterDoc.exists) {
        Map<String, dynamic> data = semesterDoc.data() as Map<String, dynamic>;
        return data['semester'] ?? 'unknown';
      }
      
      return 'unknown';
    } catch (e) {
      print('Error getting current semester type: $e');
      return 'unknown';
    }
  }
}
