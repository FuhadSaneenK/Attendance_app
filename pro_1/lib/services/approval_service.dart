import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get pending teacher approvals
  Stream<QuerySnapshot> getPendingTeachers() {
    return _firestore
        .collection('pendingApprovals')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
  
  // Get approved teacher count today
  Future<int> getApprovedTodayCount() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final querySnapshot = await _firestore
        .collection('pendingApprovals')
        .where('status', isEqualTo: 'approved')
        .where('processedAt', isGreaterThanOrEqualTo: today)
        .get();
        
    return querySnapshot.docs.length;
  }
  
  // Get rejected teacher count today
  Future<int> getRejectedTodayCount() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final querySnapshot = await _firestore
        .collection('pendingApprovals')
        .where('status', isEqualTo: 'rejected')
        .where('processedAt', isGreaterThanOrEqualTo: today)
        .get();
        
    return querySnapshot.docs.length;
  }
  
  // Get all teachers (for teacher listing)
  Stream<QuerySnapshot> getAllTeachers() {
    return _firestore
        .collection('teachers')
        .orderBy('name')
        .snapshots();
  }
  
  // Get teacher details by UID
  Future<DocumentSnapshot> getTeacherDetails(String uid) {
    return _firestore
        .collection('teachers')
        .doc(uid)
        .get();
  }
  
  // Add a new teacher to the pending approvals using teacherId as document ID
  Future<bool> addTeacherToPendingApprovals({
    required String name,
    required String email,
    required String contact,
    required String teacherId,
    required String department,
    required String position,
  }) async {
    try {
      // First check if teacherId already exists
      var teacherIdCheck = await _firestore
          .collection('teachers')
          .where('teacherId', isEqualTo: teacherId)
          .get();
          
      var pendingCheck = await _firestore
          .collection('pendingApprovals')
          .where('teacherId', isEqualTo: teacherId)
          .get();
          
      if (teacherIdCheck.docs.isNotEmpty || pendingCheck.docs.isNotEmpty) {
        return false; // Teacher ID already exists
      }
      
      // Instead of generating a document ID, use the teacherId as the document ID
      await _firestore.collection('pendingApprovals').doc(teacherId).set({
        'name': name,
        'email': email,
        'contact': contact,
        'teacherId': teacherId,
        'department': department,
        'position': position,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'uid': teacherId, // Store teacherId as the UID for reference
        'authProvider': 'email' // Default auth provider
      });
      
      return true;
    } catch (e) {
      print('Error adding teacher to pending approvals: $e');
      return false;
    }
  }

  // Method to approve a teacher - Fixed to properly handle document references
  Future<bool> approveTeacher(String uid) async {
    try {
      print('Approving teacher with UID: $uid');
      
      // Get the pending approval document
      DocumentSnapshot pendingDoc = await _firestore
          .collection('pendingApprovals')
          .doc(uid)
          .get();
          
      if (!pendingDoc.exists) {
        print('Pending document does not exist for UID: $uid');
        return false;
      }
      
      // Extract teacher data
      Map<String, dynamic> teacherData = pendingDoc.data() as Map<String, dynamic>;
      print('Teacher data retrieved: ${teacherData.toString()}');
      
      // Get the teacher ID from the teacher data
      String teacherId = teacherData['teacherId'] as String;
      
      if (teacherId.isEmpty) {
        print('Error: Teacher ID is empty');
        return false;
      }
      
      // Check auth provider
      String authProvider = teacherData['authProvider'] ?? 'email';
      print('Auth provider: $authProvider');
      
      // Create a batch write
      WriteBatch batch = _firestore.batch();
      
      // Store user data - Using the UID from the pending approval document
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      Map<String, dynamic> userData = {
        'name': teacherData['name'],
        'email': teacherData['email'],
        'role': 'teacher',
        'teacherId': teacherId,
        'department': teacherData['department'],
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'authProvider': authProvider
      };
      
      if (authProvider == 'google' && teacherData.containsKey('photoURL')) {
        userData['photoURL'] = teacherData['photoURL'];
      }
      
      batch.set(userRef, userData);
      print('Creating user document for UID: $uid');
      
      // Create teacher entry - Using teacherId as the document ID
      DocumentReference teacherRef = _firestore.collection('teachers').doc(teacherId);
      Map<String, dynamic> teacherRecord = {
        'name': teacherData['name'],
        'email': teacherData['email'],
        'contact': teacherData['contact'] ?? '',
        'teacherId': teacherId,
        'department': teacherData['department'],
        'position': teacherData['position'] ?? 'Teacher',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'uid': uid,  // Store the actual UID from Firebase Auth
        'authProvider': authProvider
      };
      
      if (authProvider == 'google' && teacherData.containsKey('photoURL')) {
        teacherRecord['photoURL'] = teacherData['photoURL'];
      }
      
      batch.set(teacherRef, teacherRecord);
      print('Creating teacher document with ID: $teacherId');
      
      // Update pending approval status - using the same document reference
      batch.update(pendingDoc.reference, {
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp()
      });
      print('Updating pending approval status for UID: $uid');
      
      // Commit the batch
      await batch.commit();
      print('Batch committed successfully');
      
      return true;
    } catch (e) {
      print('Error approving teacher: $e');
      return false;
    }
  }
  
  // Method to reject a teacher
  Future<bool> rejectTeacher(String uid, String reason) async {
    try {
      print('Rejecting teacher with UID: $uid, reason: $reason');
      // Update the pending approval
      await _firestore.collection('pendingApprovals').doc(uid).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp()
      });
      
      return true;
    } catch (e) {
      print('Error rejecting teacher: $e');
      return false;
    }
  }
  
  // Method to update teacher information
  Future<bool> updateTeacher(String uid, Map<String, dynamic> data) async {
    try {
      // Create a batch write
      WriteBatch batch = _firestore.batch();
      
      // Update in teachers collection
      DocumentReference teacherRef = _firestore.collection('teachers').doc(uid);
      batch.update(teacherRef, data);
      
      // Update relevant fields in users collection
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      Map<String, dynamic> userData = {};
      
      // Only update specific fields in the users collection
      if (data.containsKey('name')) userData['name'] = data['name'];
      if (data.containsKey('email')) userData['email'] = data['email'];
      if (data.containsKey('department')) userData['department'] = data['department'];
      if (data.containsKey('isActive')) userData['isActive'] = data['isActive'];
      if (data.containsKey('photoURL')) userData['photoURL'] = data['photoURL'];
      
      if (userData.isNotEmpty) {
        batch.update(userRef, userData);
      }
      
      // Commit the batch
      await batch.commit();
      
      return true;
    } catch (e) {
      print('Error updating teacher: $e');
      return false;
    }
  }
  
  // Method to delete a teacher
  Future<bool> deleteTeacher(String uid) async {
    try {
      // Get the auth provider for this teacher to handle sign-out properly
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      String authProvider = 'email';
      String teacherId = '';
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        authProvider = userData['authProvider'] ?? 'email';
        teacherId = userData['teacherId'] ?? '';
      }
      
      // Create a batch write
      WriteBatch batch = _firestore.batch();
      
      // Delete from teachers collection if teacherId is available
      if (teacherId.isNotEmpty) {
        DocumentReference teacherRef = _firestore.collection('teachers').doc(teacherId);
        batch.delete(teacherRef);
      }
      
      // Delete from users collection
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      batch.delete(userRef);
      
      // Commit the batch
      await batch.commit();
      
      return true;
    } catch (e) {
      print('Error deleting teacher: $e');
      return false;
    }
  }
}

