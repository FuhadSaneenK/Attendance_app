import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthResult {
  final bool success;
  final String errorMessage;
  final User? user;

  AuthResult({
    required this.success, 
    this.errorMessage = '', 
    this.user
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Please enter email and password',
        );
      }

      // Attempt to sign in
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Check if user exists and is authenticated
      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;
        
        // Query Firestore to check user role using the auth UID as document ID
        final userDoc = await _firestore
            .collection('users')
            .doc(uid)  // Now using the auth UID as document ID
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          
          // Verify that this user has the expected role
          if (userData != null && userData['role'] == expectedRole) {
            return AuthResult(
              success: true,
              user: userCredential.user,
            );
          } else {
            // User exists but doesn't have the expected role
            await _auth.signOut(); // Sign out the user
            return AuthResult(
              success: false,
              errorMessage: 'Access denied: Not authorized as a $expectedRole',
            );
          }
        } else {
          // User authenticated but not found in Firestore
          await _auth.signOut(); // Sign out the user
          return AuthResult(
            success: false,
            errorMessage: 'User profile not found',
          );
        }
      }
      
      // This should rarely happen as FirebaseAuth usually throws an exception
      return AuthResult(
        success: false,
        errorMessage: 'Login failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'Email not registered';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else {
        errorMessage = 'Authentication failed: ${e.message}';
      }
      
      return AuthResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'An error occurred: $e',
      );
    }
  }

  Future<AuthResult> registerTeacher({
    required String name,
    required String email,
    required String contact,
    required String teacherId,
    required String department,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty || name.isEmpty || 
          contact.isEmpty || teacherId.isEmpty || department.isEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Please fill in all required fields',
        );
      }

      // Check if teacher ID already exists in users or pendingApprovals
      var teacherIdCheckInUsers = await _firestore
          .collection('users')
          .where('teacherId', isEqualTo: teacherId.trim())
          .get();
          
      var teacherIdCheckInPending = await _firestore
          .collection('pendingApprovals')
          .where('teacherId', isEqualTo: teacherId.trim())
          .get();
      
      if (teacherIdCheckInUsers.docs.isNotEmpty || teacherIdCheckInPending.docs.isNotEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Teacher ID already registered or pending approval',
        );
      }

      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // If successful, store additional user data in Firestore pendingApprovals collection
      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;
        
        // Create document in pendingApprovals collection
        await _firestore.collection('pendingApprovals').doc(uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'contact': contact.trim(),
          'teacherId': teacherId.trim(),
          'department': department.trim(),
          'role': 'teacher',
          'submittedAt': FieldValue.serverTimestamp(),
          'status': 'pending', // Can be 'pending', 'approved', 'rejected'
          'uid': uid, // Store the Firebase Auth UID for reference
        });

        return AuthResult(
          success: true,
          user: userCredential.user,
        );
      }
      
      return AuthResult(
        success: false,
        errorMessage: 'Registration failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email already registered';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else {
        errorMessage = 'Registration failed: ${e.message}';
      }
      
      return AuthResult(
        success: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'An error occurred: $e',
      );
    }
  }

  // Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Password reset
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(
        success: true,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false, 
        errorMessage: 'Password reset failed: ${e.message}'
      );
    }
  }
}



// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthResult {
//   final bool success;
//   final String errorMessage;
//   final User? user;

//   AuthResult({
//     required this.success, 
//     this.errorMessage = '', 
//     this.user
//   });
// }

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<AuthResult> signInWithEmailAndPassword({
//     required String email,
//     required String password,
//     required String expectedRole,
//   }) async {
//     try {
//       // Validate inputs
//       if (email.isEmpty || password.isEmpty) {
//         return AuthResult(
//           success: false,
//           errorMessage: 'Please enter email and password',
//         );
//       }

//       // Attempt to sign in
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       // Check if user exists and is authenticated
//       if (userCredential.user != null) {
//         final String uid = userCredential.user!.uid;
        
//         // Query Firestore to check user role using the auth UID as document ID
//         final userDoc = await _firestore
//             .collection('users')
//             .doc(uid)  // Now using the auth UID as document ID
//             .get();
        
//         if (userDoc.exists) {
//           final userData = userDoc.data();
          
//           // Verify that this user has the expected role
//           if (userData != null && userData['role'] == expectedRole) {
//             return AuthResult(
//               success: true,
//               user: userCredential.user,
//             );
//           } else {
//             // User exists but doesn't have the expected role
//             await _auth.signOut(); // Sign out the user
//             return AuthResult(
//               success: false,
//               errorMessage: 'Access denied: Not authorized as a $expectedRole',
//             );
//           }
//         } else {
//           // User authenticated but not found in Firestore
//           await _auth.signOut(); // Sign out the user
//           return AuthResult(
//             success: false,
//             errorMessage: 'User profile not found',
//           );
//         }
//       }
      
//       // This should rarely happen as FirebaseAuth usually throws an exception
//       return AuthResult(
//         success: false,
//         errorMessage: 'Login failed. Please try again.',
//       );
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;
      
//       if (e.code == 'wrong-password') {
//         errorMessage = 'Incorrect password';
//       } else if (e.code == 'user-not-found') {
//         errorMessage = 'Email not registered';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Invalid email format';
//       } else {
//         errorMessage = 'Authentication failed: ${e.message}';
//       }
      
//       return AuthResult(
//         success: false,
//         errorMessage: errorMessage,
//       );
//     } catch (e) {
//       return AuthResult(
//         success: false,
//         errorMessage: 'An error occurred: $e',
//       );
//     }
//   }

//   Future<AuthResult> registerTeacher({
//     required String name,
//     required String email,
//     required String contact,
//     required String teacherId,
//     required String department,
//     required String password,
//   }) async {
//     try {
//       // Validate inputs
//       if (email.isEmpty || password.isEmpty || name.isEmpty || 
//           contact.isEmpty || teacherId.isEmpty || department.isEmpty) {
//         return AuthResult(
//           success: false,
//           errorMessage: 'Please fill in all required fields',
//         );
//       }

//       // Check if teacher ID already exists in users or pendingApprovals
//       var teacherIdCheckInUsers = await _firestore
//           .collection('users')
//           .where('teacherId', isEqualTo: teacherId.trim())
//           .get();
          
//       var teacherIdCheckInPending = await _firestore
//           .collection('pendingApprovals')
//           .where('teacherId', isEqualTo: teacherId.trim())
//           .get();
      
//       if (teacherIdCheckInUsers.docs.isNotEmpty || teacherIdCheckInPending.docs.isNotEmpty) {
//         return AuthResult(
//           success: false,
//           errorMessage: 'Teacher ID already registered or pending approval',
//         );
//       }

//       // Create user with email and password
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       // If successful, store additional user data in Firestore pendingApprovals collection
//       if (userCredential.user != null) {
//         final String uid = userCredential.user!.uid;
        
//         // Create document in pendingApprovals collection
//         await _firestore.collection('pendingApprovals').doc(uid).set({
//           'name': name.trim(),
//           'email': email.trim(),
//           'contact': contact.trim(),
//           'teacherId': teacherId.trim(),
//           'department': department.trim(),
//           'role': 'teacher',
//           'submittedAt': FieldValue.serverTimestamp(),
//           'status': 'pending', // Can be 'pending', 'approved', 'rejected'
//           'uid': uid, // Store the Firebase Auth UID for reference
//         });

//         return AuthResult(
//           success: true,
//           user: userCredential.user,
//         );
//       }
      
//       return AuthResult(
//         success: false,
//         errorMessage: 'Registration failed. Please try again.',
//       );
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;
      
//       if (e.code == 'email-already-in-use') {
//         errorMessage = 'Email already registered';
//       } else if (e.code == 'weak-password') {
//         errorMessage = 'Password is too weak';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Invalid email format';
//       } else {
//         errorMessage = 'Registration failed: ${e.message}';
//       }
      
//       return AuthResult(
//         success: false,
//         errorMessage: errorMessage,
//       );
//     } catch (e) {
//       return AuthResult(
//         success: false,
//         errorMessage: 'An error occurred: $e',
//       );
//     }
//   }

//   // Admin method to approve a teacher
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
      
//       // Extract teacher data from pending document
//       Map<String, dynamic> teacherData = pendingDoc.data() as Map<String, dynamic>;
      
//       // Create approved user in the users collection
//       await _firestore.collection('users').doc(uid).set({
//         'name': teacherData['name'],
//         'email': teacherData['email'],
//         'contact': teacherData['contact'],
//         'teacherId': teacherData['teacherId'],
//         'department': teacherData['department'],
//         'role': 'teacher',
//         'createdAt': FieldValue.serverTimestamp(),
//         'isActive': true,
//       });
      
//       // Update status in pendingApprovals
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
  
//   // Admin method to reject a teacher
//   Future<bool> rejectTeacher(String uid, String reason) async {
//     try {
//       // Update status in pendingApprovals
//       await _firestore.collection('pendingApprovals').doc(uid).update({
//         'status': 'rejected',
//         'rejectionReason': reason,
//         'processedAt': FieldValue.serverTimestamp(),
//       });
      
//       // You might want to delete the Firebase Auth user or leave it for the user to try again
//       // This depends on your application's requirements
      
//       return true;
//     } catch (e) {
//       print('Error rejecting teacher: $e');
//       return false;
//     }
//   }

//   // Sign out current user
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }
  
//   // Password reset
//   Future<AuthResult> resetPassword(String email) async {
//     try {
//       await _auth.sendPasswordResetEmail(email: email.trim());
//       return AuthResult(
//         success: true,
//       );
//     } on FirebaseAuthException catch (e) {
//       return AuthResult(
//         success: false, 
//         errorMessage: 'Password reset failed: ${e.message}'
//       );
//     }
//   }
// }




// normal working authentication
//import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthResult {
//   final bool success;
//   final String errorMessage;
//   final User? user;

//   AuthResult({
//     required this.success, 
//     this.errorMessage = '', 
//     this.user
//   });
// }

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<AuthResult> signInWithEmailAndPassword({
//     required String email,
//     required String password,
//     required String expectedRole,
//   }) async {
//     try {
//       // Validate inputs
//       if (email.isEmpty || password.isEmpty) {
//         return AuthResult(
//           success: false,
//           errorMessage: 'Please enter email and password',
//         );
//       }

//       // Attempt to sign in
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       // Check if user exists and is authenticated
//       if (userCredential.user != null) {
//         final String uid = userCredential.user!.uid;
        
//         // Query Firestore to check user role using the auth UID as document ID
//         final userDoc = await _firestore
//             .collection('users')
//             .doc(uid)  // Now using the auth UID as document ID
//             .get();
        
//         if (userDoc.exists) {
//           final userData = userDoc.data();
          
//           // Verify that this user has the expected role
//           if (userData != null && userData['role'] == expectedRole) {
//             return AuthResult(
//               success: true,
//               user: userCredential.user,
//             );
//           } else {
//             // User exists but doesn't have the expected role
//             await _auth.signOut(); // Sign out the user
//             return AuthResult(
//               success: false,
//               errorMessage: 'Access denied: Not authorized as a $expectedRole',
//             );
//           }
//         } else {
//           // User authenticated but not found in Firestore
//           await _auth.signOut(); // Sign out the user
//           return AuthResult(
//             success: false,
//             errorMessage: 'User profile not found',
//           );
//         }
//       }
      
//       // This should rarely happen as FirebaseAuth usually throws an exception
//       return AuthResult(
//         success: false,
//         errorMessage: 'Login failed. Please try again.',
//       );
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;
      
//       if (e.code == 'wrong-password') {
//         errorMessage = 'Incorrect password';
//       } else if (e.code == 'user-not-found') {
//         errorMessage = 'Email not registered';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Invalid email format';
//       } else {
//         errorMessage = 'Authentication failed: ${e.message}';
//       }
      
//       return AuthResult(
//         success: false,
//         errorMessage: errorMessage,
//       );
//     } catch (e) {
//       return AuthResult(
//         success: false,
//         errorMessage: 'An error occurred: $e',
//       );
//     }
//   }

//   Future<AuthResult> registerTeacher({
//     required String name,
//     required String email,
//     required String contact,
//     required String teacherId,
//     required String department,
//     required String password,
//   }) async {
//     try {
//       // Validate inputs
//       if (email.isEmpty || password.isEmpty || name.isEmpty || 
//           contact.isEmpty || teacherId.isEmpty || department.isEmpty) {
//         return AuthResult(
//           success: false,
//           errorMessage: 'Please fill in all required fields',
//         );
//       }

//       // Check if teacher ID already exists in Firestore
//       final teacherIdCheck = await _firestore
//           .collection('users')
//           .where('teacherId', isEqualTo: teacherId.trim())
//           .get();
      
//       if (teacherIdCheck.docs.isNotEmpty) {
//         return AuthResult(
//           success: false,
//           errorMessage: 'Teacher ID already registered',
//         );
//       }

//       // Create user with email and password
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       // If successful, store additional user data in Firestore
//       if (userCredential.user != null) {
//         final String uid = userCredential.user!.uid;
        
//         // Create user document in Firestore
//         await _firestore.collection('users').doc(uid).set({
//           'name': name.trim(),
//           'email': email.trim(),
//           'contact': contact.trim(),
//           'teacherId': teacherId.trim(),
//           'department': department.trim(),
//           'role': 'teacher',
//           'createdAt': FieldValue.serverTimestamp(),
//           'isActive': true,
//         });

//         return AuthResult(
//           success: true,
//           user: userCredential.user,
//         );
//       }
      
//       return AuthResult(
//         success: false,
//         errorMessage: 'Registration failed. Please try again.',
//       );
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;
      
//       if (e.code == 'email-already-in-use') {
//         errorMessage = 'Email already registered';
//       } else if (e.code == 'weak-password') {
//         errorMessage = 'Password is too weak';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Invalid email format';
//       } else {
//         errorMessage = 'Registration failed: ${e.message}';
//       }
      
//       return AuthResult(
//         success: false,
//         errorMessage: errorMessage,
//       );
//     } catch (e) {
//       return AuthResult(
//         success: false,
//         errorMessage: 'An error occurred: $e',
//       );
//     }
//   }

//   // Sign out current user
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }
  
//   // Password reset
//   Future<AuthResult> resetPassword(String email) async {
//     try {
//       await _auth.sendPasswordResetEmail(email: email.trim());
//       return AuthResult(
//         success: true,
//       );
//     } on FirebaseAuthException catch (e) {
//       return AuthResult(
//         success: false, 
//         errorMessage: 'Password reset failed: ${e.message}'
//       );
//     }
//   }
// }











// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthResult {
//   final bool success;
//   final String errorMessage;
//   final User? user;

//   AuthResult({
//     required this.success, 
//     this.errorMessage = '', 
//     this.user
//   });
// }

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;


// Future<AuthResult> signInWithEmailAndPassword({
//   required String email,
//   required String password,
//   required String expectedRole,
// }) async {
//   try {
//     // Validate inputs
//     if (email.isEmpty || password.isEmpty) {
//       return AuthResult(
//         success: false,
//         errorMessage: 'Please enter email and password',
//       );
//     }

//     // Attempt to sign in
//     UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//       email: email.trim(),
//       password: password.trim(),
//     );

//     // Check if user exists and is authenticated
//     if (userCredential.user != null) {
//       final String uid = userCredential.user!.uid;
      
//       // Query Firestore to check user role using the auth UID as document ID
//       final userDoc = await _firestore
//           .collection('users')
//           .doc(uid)  // Now using the auth UID as document ID
//           .get();
      
//       if (userDoc.exists) {
//         final userData = userDoc.data();
        
//         // Verify that this user has the expected role
//         if (userData != null && userData['role'] == expectedRole) {
//           return AuthResult(
//             success: true,
//             user: userCredential.user,
//           );
//         } else {
//           // User exists but doesn't have the expected role
//           await _auth.signOut(); // Sign out the user
//           return AuthResult(
//             success: false,
//             errorMessage: 'Access denied: Not authorized as a $expectedRole',
//           );
//         }
//       } else {
//         // User authenticated but not found in Firestore
//         await _auth.signOut(); // Sign out the user
//         return AuthResult(
//           success: false,
//           errorMessage: 'User profile not found',
//         );
//       }
//     }
    
//     // This should rarely happen as FirebaseAuth usually throws an exception
//     return AuthResult(
//       success: false,
//       errorMessage: 'Login failed. Please try again.',
//     );
//   } on FirebaseAuthException catch (e) {
//     String errorMessage;
    
//     if (e.code == 'wrong-password') {
//       errorMessage = 'Incorrect password';
//     } else if (e.code == 'user-not-found') {
//       errorMessage = 'Email not registered';
//     } else if (e.code == 'invalid-email') {
//       errorMessage = 'Invalid email format';
//     } else {
//       errorMessage = 'Authentication failed: ${e.message}';
//     }
    
//     return AuthResult(
//       success: false,
//       errorMessage: errorMessage,
//     );
//   } catch (e) {
//     return AuthResult(
//       success: false,
//       errorMessage: 'An error occurred: $e',
//     );
//   }
// }

//   // Sign out current user
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }
  
//   // Password reset
//   Future<AuthResult> resetPassword(String email) async {
//     try {
//       await _auth.sendPasswordResetEmail(email: email.trim());
//       return AuthResult(
//         success: true,
//       );
//     } on FirebaseAuthException catch (e) {
//       return AuthResult(
//         success: false, 
//         errorMessage: 'Password reset failed: ${e.message}'
//       );
//     }
//   }
// }