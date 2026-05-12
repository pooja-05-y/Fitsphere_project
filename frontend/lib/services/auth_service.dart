import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save profile to Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'weight': 70,
        'height': 175,
        'age': 25,
        'gender': 'Not specified',
        'goal': 'Stay Fit',
        'stepGoal': 10000,
      });
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Forgot password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    final doc = await _db
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    return doc.data();
  }

  // Save profile
  Future<void> saveProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser!.uid)
        .update(data);
  }

  // Save goals
  Future<void> saveGoals(Map<String, dynamic> goals) async {
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('goals')
        .doc('daily')
        .set(goals, SetOptions(merge: true));
  }

  // Log mood
  Future<void> logMood(String mood) async {
    if (currentUser == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('mood_logs')
        .doc(today)
        .set({
      'mood': mood,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Log meal
  Future<void> logMeal(Map<String, dynamic> meal) async {
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('meals')
        .add({
      ...meal,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Log workout
  Future<void> logWorkout(Map<String, dynamic> workout) async {
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('workouts')
        .add({
      ...workout,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Save daily steps
  Future<void> saveSteps(int steps) async {
    if (currentUser == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _db
        .collection('users')
        .doc(currentUser!.uid)
        .collection('fitness')
        .doc(today)
        .set({
      'steps': steps,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}