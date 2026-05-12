import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class FirebaseService extends ChangeNotifier {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth state ────────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String get uid => _auth.currentUser?.uid ?? '';

  // ── Local cache (instant UI updates) ─────────────────────────────────────
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _goals = {};
  List<Map<String, dynamic>> _meals = [];
  List<Map<String, dynamic>> _moods = [];
  List<Map<String, dynamic>> _workouts = [];
  Map<String, dynamic> _notifSettings = {};
  Map<String, dynamic> _fitnessData = {};

  // ── Getters ───────────────────────────────────────────────────────────────
  Map<String, dynamic> get profile => _profile;
  Map<String, dynamic> get goals => _goals;
  List<Map<String, dynamic>> get meals => List.unmodifiable(_meals);
  List<Map<String, dynamic>> get moods => List.unmodifiable(_moods);
  List<Map<String, dynamic>> get workouts => List.unmodifiable(_workouts);
  Map<String, dynamic> get notifSettings => _notifSettings;
  Map<String, dynamic> get fitnessData => _fitnessData;

  String get name => _profile['name'] ?? 'User';
  String get email => _profile['email'] ?? '';
  String get phone => _profile['phone'] ?? '';
  int get age => _profile['age'] ?? 25;
  double get weight => (_profile['weight'] ?? 70).toDouble();
  double get height => (_profile['height'] ?? 175).toDouble();
  String get gender => _profile['gender'] ?? 'Not specified';
  String get primaryGoal => _profile['primaryGoal'] ?? 'Stay Fit';

  double get stepGoal => (_goals['stepGoal'] ?? 10000).toDouble();
  double get calorieGoal => (_goals['calorieGoal'] ?? 2000).toDouble();
  double get waterGoal => (_goals['waterGoal'] ?? 8).toDouble();
  double get workoutsGoal => (_goals['workoutsGoal'] ?? 5).toDouble();
  double get sleepGoal => (_goals['sleepGoal'] ?? 8).toDouble();

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  String get _timeNow {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}';
  }

  List<Map<String, dynamic>> get todayMeals =>
      _meals.where((m) => m['date'] == _today).toList();

  double get totalCaloriesToday => todayMeals.fold(
      0.0, (sum, m) => sum + (m['calories'] as num).toDouble());

  int get workoutsThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _workouts.where((w) {
      final d = DateTime.tryParse(w['date'] ?? '');
      return d != null && !d.isBefore(weekStart);
    }).length;
  }

  // ── Listeners ─────────────────────────────────────────────────────────────
  StreamSubscription? _profileSub;
  StreamSubscription? _goalsSub;
  StreamSubscription? _mealsSub;
  StreamSubscription? _moodsSub;
  StreamSubscription? _workoutsSub;
  StreamSubscription? _notifSub;
  StreamSubscription? _fitnessSub;

  // ── Init: start listening to Firestore streams ─────────────────────────────
  void startListening() {
    if (uid.isEmpty) return;
    final userDoc = _db.collection('users').doc(uid);

    // Profile — live stream
    _profileSub = userDoc.snapshots().listen((snap) {
      if (snap.exists) {
        _profile = snap.data() ?? {};
        notifyListeners();
      }
    });

    // Goals — live stream
    _goalsSub = userDoc.collection('goals').doc('daily').snapshots().listen((snap) {
      if (snap.exists) {
        _goals = snap.data() ?? {};
        notifyListeners();
      }
    });

    // Meals — live stream ordered by time
    _mealsSub = userDoc
        .collection('meals')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
      _meals = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      notifyListeners();
    });

    // Moods — live stream
    _moodsSub = userDoc
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      _moods = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      notifyListeners();
    });

    // Workouts — live stream
    _workoutsSub = userDoc
        .collection('workouts')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      _workouts = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      notifyListeners();
    });

    // Notification settings
    _notifSub = userDoc
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        _notifSettings = snap.data() ?? {};
        notifyListeners();
      }
    });

    // Fitness (steps) — today's doc
    _fitnessSub = userDoc
        .collection('fitness')
        .doc(_today)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        _fitnessData = snap.data() ?? {};
        notifyListeners();
      }
    });
  }

  void stopListening() {
    _profileSub?.cancel();
    _goalsSub?.cancel();
    _mealsSub?.cancel();
    _moodsSub?.cancel();
    _workoutsSub?.cancel();
    _notifSub?.cancel();
    _fitnessSub?.cancel();
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      // Create profile doc
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'phone': '',
        'age': 25,
        'weight': 70.0,
        'height': 175.0,
        'gender': 'Not specified',
        'primaryGoal': 'Stay Fit',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Create default goals
      await _db
          .collection('users')
          .doc(cred.user!.uid)
          .collection('goals')
          .doc('daily')
          .set({
        'stepGoal': 10000,
        'calorieGoal': 2000,
        'waterGoal': 8,
        'workoutsGoal': 5,
        'sleepGoal': 8,
      });
      // Create default notification settings
      await _db
          .collection('users')
          .doc(cred.user!.uid)
          .collection('settings')
          .doc('notifications')
          .set({
        'workoutReminders': true,
        'waterIntake': true,
        'meditationSessions': false,
        'dailyGoals': true,
      });
      startListening();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      startListening();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    stopListening();
    _profile = {};
    _goals = {};
    _meals = [];
    _moods = [];
    _workouts = [];
    await _auth.signOut();
    notifyListeners();
  }

  // ── PROFILE ───────────────────────────────────────────────────────────────

  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String goal,
  }) async {
    if (uid.isEmpty) return;
    // Update local cache instantly
    _profile = {
      ..._profile,
      'name': name, 'email': email, 'phone': phone,
      'age': age, 'weight': weight, 'height': height,
      'gender': gender, 'primaryGoal': goal,
    };
    notifyListeners();
    // Save to Firestore
    await _db.collection('users').doc(uid).update({
      'name': name, 'email': email, 'phone': phone,
      'age': age, 'weight': weight, 'height': height,
      'gender': gender, 'primaryGoal': goal,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── GOALS ─────────────────────────────────────────────────────────────────

  Future<void> saveGoals({
    required double steps,
    required double calories,
    required double water,
    required double workoutsPerWeek,
    required double sleep,
  }) async {
    if (uid.isEmpty) return;
    final data = {
      'stepGoal': steps, 'calorieGoal': calories, 'waterGoal': water,
      'workoutsGoal': workoutsPerWeek, 'sleepGoal': sleep,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Update local instantly
    _goals = {..._goals, ...data};
    notifyListeners();
    // Save to Firestore
    await _db.collection('users').doc(uid)
        .collection('goals').doc('daily')
        .set(data, SetOptions(merge: true));
  }

  // ── MEALS ─────────────────────────────────────────────────────────────────

  Future<void> logMeal({
    required String type,
    required String foodName,
    required double calories,
  }) async {
    if (uid.isEmpty) return;
    final data = {
      'type': type,
      'name': foodName,
      'calories': calories,
      'date': _today,
      'time': _timeNow,
      'timestamp': FieldValue.serverTimestamp(),
    };
    // Add to local cache instantly
    _meals.insert(0, {'id': 'temp_${DateTime.now().millisecondsSinceEpoch}', ...data});
    notifyListeners();
    // Save to Firestore
    await _db.collection('users').doc(uid).collection('meals').add(data);
  }

  Future<void> deleteMeal(String mealId) async {
    if (uid.isEmpty) return;
    // Remove from local instantly
    _meals.removeWhere((m) => m['id'] == mealId);
    notifyListeners();
    // Delete from Firestore
    await _db.collection('users').doc(uid)
        .collection('meals').doc(mealId).delete();
  }

  // ── MOODS ─────────────────────────────────────────────────────────────────

  Future<void> logMood(String emoji, String label) async {
    if (uid.isEmpty) return;
    final data = {
      'emoji': emoji,
      'label': label,
      'date': _today,
      'time': _timeNow,
      'timestamp': FieldValue.serverTimestamp(),
    };
    // Add to local instantly
    _moods.insert(0, {'id': 'temp_${DateTime.now().millisecondsSinceEpoch}', ...data});
    notifyListeners();
    // Save to Firestore
    await _db.collection('users').doc(uid).collection('moods').add(data);
  }

  Future<void> deleteMood(String moodId) async {
    if (uid.isEmpty) return;
    _moods.removeWhere((m) => m['id'] == moodId);
    notifyListeners();
    await _db.collection('users').doc(uid)
        .collection('moods').doc(moodId).delete();
  }

  Future<void> clearMoods() async {
    if (uid.isEmpty) return;
    _moods = [];
    notifyListeners();
    final batch = _db.batch();
    final docs = await _db.collection('users').doc(uid)
        .collection('moods').get();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── WORKOUTS ──────────────────────────────────────────────────────────────

  Future<void> logWorkout({
    required String type,
    required int durationMinutes,
    required int caloriesBurned,
  }) async {
    if (uid.isEmpty) return;
    final data = {
      'type': type,
      'duration': durationMinutes,
      'calories': caloriesBurned,
      'date': _today,
      'time': _timeNow,
      'timestamp': FieldValue.serverTimestamp(),
    };
    _workouts.insert(0, {'id': 'temp_${DateTime.now().millisecondsSinceEpoch}', ...data});
    notifyListeners();
    await _db.collection('users').doc(uid).collection('workouts').add(data);
  }

  // ── FITNESS / STEPS ───────────────────────────────────────────────────────

  Future<void> saveSteps(int steps) async {
    if (uid.isEmpty) return;
    _fitnessData = {..._fitnessData, 'steps': steps, 'date': _today};
    notifyListeners();
    await _db.collection('users').doc(uid)
        .collection('fitness').doc(_today)
        .set({'steps': steps, 'date': _today,
              'updatedAt': FieldValue.serverTimestamp()},
             SetOptions(merge: true));
  }

  // ── NOTIFICATION SETTINGS ─────────────────────────────────────────────────

  Future<void> saveNotifSettings({
    required bool workout,
    required bool water,
    required bool meditation,
    required bool goals,
  }) async {
    if (uid.isEmpty) return;
    final data = {
      'workoutReminders': workout,
      'waterIntake': water,
      'meditationSessions': meditation,
      'dailyGoals': goals,
    };
    _notifSettings = data;
    notifyListeners();
    await _db.collection('users').doc(uid)
        .collection('settings').doc('notifications')
        .set(data, SetOptions(merge: true));
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}