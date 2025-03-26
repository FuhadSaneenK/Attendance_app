import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch a teacher by their UID
  Future<Map<String, dynamic>?> getTeacherByUid(String uid) async {
    try {
      // First try to get the user document to find the teacherId
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String teacherId = userData['teacherId'] ?? '';
        
        if (teacherId.isNotEmpty) {
          // Try to get the teacher document using teacherId
          DocumentSnapshot teacherDoc = await _firestore
              .collection('teachers')
              .doc(teacherId)
              .get();
              
          if (teacherDoc.exists) {
            return teacherDoc.data() as Map<String, dynamic>;
          }
        }
      }
      
      // Try to get the teacher document directly from the teachers collection using uid
      DocumentSnapshot teacherDoc = await _firestore.collection('teachers').doc(uid).get();
      
      if (teacherDoc.exists) {
        return teacherDoc.data() as Map<String, dynamic>;
      }
      
      // If not found, check if there's a pending approval
      DocumentSnapshot pendingDoc = await _firestore.collection('pendingApprovals').doc(uid).get();
      
      if (pendingDoc.exists) {
        return pendingDoc.data() as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error fetching teacher: $e');
      return null;
    }
  }
  
  // Fetch a teacher by their teacher ID
  Future<Map<String, dynamic>?> getTeacherById(String teacherId) async {
    try {
      // Try to get teacher directly using teacherId as document ID first
      DocumentSnapshot teacherDoc = await _firestore
          .collection('teachers')
          .doc(teacherId)
          .get();
          
      if (teacherDoc.exists) {
        return teacherDoc.data() as Map<String, dynamic>;
      }
      
      // Fallback to query by teacherId field
      QuerySnapshot querySnapshot = await _firestore
          .collection('teachers')
          .where('teacherId', isEqualTo: teacherId)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error fetching teacher by ID: $e');
      return null;
    }
  }
  
  // Get current teacher data
  Future<Map<String, dynamic>?> getCurrentTeacherData() async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        return null;
      }
      
      return await getTeacherByUid(currentUser.uid);
    } catch (e) {
      print('Error getting current teacher data: $e');
      return null;
    }
  }
  
  // Create a new teacher profile
  Future<bool> createTeacherProfile(Map<String, dynamic> teacherData) async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        return false;
      }
      
      // Ensure email is set from current user
      teacherData['email'] = currentUser.email ?? teacherData['email'];
      
      // Add timestamp and uid
      teacherData['createdAt'] = FieldValue.serverTimestamp();
      teacherData['status'] = 'active';
      teacherData['uid'] = currentUser.uid;
      
      // Use teacherId as document ID if available, or fallback to UID
      String docId = teacherData['teacherId'] ?? currentUser.uid;
      
      // Create or update in teachers collection
      await _firestore.collection('teachers').doc(docId).set(teacherData);
      
      // Also create entry in users collection
      await _firestore.collection('users').doc(currentUser.uid).set({
        'name': teacherData['name'],
        'email': teacherData['email'],
        'role': 'teacher',
        'teacherId': teacherData['teacherId'],
        'department': teacherData['department'],
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error creating teacher profile: $e');
      return false;
    }
  }
  
  // Update an existing teacher profile
  Future<bool> updateTeacherProfile(Map<String, dynamic> teacherData) async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        return false;
      }
      
      // Add last updated timestamp
      teacherData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Find the correct document ID to update
      
      // First check if we have a teacherId in the provided data
      String? teacherId = teacherData['teacherId'];
      
      if (teacherId == null || teacherId.isEmpty) {
        // If not, try to get it from the users collection
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          teacherId = userData['teacherId'];
        }
      }
      
      // If we have a teacherId, use it as the document ID
      if (teacherId != null && teacherId.isNotEmpty) {
        // Update in teachers collection
        await _firestore.collection('teachers').doc(teacherId).update(teacherData);
        
        // Also update name and department in users collection if provided
        Map<String, dynamic> userUpdate = {};
        if (teacherData.containsKey('name')) userUpdate['name'] = teacherData['name'];
        if (teacherData.containsKey('department')) userUpdate['department'] = teacherData['department'];
        
        if (userUpdate.isNotEmpty) {
          await _firestore.collection('users').doc(currentUser.uid).update(userUpdate);
        }
        
        return true;
      }
      
      // If no teacherId found, try to update using UID as document ID
      await _firestore.collection('teachers').doc(currentUser.uid).update(teacherData);
      
      return true;
    } catch (e) {
      print('Error updating teacher profile: $e');
      return false;
    }
  }
  
  // Update specific teacher field
  Future<bool> updateTeacherField(String field, dynamic value) async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        return false;
      }
      
      // Create map with field to update
      Map<String, dynamic> updateData = {
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Find the correct document ID to update
      String? teacherId;
      
      // Try to get teacherId from the users collection
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        teacherId = userData['teacherId'];
      }
      
      // If we have a teacherId, use it as the document ID
      if (teacherId != null && teacherId.isNotEmpty) {
        // Update in teachers collection
        await _firestore.collection('teachers').doc(teacherId).update(updateData);
        
        // Also update in users collection if it's name or department
        if (field == 'name' || field == 'department') {
          await _firestore.collection('users').doc(currentUser.uid).update({field: value});
        }
        
        return true;
      }
      
      // If no teacherId found, try to update using UID as document ID
      await _firestore.collection('teachers').doc(currentUser.uid).update(updateData);
      
      return true;
    } catch (e) {
      print('Error updating teacher field: $e');
      return false;
    }
  }
  
  // Get all teachers
  Stream<QuerySnapshot> getAllTeachers() {
    return _firestore
        .collection('teachers')
        .orderBy('name')
        .snapshots();
  }
}







// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class TeacherService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Fetch a teacher by their UID
//   Future<Map<String, dynamic>?> getTeacherByUid(String uid) async {
//     try {
//       // Try to get the teacher document directly from the teachers collection
//       DocumentSnapshot teacherDoc = await _firestore.collection('teachers').doc(uid).get();
      
//       if (teacherDoc.exists) {
//         return teacherDoc.data() as Map<String, dynamic>;
//       }
      
//       // If not found, check if there's a pending approval
//       DocumentSnapshot pendingDoc = await _firestore.collection('pendingApprovals').doc(uid).get();
      
//       if (pendingDoc.exists) {
//         return pendingDoc.data() as Map<String, dynamic>;
//       }
      
//       return null;
//     } catch (e) {
//       print('Error fetching teacher: $e');
//       return null;
//     }
//   }
  
//   // Fetch a teacher by their teacher ID
//   Future<Map<String, dynamic>?> getTeacherById(String teacherId) async {
//     try {
//       QuerySnapshot querySnapshot = await _firestore
//           .collection('teachers')
//           .where('teacherId', isEqualTo: teacherId)
//           .limit(1)
//           .get();
          
//       if (querySnapshot.docs.isNotEmpty) {
//         return querySnapshot.docs.first.data() as Map<String, dynamic>;
//       }
      
//       return null;
//     } catch (e) {
//       print('Error fetching teacher by ID: $e');
//       return null;
//     }
//   }
  
//   // Create a new teacher profile
//   Future<bool> createTeacherProfile(Map<String, dynamic> teacherData) async {
//     try {
//       User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         return false;
//       }
      
//       // Ensure email is set from current user
//       teacherData['email'] = currentUser.email ?? teacherData['email'];
      
//       // Add timestamp
//       teacherData['createdAt'] = FieldValue.serverTimestamp();
//       teacherData['status'] = 'active';
      
//       // Create or update in teachers collection
//       await _firestore.collection('teachers').doc(currentUser.uid).set(teacherData);
      
//       return true;
//     } catch (e) {
//       print('Error creating teacher profile: $e');
//       return false;
//     }
//   }
  
//   // Update an existing teacher profile - with support for updating any field including name
//   Future<bool> updateTeacherProfile(Map<String, dynamic> teacherData) async {
//     try {
//       User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         return false;
//       }
      
//       // Add last updated timestamp
//       teacherData['updatedAt'] = FieldValue.serverTimestamp();
      
//       // Update in teachers collection
//       await _firestore.collection('teachers').doc(currentUser.uid).update(teacherData);
      
//       return true;
//     } catch (e) {
//       print('Error updating teacher profile: $e');
//       return false;
//     }
//   }
  
//   // Update specific teacher field - useful for individual field updates
//   Future<bool> updateTeacherField(String field, dynamic value) async {
//     try {
//       User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         return false;
//       }
      
//       // Create map with field to update
//       Map<String, dynamic> updateData = {
//         field: value,
//         'updatedAt': FieldValue.serverTimestamp(),
//       };
      
//       // Update in teachers collection
//       await _firestore.collection('teachers').doc(currentUser.uid).update(updateData);
      
//       return true;
//     } catch (e) {
//       print('Error updating teacher field: $e');
//       return false;
//     }
//   }
  
//   // Update teacher name
//   Future<bool> updateTeacherName(String name) async {
//     return await updateTeacherField('name', name);
//   }
  
//   // Approve a pending teacher registration
//   Future<bool> approveTeacher(String uid) async {
//     try {
//       // Get the pending approval document
//       DocumentSnapshot pendingDoc = await _firestore
//           .collection('pendingApprovals')
//           .doc(uid)
//           .get();
          
//       if (!pendingDoc.exists) {
//         return false;
//       }
      
//       // Get pending document data
//       Map<String, dynamic> pendingData = pendingDoc.data() as Map<String, dynamic>;
      
//       // Create a new document in the teachers collection
//       await _firestore.collection('teachers').doc(uid).set({
//         ...pendingData,
//         'status': 'active',
//         'approvedAt': FieldValue.serverTimestamp(),
//       });
      
//       // Update the pendingApprovals document
//       await _firestore.collection('pendingApprovals').doc(uid).update({
//         'status': 'approved',
//         'processedAt': FieldValue.serverTimestamp(),
//       });
      
//       return true;
//     } catch (e) {
//       print('Error approving teacher: $e');
//       return false;
//     }
//   }
  
//   // Reject a pending teacher registration
//   Future<bool> rejectTeacher(String uid, String reason) async {
//     try {
//       // Update the pendingApprovals document
//       await _firestore.collection('pendingApprovals').doc(uid).update({
//         'status': 'rejected',
//         'rejectionReason': reason,
//         'processedAt': FieldValue.serverTimestamp(),
//       });
      
//       return true;
//     } catch (e) {
//       print('Error rejecting teacher: $e');
//       return false;
//     }  
//   }
// }


