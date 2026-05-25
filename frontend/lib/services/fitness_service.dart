import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FitnessService extends ChangeNotifier {
  static final FitnessService _instance = FitnessService._internal();
  factory FitnessService() => _instance;
  FitnessService._internal();

  // ── Step state ─────────────────────────────────────────────────────────────
  int _todaySteps = 0;
  int _stepGoal = 10000;
  int _rawBase = -1;
  bool _pedometerWorking = false;
  String _status = 'Initialising...';

  // ── Hourly / weekly ────────────────────────────────────────────────────────
  List<int> _hourly = List.filled(24, 0);
  int _stepsAtHourStart = 0;
  int _lastHour = -1;
  List<int> _weekly = [3200, 7800, 5500, 9100, 6300, 8400, 0];

  // ── Accel fallback step detection ─────────────────────────────────────────
  bool _usingFallback = false;
  int _accelSteps = 0;
  double _prevMag = 9.8;
  bool _stepPending = false;
  DateTime _lastStepTime = DateTime.now();
  static const double _threshold = 11.5;   // tune for Samsung
  static const int _minMs = 300;

  // ── Heart rate ─────────────────────────────────────────────────────────────
  double _heartRate = 72;
  final List<double> _hrBuf = [];

  // ── Active minutes ─────────────────────────────────────────────────────────
  int _activeMinutes = 0;
  bool _moving = false;
  Timer? _activeTimer;

  // ── User metrics ────────────────────────────────────────────────────────────
  double _weight = 70;
  double _height = 175;

  // ── Streams ────────────────────────────────────────────────────────────────
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _pedStatusSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // ── Getters ────────────────────────────────────────────────────────────────
  int    get todaySteps      => _todaySteps;
  int    get stepGoal        => _stepGoal;
  double get stepProgress    => (_todaySteps / _stepGoal).clamp(0.0, 1.0);
  String get pedometerStatus => _status;
  bool   get pedometerAvailable => _pedometerWorking || _usingFallback;

  double get caloriesBurned  => _todaySteps * 0.04 * (_weight / 70);
  double get distanceKm      => _todaySteps * 0.415 * (_height / 100) / 1000;
  double get heartRate       => _heartRate;
  int    get activeMinutes   => _activeMinutes;
  double get weightKg        => _weight;
  double get heightCm        => _height;

  List<int> get hourlySteps  => List.unmodifiable(_hourly);
  List<int> get weeklySteps  => List.unmodifiable(_weekly);

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _load();
    _startPedometer();
    _startAccelerometer();
    _startActiveTimer();
    // If pedometer gives no reading in 6 seconds, activate fallback
    Future.delayed(const Duration(seconds: 6), () {
      if (!_pedometerWorking) {
        _usingFallback = true;
        _status = 'Motion sensor active';
        notifyListeners();
      }
    });
  }

  // ── Pedometer ──────────────────────────────────────────────────────────────
  void _startPedometer() {
    _stepSub?.cancel();
    _pedStatusSub?.cancel();

    _stepSub = Pedometer.stepCountStream.listen(
      (event) {
        _pedometerWorking = true;
        _usingFallback = false;
        _handleRawSteps(event.steps);
      },
      onError: (e) {
        debugPrint('[FitSphere] Pedometer error: $e');
        _usingFallback = true;
        _status = 'Motion sensor active';
        notifyListeners();
      },
      cancelOnError: false,
    );

    _pedStatusSub = Pedometer.pedestrianStatusStream.listen(
      (event) {
        _moving = event.status == 'walking';
        _status = _moving ? 'Walking' : 'Still';
        notifyListeners();
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  Future<void> _handleRawSteps(int raw) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final saved = prefs.getString('step_date') ?? '';

    if (_rawBase == -1) {
      _rawBase = raw;
      await prefs.setInt('step_base', raw);
      await prefs.setString('step_date', today);
    }

    if (saved != today && saved.isNotEmpty) {
      _shiftWeekly(_todaySteps);
      _hourly = List.filled(24, 0);
      _activeMinutes = 0;
      _rawBase = raw;
      await prefs.setInt('step_base', raw);
      await prefs.setString('step_date', today);
    }

    _todaySteps = (raw - _rawBase).clamp(0, 9999999);
    _weekly[6] = _todaySteps;
    _updateHourly();
    await _saveSteps(prefs);
    notifyListeners();
  }

  // ── Accelerometer ──────────────────────────────────────────────────────────
  void _startAccelerometer() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

      // Heart rate buffer
      _hrBuf.add(mag);
      if (_hrBuf.length > 150) _hrBuf.removeAt(0);
      if (_hrBuf.length == 150) _calcHR();

      // Fallback step detection
      if (_usingFallback) _detectStep(mag);

      _prevMag = mag;
    });
  }

  void _detectStep(double mag) {
    // Rising edge detection — Samsung gyration signature
    if (!_stepPending && mag > _threshold && _prevMag <= _threshold) {
      _stepPending = true;
    } else if (_stepPending && mag < _threshold) {
      // Falling edge — confirmed step
      final now = DateTime.now();
      final ms = now.difference(_lastStepTime).inMilliseconds;
      if (ms >= _minMs) {
        _accelSteps++;
        _todaySteps = _accelSteps;
        _weekly[6] = _todaySteps;
        _moving = true;
        _status = 'Walking';
        _lastStepTime = now;
        _updateHourly();
        notifyListeners();
        // Save every 10 steps
        if (_accelSteps % 10 == 0) {
          SharedPreferences.getInstance().then(
            (prefs) => _saveSteps(prefs));
        }
      }
      _stepPending = false;
    }
  }

  void _calcHR() {
    final mean = _hrBuf.reduce((a, b) => a + b) / _hrBuf.length;
    int cross = 0;
    for (int i = 1; i < _hrBuf.length; i++) {
      if ((_hrBuf[i - 1] - mean).sign != (_hrBuf[i] - mean).sign) cross++;
    }
    // 150 samples @ 20Hz = 7.5s
    final raw = ((cross / 7.5) * 60).clamp(45.0, 180.0);
    _heartRate = _heartRate * 0.85 + raw * 0.15;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  void _updateHourly() {
    final h = DateTime.now().hour;
    if (h != _lastHour) {
      _stepsAtHourStart = _todaySteps;
      _lastHour = h;
    }
    _hourly[h] = (_todaySteps - _stepsAtHourStart).clamp(0, 99999);
  }

  void _shiftWeekly(int todayTotal) {
    for (int i = 0; i < 6; i++) {
      _weekly[i] = _weekly[i + 1];
    }
    _weekly[6] = todayTotal;
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Active timer ──────────────────────────────────────────────────────────
  void _startActiveTimer() {
    _activeTimer?.cancel();
    _activeTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (_moving) {
        _activeMinutes++;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('active_minutes', _activeMinutes);
        notifyListeners();
      }
    });
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final saved = prefs.getString('step_date') ?? '';

    if (saved == today) {
      _rawBase = prefs.getInt('step_base') ?? -1;
      _todaySteps = prefs.getInt('today_steps') ?? 0;
      _activeMinutes = prefs.getInt('active_minutes') ?? 0;
      _accelSteps = _todaySteps;
    }

    _stepGoal = prefs.getInt('step_goal') ?? 10000;
    _weight   = prefs.getDouble('weight_kg') ?? 70;
    _height   = prefs.getDouble('height_cm') ?? 175;

    final ws = prefs.getString('weekly_steps') ?? '';
    if (ws.isNotEmpty) {
      final parts = ws.split(',');
      if (parts.length == 7) {
        _weekly = parts.map((e) => int.tryParse(e) ?? 0).toList();
      }
    }
    _weekly[6] = _todaySteps;
  }

  Future<void> _saveSteps(SharedPreferences prefs) async {
    await prefs.setInt('today_steps', _todaySteps);
    await prefs.setString('weekly_steps', _weekly.join(','));
    await prefs.setString('step_date', _todayStr());
  }

  // ── Public setters ─────────────────────────────────────────────────────────
  Future<void> setStepGoal(int goal) async {
    _stepGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_goal', goal);
    notifyListeners();
  }

  Future<void> setUserMetrics({double? weight, double? height}) async {
    if (weight != null) _weight = weight;
    if (height != null) _height = height;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weight_kg', _weight);
    await prefs.setDouble('height_cm', _height);
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _pedStatusSub?.cancel();
    _accelSub?.cancel();
    _activeTimer?.cancel();
    super.dispose();
  }
}