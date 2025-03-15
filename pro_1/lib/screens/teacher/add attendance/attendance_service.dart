import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all classes from Firestore
  static Future<List<String>> getAllClasses() async {
    List<String> classList = [];
    try {
      QuerySnapshot snapshot = await _firestore.collection('classes').get();
      for (var doc in snapshot.docs) {
        classList.add(doc.id); // Class ID
      }
    } catch (e) {
      print('Error fetching classes: $e');
    }
    return classList;
  }

  /// Fetch students for a selected class with optional batch filtering
  static Future<List<Map<String, dynamic>>> getStudentsForClass(
      String classId, {List<String>? batches}) async {
    List<Map<String, dynamic>> studentList = [];
    try {
      Query query = _firestore.collection('classes').doc(classId).collection('students');

      // Apply batch filter if provided
      if (batches != null && batches.isNotEmpty) {
        query = query.where('batch', whereIn: batches);
      }

      QuerySnapshot snapshot = await query.get();

      for (var doc in snapshot.docs) {
        studentList.add({
          'id': doc.id,
          'name': doc['name'],
          'isPresent': true, // Default to present
        });
      }
    } catch (e) {
      print('Error fetching students: $e');
    }
    return studentList;
  }

  /// Submit attendance for a class
  static Future<bool> submitAttendance({
    required String classId,
    required String subject,
    required String period,
    required DateTime date,
    required List<Map<String, dynamic>> studentsAttendance,
    required bool isTheory,
    List<String>? batches, // Only used for practical sessions
  }) async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      await _firestore
          .collection('attendance')
          .doc(classId)
          .collection(formattedDate)
          .doc('${period}_$subject')
          .set({
        'classId': classId,
        'subject': subject,
        'period': period,
        'date': formattedDate,
        'isTheory': isTheory,
        'batches': isTheory ? null : batches,
        'students': studentsAttendance.map((s) => {
          'studentId': s['id'],
          'isPresent': s['isPresent'],
        }).toList(),
      });

      return true;
    } catch (e) {
      print('Error submitting attendance: $e');
      return false;
    }
  }

  /// Get attendance records for a specific class, subject, and period
  static Future<List<Map<String, dynamic>>> getAttendanceForClass({
    required String classId,
    required String subject,
    required String period,
    required DateTime date,
  }) async {
    List<Map<String, dynamic>> attendanceList = [];
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      DocumentSnapshot snapshot = await _firestore
          .collection('attendance')
          .doc(classId)
          .collection(formattedDate)
          .doc('${period}_$subject')
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        attendanceList = List<Map<String, dynamic>>.from(data['students']);
      }
    } catch (e) {
      print('Error fetching attendance: $e');
    }
    return attendanceList;
  }
}























// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';


// class AttendanceService {
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   /// Fetch all classes
//   static Future<List<String>> getAllClasses() async {
//     List<String> classList = [];
//     try {
//       QuerySnapshot snapshot = await _firestore.collection('classes').get();
//       for (var doc in snapshot.docs) {
//         classList.add(doc.id); // Class ID
//       }
//     } catch (e) {
//       print('Error fetching classes: $e');
//     }
//     return classList;
//   }

//   /// Fetch students for a selected class
//   static Future<List<Map<String, dynamic>>> getStudentsForClass(String classId) async {
//     List<Map<String, dynamic>> studentList = [];
//     try {
//       QuerySnapshot snapshot =
//           await _firestore.collection('classes').doc(classId).collection('students').get();
//       for (var doc in snapshot.docs) {
//         studentList.add({
//           'id': doc.id,
//           'name': doc['name'],
//           'isPresent': true, // Default present
//         });
//       }
//     } catch (e) {
//       print('Error fetching students: $e');
//     }
//     return studentList;
//   }


//   static Future<bool> submitAttendance({
//   required String classId,
//   required String subject,
//   required String period,
//   required DateTime date,
//   required List<Map<String, dynamic>> studentsAttendance,
// }) async {
//   try {
//     String formattedDate = DateFormat('yyyy-MM-dd').format(date); // Format date
    
//     await _firestore
//         .collection('attendance')
//         .doc(classId) // Store per class
//         .collection(formattedDate) // Store per date
//         .doc('${period}_$subject') // Store per period + subject
//         .set({
//       'classId': classId,
//       'subject': subject,
//       'period': period,
//       'date': formattedDate,
//       'students': studentsAttendance.map((s) => {
//         'studentId': s['id'],
//         'isPresent': s['isPresent'],
//       }).toList(),
//     });

//     return true;
//   } catch (e) {
//     print('Error submitting attendance: $e');
//     return false;
//   }
// }


// static Future<List<Map<String, dynamic>>> getAttendanceForClass({
//   required String classId,
//   required String subject,
//   required String period,
//   required DateTime date,
// }) async {
//   List<Map<String, dynamic>> attendanceList = [];
//   try {
//     String formattedDate = DateFormat('yyyy-MM-dd').format(date);

//     DocumentSnapshot snapshot = await _firestore
//         .collection('attendance')
//         .doc(classId)
//         .collection(formattedDate)
//         .doc('${period}_$subject')
//         .get();

//     if (snapshot.exists) {
//       var data = snapshot.data() as Map<String, dynamic>;
//       attendanceList = List<Map<String, dynamic>>.from(data['students']);
//     }
//   } catch (e) {
//     print('Error fetching attendance: $e');
//   }
//   return attendanceList;
// }
// }






















