import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  // Firebase instances
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters to access instances
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseAuth get auth => _auth;

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Get current user ID (teacher ID in this case)
  static String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  static bool get isUserLoggedIn => _auth.currentUser != null;
}