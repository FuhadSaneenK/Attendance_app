import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String studentId;
  final String classId;
  final String subject;
  final String period;
  final DateTime date;
  final bool isPresent;
  final Timestamp createdAt;
  final String teacherId;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subject,
    required this.period,
    required this.date,
    required this.isPresent,
    required this.createdAt,
    required this.teacherId,
  });

  // Convert AttendanceRecord to a Map for Firestore
  // Map<String, dynamic> toMap() {
  //   return {
  //     'id': id,
  //     'studentId': studentId,
  //     'classId': classId,
  //     'subject': subject,
  //     'period': period,
  //     'date': date,
  //     'isPresent': isPresent,
  //     'createdAt': createdAt,
  //     'teacherId': teacherId,
  //   };
  // }
  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'studentId': studentId,
    'classId': classId,
    'subject': subject,
    'period': period,
    'date': Timestamp.fromDate(date),  // Convert DateTime to Timestamp
    'isPresent': isPresent,
    'createdAt': createdAt,
    'teacherId': teacherId,
  };
}

  // Create AttendanceRecord from Firestore document
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      studentId: map['studentId'],
      classId: map['classId'],
      subject: map['subject'],
      period: map['period'],
      date: (map['date'] as Timestamp).toDate(),
      isPresent: map['isPresent'],
      createdAt: map['createdAt'],
      teacherId: map['teacherId'],
    );
  }
}