import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HiitScreen extends StatefulWidget {
  const HiitScreen({super.key});

  @override
  State<HiitScreen> createState() => _HiitScreenState();
}

class _HiitScreenState extends State<HiitScreen>
    with SingleTickerProviderStateMixin {
  // ── HIIT config ────────────────────────────────────────────────────────────
  static const int _workSeconds = 40;
  static const int _restSeconds = 20;
  static const int _rounds = 3;

  final List<Map<String, dynamic>> _exercises = const [
    {'name': 'Jumping Jacks', 'emoji': '⭐', 'desc': 'Full body warm up'},
    {'name': 'Burpees', 'emoji': '🔥', 'desc': 'Full body explosive move'},
    {'name': 'High Knees', 'emoji': '🦵', 'desc': 'Cardio and core'},
    {'name': 'Mountain Climbers', 'emoji': '⚡', 'desc': 'Core and upper body'},
    {'name': 'Jump Squats', 'emoji': '💥', 'desc': 'Lower body power'},
    {'name': 'Push Ups', 'emoji': '💪', 'desc': 'Upper body strength'},
  ];

  // ── State ─────────────────────────────────────────────────────────────────
  int _currentExercise = 0;
  int _currentRound = 1;
  bool _isResting = false;
  bool _isRunning = false;
  bool _isFinished = false;
  bool _isCountingDown = false;
  int _secondsLeft = 3; // countdown before start
  Timer? _timer;
  int _totalCalories = 0;
  int _completedExercises = 0;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _secondsLeft = 3;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() => _isCountingDown = false);
        _beginWorkInterval();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _beginWorkInterval() {
    setState(() {
      _isResting = false;
      _isRunning = true;
      _secondsLeft = _workSeconds;
    });
    _pulseCtrl.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _completedExercises++;
        _totalCalories += 8;
        _beginRestInterval();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _beginRestInterval() {
    _timer?.cancel();
    _pulseCtrl.stop();

    // Check if we've completed all exercises in this round
    if (_currentExercise >= _exercises.length - 1) {
      if (_currentRound >= _rounds) {
        // All rounds done
        _onFinish();
        return;
      } else {
        // Next round
        setState(() {
          _currentRound++;
          _currentExercise = 0;
        });
      }
    } else {
      setState(() => _currentExercise++);
    }

    setState(() {
      _isResting = true;
      _secondsLeft = _restSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _beginWorkInterval();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() => _isRunning = false);
  }

  void _resume() {
    _pulseCtrl.repeat(reverse: true);
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        if (_isResting) {
          _beginWorkInterval();
        } else {
          _completedExercises++;
          _totalCalories += 8;
          _beginRestInterval();
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _skip() {
    _timer?.cancel();
    if (_isResting) {
      _beginWorkInterval();
    } else {
      _completedExercises++;
      _totalCalories += 4;
      _beginRestInterval();
    }
  }

  void _reset() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _currentExercise = 0;
      _currentRound = 1;
      _isResting = false;
      _isRunning = false;
      _isFinished = false;
      _isCountingDown = false;
      _secondsLeft = _workSeconds;
      _totalCalories = 0;
      _completedExercises = 0;
    });
  }

  void _onFinish() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _isRunning = false;
      _isFinished = true;
    });
    _showCompleteDialog();
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔥', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text('HIIT Complete!',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('$_rounds rounds • ${_exercises.length} exercises',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatPill(label: 'Rounds', value: '$_rounds', color: AppTheme.orange),
            _StatPill(label: 'Calories', value: '~$_totalCalories', color: AppTheme.accent),
            _StatPill(label: 'Exercises', value: '$_completedExercises', color: AppTheme.green),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text('Done',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () { Navigator.pop(context); _reset(); },
            child: Text('Do Again',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
          ),
        ]),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _timeDisplay {
    final s = _secondsLeft;
    return s.toString().padLeft(2, '0');
  }

  double get _timerProgress {
    final total = _isResting ? _restSeconds : _workSeconds;
    return (_secondsLeft / total).clamp(0.0, 1.0);
  }

  int get _totalExercisesCount => _exercises.length * _rounds;
  int get _doneCount =>
      (_currentRound - 1) * _exercises.length + _currentExercise;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final exercise = _exercises[_currentExercise];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () {
            if (_isRunning) _pause();
            _showExitDialog();
          },
        ),
        title: Text('HIIT',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text('Reset',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Round + overall progress
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Round $_currentRound / $_rounds',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              Text('$_doneCount / $_totalExercisesCount exercises',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _doneCount / _totalExercisesCount,
                backgroundColor: AppTheme.darkCardLight,
                valueColor: AlwaysStoppedAnimation(AppTheme.orange),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),

            // Round dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_rounds, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i + 1 < _currentRound ? 10 : i + 1 == _currentRound ? 20 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i + 1 < _currentRound
                      ? AppTheme.green
                      : i + 1 == _currentRound
                          ? AppTheme.orange
                          : AppTheme.darkCardLight,
                  borderRadius: BorderRadius.circular(5),
                ),
              )),
            ),
            const SizedBox(height: 24),

            // Phase badge
            if (!_isCountingDown)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _isResting
                      ? AppTheme.teal.withOpacity(0.2)
                      : AppTheme.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isResting ? '😮‍💨  REST' : '🔥  WORK',
                  style: GoogleFonts.poppins(
                    color: _isResting ? AppTheme.teal : AppTheme.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Timer ring
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  if (_isRunning && !_isResting)
                    Container(
                      width: 215 + (7 * _pulseCtrl.value),
                      height: 215 + (7 * _pulseCtrl.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.orange.withOpacity(0.04 * _pulseCtrl.value),
                      ),
                    ),
                  SizedBox(
                    width: 200, height: 200,
                    child: CircularProgressIndicator(
                      value: _isCountingDown ? 1.0 : _timerProgress,
                      strokeWidth: 12,
                      backgroundColor: AppTheme.darkCardLight,
                      valueColor: AlwaysStoppedAnimation(
                        _isFinished
                            ? AppTheme.green
                            : _isCountingDown
                                ? Colors.white54
                                : _isResting
                                    ? AppTheme.teal
                                    : AppTheme.orange,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    if (_isCountingDown)
                      Text(_secondsLeft.toString(),
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 72,
                              fontWeight: FontWeight.w800))
                    else ...[
                      Text(exercise['emoji'] as String,
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 4),
                      Text(_timeDisplay,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.w800)),
                      Text(
                        _isResting ? 'seconds rest' : 'seconds',
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Exercise name
            if (!_isCountingDown) ...[
              Text(
                _isResting ? 'Rest' : exercise['name'] as String,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _isResting
                    ? 'Get ready for: ${_exercises[_currentExercise]['name']}'
                    : exercise['desc'] as String,
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ] else ...[
              Text('Get Ready!',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Starting ${exercise['name']}',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 24),
            ],

            // Controls
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _ControlBtn(
                icon: Icons.replay_rounded,
                color: AppTheme.darkCard,
                iconColor: Colors.white54,
                size: 52,
                onTap: _reset,
              ),
              const SizedBox(width: 16),
              _ControlBtn(
                icon: _isCountingDown
                    ? Icons.hourglass_top_rounded
                    : _isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                color: _isFinished ? AppTheme.darkCardLight : AppTheme.orange,
                iconColor: Colors.white,
                size: 70,
                shadow: !_isFinished,
                onTap: _isFinished
                    ? null
                    : _isCountingDown
                        ? null
                        : _isRunning
                            ? _pause
                            : _isRunning == false && _secondsLeft == _workSeconds && _currentExercise == 0 && _currentRound == 1
                                ? _startCountdown
                                : _resume,
              ),
              const SizedBox(width: 16),
              _ControlBtn(
                icon: Icons.skip_next_rounded,
                color: AppTheme.darkCard,
                iconColor: Colors.white54,
                size: 52,
                onTap: _isCountingDown || _isFinished ? null : _skip,
              ),
            ]),
            const SizedBox(height: 24),

            // Up next
            if (!_isFinished && !_isCountingDown) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Up Next',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              ..._exercises
                  .asMap()
                  .entries
                  .where((e) => e.key > _currentExercise)
                  .take(3)
                  .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Text(e.value['emoji'] as String,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.value['name'] as String,
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    Text('${_workSeconds}s',
                        style: GoogleFonts.poppins(
                            color: AppTheme.orange, fontSize: 12)),
                  ]),
                ),
              )),
            ],

            // Stats
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _MiniStat(label: 'Calories', value: '~$_totalCalories kcal', color: AppTheme.accent)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Completed', value: '$_completedExercises sets', color: AppTheme.green)),
            ]),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Leave Workout?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Your progress will be lost.',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!_isFinished) _resume();
            },
            child: Text('Keep Going',
                style: GoogleFonts.poppins(
                    color: AppTheme.orange, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Leave',
                style: GoogleFonts.poppins(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon; final Color color; final Color iconColor;
  final double size; final VoidCallback? onTap; final bool shadow;
  const _ControlBtn({required this.icon, required this.color, required this.iconColor, required this.size, required this.onTap, this.shadow = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onTap == null ? color.withOpacity(0.4) : color,
        boxShadow: shadow ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16, spreadRadius: 2)] : null,
      ),
      child: Icon(icon, color: onTap == null ? iconColor.withOpacity(0.4) : iconColor, size: size * 0.45),
    ),
  );
}

class _StatPill extends StatelessWidget {
  final String label; final String value; final Color color;
  const _StatPill({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.poppins(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
    Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
  ]);
}

class _MiniStat extends StatelessWidget {
  final String label; final String value; final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
      ]),
    ]),
  );
}