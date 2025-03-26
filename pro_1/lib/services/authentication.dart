import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    clientId: kIsWeb ? '750053333393-fnbv8q7ikrj4u6sseoau3uu93rr07j9v.apps.googleusercontent.com' : null,
  );

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
            .doc(uid)
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

  // Updated Google Sign-In method that checks for approved teachers
  Future<AuthResult> signInWithGoogle({
    required String expectedRole,
    String? teacherId,
  }) async {
    try {
      // Validate teacher ID for teacher role
      if (expectedRole == 'teacher' && (teacherId == null || teacherId.isEmpty)) {
        return AuthResult(
          success: false,
          errorMessage: 'Teacher ID is required for faculty login',
        );
      }
      
      // First, check if the teacher ID exists in approved teachers
      if (expectedRole == 'teacher' && teacherId != null) {
        // Check if teacher ID exists in users collection
        var teacherQuery = await _firestore
          .collection('users')
          .where('teacherId', isEqualTo: teacherId.trim())
          .where('role', isEqualTo: 'teacher')
          .where('isActive', isEqualTo: true)
          .get();
          
        // If no approved teacher found with this ID, don't allow Google sign-in
        if (teacherQuery.docs.isEmpty) {
          return AuthResult(
            success: false,
            errorMessage: 'No approved teacher account found with this ID. Please register manually first.',
          );
        }
        
        // Check if the teacher account was registered with email/password method
        var teacherData = teacherQuery.docs.first.data();
        if (teacherData['authProvider'] != 'email') {
          return AuthResult(
            success: false,
            errorMessage: 'Google sign-in is only available for teachers who registered with email and password.',
          );
        }
        
        // Store the teacher email for verification later
        String teacherEmail = teacherData['email'];
        
        // Proceed with Google sign-in
        UserCredential? userCredential;
        User? user;
        
        if (kIsWeb) {
          // Web-specific implementation
          GoogleAuthProvider googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          googleProvider.addScope('profile');
          
          googleProvider.setCustomParameters({
            'prompt': 'select_account'
          });
          
          userCredential = await _auth.signInWithPopup(googleProvider);
          user = userCredential.user;
        } else {
          // Mobile implementation
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          
          if (googleUser == null) {
            return AuthResult(
              success: false,
              errorMessage: 'Google sign-in was canceled',
            );
          }

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          userCredential = await _auth.signInWithCredential(credential);
          user = userCredential.user;
        }
        
        // Verify that the Google email matches the registered teacher email
        if (user != null && user.email != teacherEmail) {
          await _auth.signOut();
          if (!kIsWeb) {
            await _googleSignIn.signOut();
          }
          
          return AuthResult(
            success: false,
            errorMessage: 'The Google account email does not match your registered teacher email.',
          );
        }
        
        // User successfully authenticated, link accounts if not already linked
        if (user != null) {
          // Update the user record to reflect Google auth provider as well
          await _firestore.collection('users').doc(user.uid).update({
            'authProvider': 'email_google', // Indicate both methods are available
            'photoURL': user.photoURL,
            'lastSignIn': FieldValue.serverTimestamp(),
          });
          
          return AuthResult(
            success: true,
            user: user,
          );
        }
      } else if (expectedRole != 'teacher') {
        // For non-teacher roles, we'll keep the original Google sign-in implementation
        UserCredential? userCredential;
        User? user;
        
        if (kIsWeb) {
          GoogleAuthProvider googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          googleProvider.addScope('profile');
          
          googleProvider.setCustomParameters({
            'prompt': 'select_account'
          });
          
          userCredential = await _auth.signInWithPopup(googleProvider);
          user = userCredential.user;
        } else {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          
          if (googleUser == null) {
            return AuthResult(
              success: false,
              errorMessage: 'Google sign-in was canceled',
            );
          }

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          userCredential = await _auth.signInWithCredential(credential);
          user = userCredential.user;
        }
        
        // Check if sign-in was successful
        if (user != null) {
          // Check if user exists in Firestore
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          
          // If user doesn't exist in Firestore yet
          if (!userDoc.exists) {
            // For non-teacher roles, create the user record directly
            await _firestore.collection('users').doc(user.uid).set({
              'name': user.displayName ?? '',
              'email': user.email ?? '',
              'role': expectedRole,
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
              'authProvider': 'google',
              'photoURL': user.photoURL,
            });
            
            return AuthResult(
              success: true,
              user: user,
            );
          } else {
            // User exists, check role
            Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
            
            if (userData != null && userData['role'] == expectedRole) {
              return AuthResult(
                success: true,
                user: user,
              );
            } else {
              // User exists but doesn't have the expected role
              await _auth.signOut();
              if (!kIsWeb) {
                await _googleSignIn.signOut();
              }
              
              return AuthResult(
                success: false,
                errorMessage: 'Access denied: Not authorized as a $expectedRole',
              );
            }
          }
        }
      }
      
      // Default fallback for unsuccessful sign-in
      return AuthResult(
        success: false,
        errorMessage: 'Google sign-in failed. Please try again.',
      );
    } catch (e) {
      print('Google Sign In Error: $e');
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
          'authProvider': 'email',
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

  // Sign out current user with platform-specific handling
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
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
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

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
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: [
//       'email',
//       'profile',
//     ],
//     clientId: kIsWeb ? '750053333393-fnbv8q7ikrj4u6sseoau3uu93rr07j9v.apps.googleusercontent.com' : null,
//   );

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
//             .doc(uid)
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

//   // Updated Google Sign-In method with teacherId parameter
//   Future<AuthResult> signInWithGoogle({
//     required String expectedRole,
//     String? teacherId,
//   }) async {
//     try {
//       // Validate teacher ID if provided for teacher role
//       if (expectedRole == 'teacher' && (teacherId == null || teacherId.isEmpty)) {
//         return AuthResult(
//           success: false,
//           errorMessage: 'Teacher ID is required for faculty registration',
//         );
//       }
      
//       UserCredential? userCredential;
//       User? user;
      
//       if (kIsWeb) {
//         // Web-specific implementation
//         GoogleAuthProvider googleProvider = GoogleAuthProvider();
//         googleProvider.addScope('email');
//         googleProvider.addScope('profile');
        
//         // Optional: You can customize the sign-in flow for web
//         googleProvider.setCustomParameters({
//           'prompt': 'select_account'
//         });
        
//         // Use popup for better UX (stays on the same page)
//         userCredential = await _auth.signInWithPopup(googleProvider);
//         user = userCredential.user;
//       } else {
//         // Mobile implementation
//         final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
//         if (googleUser == null) {
//           // User canceled the sign-in flow
//           return AuthResult(
//             success: false,
//             errorMessage: 'Google sign-in was canceled',
//           );
//         }

//         // Obtain auth details from request
//         final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
//         // Create new credential for Firebase
//         final credential = GoogleAuthProvider.credential(
//           accessToken: googleAuth.accessToken,
//           idToken: googleAuth.idToken,
//         );

//         // Sign in with credential
//         userCredential = await _auth.signInWithCredential(credential);
//         user = userCredential.user;
//       }
      
//       // Check if sign-in was successful
//       if (user != null) {
//         // Check if user exists in Firestore
//         DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
//         // If user doesn't exist in Firestore yet
//         if (!userDoc.exists) {
//           // Check if the teacher ID already exists (for teachers only)
//           if (expectedRole == 'teacher' && teacherId != null && teacherId.isNotEmpty) {
//             var teacherIdCheck = await _firestore
//                 .collection('teachers')
//                 .where('teacherId', isEqualTo: teacherId)
//                 .get();
                
//             var pendingCheck = await _firestore
//                 .collection('pendingApprovals')
//                 .where('teacherId', isEqualTo: teacherId)
//                 .get();
                
//             if (teacherIdCheck.docs.isNotEmpty || pendingCheck.docs.isNotEmpty) {
//               // Sign out as the teacherId is already taken
//               await _auth.signOut();
//               if (!kIsWeb) {
//                 await _googleSignIn.signOut();
//               }
              
//               return AuthResult(
//                 success: false,
//                 errorMessage: 'Teacher ID already registered or pending approval',
//               );
//             }
//           }
          
//           // Now check if the Google email matches any teachers in pendingApprovals
//           var pendingTeachers = await _firestore
//               .collection('pendingApprovals')
//               .where('email', isEqualTo: user.email)
//               .get();
              
//           if (pendingTeachers.docs.isNotEmpty) {
//             // Teacher found in pending approvals with same email, update their auth method
//             var teacherData = pendingTeachers.docs.first.data();
            
//             // User already has a pending approval, update it with the new auth info
//             await _firestore.collection('pendingApprovals').doc(user.uid).set({
//               'name': user.displayName ?? teacherData['name'],
//               'email': user.email,
//               'teacherId': teacherData['teacherId'] ?? teacherId,
//               'department': teacherData['department'] ?? '',
//               'position': teacherData['position'] ?? 'Teacher',
//               'role': expectedRole,
//               'submittedAt': FieldValue.serverTimestamp(),
//               'status': 'pending',
//               'uid': user.uid,
//               'photoURL': user.photoURL,
//               'authProvider': 'google',
//             });
            
//             // Sign out as the user needs approval first
//             await _auth.signOut();
//             if (!kIsWeb) {
//               await _googleSignIn.signOut();
//             }
            
//             return AuthResult(
//               success: false,
//               errorMessage: 'Your account requires approval. An administrator will review your request.',
//             );
//           } else {
//             // No matching email in pending approvals, create a new record with the teacherId
//             if (expectedRole == 'teacher') {
//               // Create a new pending approval for teacher
//               await _firestore.collection('pendingApprovals').doc(user.uid).set({
//                 'name': user.displayName ?? '',
//                 'email': user.email ?? '',
//                 'contact': '',  // Empty contact field
//                 'teacherId': teacherId ?? '',  // Use provided teacherId
//                 'department': '',  // Empty department field
//                 'position': 'Teacher',  // Default position
//                 'role': expectedRole,
//                 'submittedAt': FieldValue.serverTimestamp(),
//                 'status': 'pending',
//                 'uid': user.uid,
//                 'photoURL': user.photoURL,
//                 'authProvider': 'google',
//               });
              
//               // Sign out as the user needs approval first
//               await _auth.signOut();
//               if (!kIsWeb) {
//                 await _googleSignIn.signOut();
//               }
              
//               return AuthResult(
//                 success: false,
//                 errorMessage: 'Your account requires approval. An administrator will review your request.',
//               );
//             } else {
//               // For non-teacher roles, create the user record directly
//               await _firestore.collection('users').doc(user.uid).set({
//                 'name': user.displayName ?? '',
//                 'email': user.email ?? '',
//                 'role': expectedRole,
//                 'createdAt': FieldValue.serverTimestamp(),
//                 'isActive': true,
//                 'authProvider': 'google',
//                 'photoURL': user.photoURL,
//               });
              
//               return AuthResult(
//                 success: true,
//                 user: user,
//               );
//             }
//           }
//         } else {
//           // User exists, check role
//           Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
          
//           if (userData != null && userData['role'] == expectedRole) {
//             return AuthResult(
//               success: true,
//               user: user,
//             );
//           } else {
//             // User exists but doesn't have the expected role
//             await _auth.signOut();
//             if (!kIsWeb) {
//               await _googleSignIn.signOut();
//             }
            
//             return AuthResult(
//               success: false,
//               errorMessage: 'Access denied: Not authorized as a $expectedRole',
//             );
//           }
//         }
//       }
      
//       // Default fallback for unsuccessful sign-in
//       return AuthResult(
//         success: false,
//         errorMessage: 'Google sign-in failed. Please try again.',
//       );
//     } catch (e) {
//       print('Google Sign In Error: $e');
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
//           'authProvider': 'email',
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

//   // Sign out current user with platform-specific handling
//   Future<void> signOut() async {
//     if (!kIsWeb) {
//       await _googleSignIn.signOut();
//     }
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

