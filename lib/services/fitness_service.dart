import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class FitnessService extends ChangeNotifier {
  // Singleton so every screen shares the same live data
  static final FitnessService _instance = FitnessService._internal();
  factory FitnessService() => _instance;
  FitnessService._internal();

  // ── Step tracking ──────────────────────────────────────────────────────────
  int _todaySteps = 0;
  int _stepGoal = 10000;
  int _baseStepCount = -1; // raw pedometer value at midnight / first launch
  String _pedometerStatus = 'unknown';
  bool _pedometerAvailable = true;

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  // ── Hourly bucket (index = hour 0-23) ─────────────────────────────────────
  List<int> _hourlySteps = List.filled(24, 0);
  int _stepsAtStartOfHour = 0;
  int _lastTrackedHour = -1;

  // ── Weekly history ─────────────────────────────────────────────────────────
  List<int> _weeklySteps = [3200, 7800, 5500, 9100, 6300, 8400, 0];

  // ── User metrics ───────────────────────────────────────────────────────────
  double _weightKg = 70;
  double _heightCm = 175;

  // ── Active minutes ─────────────────────────────────────────────────────────
  int _activeMinutes = 0;
  bool _isCurrentlyWalking = false;
  Timer? _activeTimer;

  // ── Heart rate estimate via accelerometer ──────────────────────────────────
  double _heartRate = 72;
  final List<double> _accelMagnitudes = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // ── Calories consumed (set by diet tracker) ────────────────────────────────
  double _caloriesConsumed = 1500;

  // ── Notification milestones already fired today ───────────────────────────
  final Set<int> _firedMilestones = {};

  // ── Getters ────────────────────────────────────────────────────────────────
  int get todaySteps => _todaySteps;
  int get stepGoal => _stepGoal;
  double get stepProgress => (_todaySteps / _stepGoal).clamp(0.0, 1.0);
  String get pedometerStatus => _pedometerStatus;
  bool get pedometerAvailable => _pedometerAvailable;

  double get caloriesBurned {
    // Standard formula: steps × 0.04 × (weight / 70)
    return (_todaySteps * 0.04 * (_weightKg / 70));
  }

  double get distanceKm {
    // Stride = 0.415 × height(m)
    final stride = 0.415 * (_heightCm / 100);
    return _todaySteps * stride / 1000;
  }

  double get heartRate => _heartRate;
  int get activeMinutes => _activeMinutes;
  double get caloriesConsumed => _caloriesConsumed;
  double get caloriesGoal => 2000;
  List<int> get hourlySteps => List.unmodifiable(_hourlySteps);
  List<int> get weeklySteps => List.unmodifiable(_weeklySteps);
  double get weightKg => _weightKg;
  double get heightCm => _heightCm;

  // ── Initialise everything ──────────────────────────────────────────────────
  Future<void> init() async {
    await _loadFromPrefs();
    _startPedometer();
    _startAccelerometer();
    _startActiveMinuteTimer();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PEDOMETER
  // ─────────────────────────────────────────────────────────────────────────
  void _startPedometer() {
    _stepSub?.cancel();
    _statusSub?.cancel();

    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) {
        _pedometerAvailable = false;
        _pedometerStatus = 'unavailable';
        notifyListeners();
      },
      cancelOnError: false,
    );

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (event) {
        _pedometerStatus = event.status;
        _isCurrentlyWalking = event.status == 'walking';
        notifyListeners();
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void _onStepCount(StepCount event) async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('step_date') ?? '';

    // First ever reading — set base
    if (_baseStepCount == -1) {
      _baseStepCount = event.steps;
      await prefs.setInt('step_base', _baseStepCount);
      await prefs.setString('step_date', todayStr);
    }

    // New day rolled over
    if (savedDate != todayStr && savedDate.isNotEmpty) {
      // Save yesterday total into weekly history
      _shiftWeeklyHistory(_todaySteps);
      _hourlySteps = List.filled(24, 0);
      _activeMinutes = 0;
      _firedMilestones.clear();
      _baseStepCount = event.steps;
      await prefs.setInt('step_base', _baseStepCount);
      await prefs.setString('step_date', todayStr);
    }

    // Calculate today's steps
    _todaySteps = (event.steps - _baseStepCount).clamp(0, 9999999);

    // Update hourly bucket
    _updateHourlyBucket(now.hour);

    // Check milestone notifications
    _checkStepMilestones();

    // Persist
    await prefs.setInt('today_steps', _todaySteps);
    await _saveWeeklyHistory();

    notifyListeners();
  }

  void _updateHourlyBucket(int currentHour) {
    if (_lastTrackedHour != currentHour) {
      // Hour changed — record how many steps we had at this boundary
      _stepsAtStartOfHour = _todaySteps;
      _lastTrackedHour = currentHour;
    }
    // Steps taken in this hour = total today minus what we had at the hour start
    final stepsThisHour = (_todaySteps - _stepsAtStartOfHour).clamp(0, 99999);
    _hourlySteps[currentHour] = stepsThisHour;
  }

  void _checkStepMilestones() {
    final milestones = [2000, 5000, 7500, 10000, 15000, 20000];
    for (final m in milestones) {
      if (_todaySteps >= m && !_firedMilestones.contains(m)) {
        _firedMilestones.add(m);
        if (m == _stepGoal) {
          NotificationService().showNotification(
            id: m,
            title: '🎉 Goal Reached!',
            body: 'Amazing! You hit your ${_formatNumber(m)} step goal today!',
          );
        } else {
          NotificationService().showNotification(
            id: m,
            title: '🚶 ${_formatNumber(m)} Steps!',
            body: 'Great progress! Keep going — you\'re crushing it!',
          );
        }
      }
    }
  }

  String _formatNumber(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k' : '$n';

  void _shiftWeeklyHistory(int todayTotal) {
    for (int i = 0; i < 6; i++) {
      _weeklySteps[i] = _weeklySteps[i + 1];
    }
    _weeklySteps[6] = todayTotal;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCELEROMETER → Heart Rate estimate
  // ─────────────────────────────────────────────────────────────────────────
  void _startAccelerometer() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _accelMagnitudes.add(mag);
      if (_accelMagnitudes.length > 100) _accelMagnitudes.removeAt(0);
      if (_accelMagnitudes.length == 100) _estimateHeartRate();
    });
  }

  void _estimateHeartRate() {
    final mean = _accelMagnitudes.reduce((a, b) => a + b) / _accelMagnitudes.length;
    int crossings = 0;
    for (int i = 1; i < _accelMagnitudes.length; i++) {
      if ((_accelMagnitudes[i - 1] - mean).sign != (_accelMagnitudes[i] - mean).sign) {
        crossings++;
      }
    }
    // 100 samples at 10Hz = 10 seconds; crossings / 10 * 60 = BPM estimate
    final raw = ((crossings / 10.0) * 60).clamp(45.0, 180.0);
    // EMA smoothing
    _heartRate = _heartRate * 0.85 + raw * 0.15;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVE MINUTES
  // ─────────────────────────────────────────────────────────────────────────
  void _startActiveMinuteTimer() {
    _activeTimer?.cancel();
    _activeTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (_isCurrentlyWalking) {
        _activeMinutes++;
        // Notification every 30 active minutes
        if (_activeMinutes % 30 == 0) {
          NotificationService().showNotification(
            id: 9000 + _activeMinutes,
            title: '💪 $_activeMinutes Active Minutes!',
            body: 'Fantastic effort — keep moving!',
          );
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('active_minutes', _activeMinutes);
        notifyListeners();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PERSISTENCE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString('step_date') ?? '';

    if (savedDate == todayStr) {
      _baseStepCount = prefs.getInt('step_base') ?? -1;
      _todaySteps = prefs.getInt('today_steps') ?? 0;
      _activeMinutes = prefs.getInt('active_minutes') ?? 0;
    }

    _stepGoal = prefs.getInt('step_goal') ?? 10000;
    _weightKg = prefs.getDouble('weight_kg') ?? 70;
    _heightCm = prefs.getDouble('height_cm') ?? 175;

    final weekStr = prefs.getString('weekly_steps') ?? '';
    if (weekStr.isNotEmpty) {
      final parts = weekStr.split(',');
      if (parts.length == 7) {
        _weeklySteps = parts.map((e) => int.tryParse(e) ?? 0).toList();
      }
    }
    // Inject today into the last slot of weekly
    _weeklySteps[6] = _todaySteps;
  }

  Future<void> _saveWeeklyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weekly_steps', _weeklySteps.join(','));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC SETTERS (called from UI)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setStepGoal(int goal) async {
    _stepGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_goal', goal);
    notifyListeners();
  }

  Future<void> setUserMetrics({double? weight, double? height}) async {
    if (weight != null) _weightKg = weight;
    if (height != null) _heightCm = height;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weight_kg', _weightKg);
    await prefs.setDouble('height_cm', _heightCm);
    notifyListeners();
  }

  void updateCaloriesConsumed(double cal) {
    _caloriesConsumed = cal;
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _accelSub?.cancel();
    _activeTimer?.cancel();
    super.dispose();
  }
}