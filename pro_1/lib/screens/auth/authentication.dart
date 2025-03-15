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