

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
      String semesterType = await _getSemesterType();

      // Create a batch operation for multiple writes
      WriteBatch batch = _firestore.batch();

      // 1. Set the attendance record for this period
      DocumentReference periodRef = _firestore
          .collection('attendance')
          .doc(classId)
          .collection(formattedDate)
          .doc('${period}_$subject');

      batch.set(periodRef, {
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

      // 2. Update attendance counters for each student
      for (var student in studentsAttendance) {
        String studentId = student['id'];
        bool isPresent = student['isPresent'];
        
        // Update overall attendance counter
        DocumentReference studentAttendanceRef = _firestore
            .collection('attendance_counters')
            .doc(semesterType)
            .collection(classId)
            .doc(studentId);
        
        // Use FieldValue.increment to atomically update counters
        batch.set(studentAttendanceRef, {
          'markedPeriods': FieldValue.increment(1),
          'presentPeriods': isPresent ? FieldValue.increment(1) : FieldValue.increment(0),
          'studentId': studentId,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // NEW: Update subject-wise attendance counter
        DocumentReference subjectAttendanceRef = _firestore
            .collection('subject_attendance')
            .doc(semesterType)
            .collection(classId)
            .doc(studentId)
            .collection('subjects')
            .doc(subject);
        
        batch.set(subjectAttendanceRef, {
          'subject': subject,
          'markedPeriods': FieldValue.increment(1),
          'presentPeriods': isPresent ? FieldValue.increment(1) : FieldValue.increment(0),
          'studentId': studentId,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Commit all the writes as a single batch
      await batch.commit();
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
  
  /// Get attendance counters for a specific student
  static Future<Map<String, dynamic>> getStudentAttendanceCounters({
    required String classId,
    required String studentId,
  }) async {
    try {
      String semesterType = await _getSemesterType();
      
      DocumentSnapshot snapshot = await _firestore
          .collection('attendance_counters')
          .doc(semesterType)
          .collection(classId)
          .doc(studentId)
          .get();
      
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        return {
          'markedPeriods': 0,
          'presentPeriods': 0,
          'studentId': studentId,
        };
      }
    } catch (e) {
      print('Error fetching attendance counters: $e');
      return {
        'markedPeriods': 0,
        'presentPeriods': 0,
        'studentId': studentId,
        'error': e.toString(),
      };
    }
  }
  
  /// NEW: Get subject-wise attendance counters for a specific student
  static Future<List<Map<String, dynamic>>> getStudentSubjectAttendance({
    required String classId,
    required String studentId,
  }) async {
    List<Map<String, dynamic>> subjectAttendance = [];
    try {
      String semesterType = await _getSemesterType();
      
      QuerySnapshot snapshot = await _firestore
          .collection('subject_attendance')
          .doc(semesterType)
          .collection(classId)
          .doc(studentId)
          .collection('subjects')
          .get();
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Calculate percentage
        int markedPeriods = data['markedPeriods'] ?? 0;
        int presentPeriods = data['presentPeriods'] ?? 0;
        double percentage = markedPeriods > 0 
            ? (presentPeriods / markedPeriods * 100) 
            : 0.0;
        
        subjectAttendance.add({
          'subject': data['subject'] ?? doc.id,
          'markedPeriods': markedPeriods,
          'presentPeriods': presentPeriods,
          'percentage': percentage.toStringAsFixed(1)
        });
      }
      
      // Sort by subject name
      subjectAttendance.sort((a, b) => a['subject'].compareTo(b['subject']));
      
    } catch (e) {
      print('Error fetching subject attendance: $e');
    }
    return subjectAttendance;
  }
  
  /// Helper method to get current semester type
  static Future<String> _getSemesterType() async {
    try {
      DocumentSnapshot semesterDoc = await _firestore
          .collection('attendance')
          .doc('current_semester')
          .get();
      
      if (semesterDoc.exists) {
        Map<String, dynamic> data = semesterDoc.data() as Map<String, dynamic>;
        return data['semester'] ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      print('Error getting semester type: $e');
      return 'unknown';
    }
  }
}



