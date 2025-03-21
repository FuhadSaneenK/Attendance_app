import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  
  // Add a new teacher to the pending approvals
  // Future<bool> addTeacherToPendingApprovals({
  //   required String name,
  //   required String email,
  //   required String contact,
  //   required String teacherId,
  //   required String department,
  //   required String position,
  // }) async {
  //   try {
  //     // First check if teacherId already exists
  //     var teacherIdCheck = await _firestore
  //         .collection('teachers')
  //         .where('teacherId', isEqualTo: teacherId)
  //         .get();
          
  //     var pendingCheck = await _firestore
  //         .collection('pendingApprovals')
  //         .where('teacherId', isEqualTo: teacherId)
  //         .get();
          
  //     if (teacherIdCheck.docs.isNotEmpty || pendingCheck.docs.isNotEmpty) {
  //       return false; // Teacher ID already exists
  //     }
      
  //     // Generate a unique document ID
  //     String docId = _firestore.collection('pendingApprovals').doc().id;
      
  //     // Add to pending approvals
  //     await _firestore.collection('pendingApprovals').doc(docId).set({
  //       'name': name,
  //       'email': email,
  //       'contact': contact,
  //       'teacherId': teacherId,
  //       'department': department,
  //       'position': position,
  //       'status': 'pending',
  //       'submittedAt': FieldValue.serverTimestamp(),
  //       'uid': docId
  //     });
      
  //     return true;
  //   } catch (e) {
  //     print('Error adding teacher to pending approvals: $e');
  //     return false;
  //   }
  // }
  
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
      'uid': teacherId // Store teacherId as the UID for reference
    });
    
    return true;
  } catch (e) {
    print('Error adding teacher to pending approvals: $e');
    return false;
  }
}

  
  // Method to approve a teacher
  Future<bool> approveTeacher(String uid) async {
    try {
      // Get the pending approval document
      DocumentSnapshot pendingDoc = await _firestore
          .collection('pendingApprovals')
          .doc(uid)
          .get();
          
      if (!pendingDoc.exists) {
        return false;
      }
      
      // Extract teacher data
      Map<String, dynamic> teacherData = pendingDoc.data() as Map<String, dynamic>;
      
      // Get the teacher ID to use as document ID
      String teacherId = teacherData['teacherId'] as String;
      
      // Verify teacher ID is not empty
      if (teacherId.isEmpty) {
        print('Error: Teacher ID is empty');
        return false;
      }
      
      // Create a batch write to ensure atomicity
      WriteBatch batch = _firestore.batch();
      
      // 1. Create user entry in the users collection (using auth UID)
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      batch.set(userRef, {
        'name': teacherData['name'],
        'email': teacherData['email'],
        'role': 'teacher',
        'teacherId': teacherId,
        'department': teacherData['department'],
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      });
      
      // 2. Create teacher entry in the teachers collection using teacherId as document ID
      DocumentReference teacherRef = _firestore.collection('teachers').doc(teacherId);
      batch.set(teacherRef, {
        'name': teacherData['name'],
        'email': teacherData['email'],
        'contact': teacherData['contact'],
        'teacherId': teacherId,
        'department': teacherData['department'],
        'position': teacherData['position'] ?? 'Teacher', // Default if not provided
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'uid': uid // Store auth UID for reference
      });
      
      // 3. Update the pending approval status
      DocumentReference pendingRef = _firestore.collection('pendingApprovals').doc(uid);
      batch.update(pendingRef, {
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp()
      });
      
      // Commit the batch
      await batch.commit();
      
      return true;
    } catch (e) {
      print('Error approving teacher: $e');
      return false;
    }
  }

  // Method to reject a teacher
  Future<bool> rejectTeacher(String uid, String reason) async {
    try {
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
      // Create a batch write
      WriteBatch batch = _firestore.batch();
      
      // Delete from teachers collection
      DocumentReference teacherRef = _firestore.collection('teachers').doc(uid);
      batch.delete(teacherRef);
      
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

