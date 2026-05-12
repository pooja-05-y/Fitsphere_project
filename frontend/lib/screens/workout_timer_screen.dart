import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class WorkoutTimerScreen extends StatefulWidget {
  final String workoutName;
  final String emoji;
  final Color color;
  final int durationMinutes;
  final List<Map<String, dynamic>> exercises;
  final List<String> tips;

  const WorkoutTimerScreen({
    super.key,
    required this.workoutName,
    required this.emoji,
    required this.color,
    required this.durationMinutes,
    required this.exercises,
    required this.tips,
  });

  @override
  State<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen>
    with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late int _secondsLeft;
  bool _isRunning = false;
  bool _isFinished = false;
  Timer? _timer;
  int _currentExercise = 0;
  int _completedSets = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _secondsLeft = _totalSeconds;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _isRunning = true);
    _pulseCtrl.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _onFinish();
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

  void _reset() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _isRunning = false;
      _isFinished = false;
      _secondsLeft = _totalSeconds;
      _currentExercise = 0;
      _completedSets = 0;
    });
  }

  void _skipExercise() {
    if (_currentExercise < widget.exercises.length - 1) {
      setState(() {
        _completedSets++;
        _currentExercise++;
      });
    }
  }

  void _onFinish() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() {
      _isRunning = false;
      _isFinished = true;
      _secondsLeft = 0;
    });
    _showCompleteDialog();
  }

  void _showCompleteDialog() {
    final calories = (widget.durationMinutes * 7.5).toInt();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text('Workout Complete!',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('${widget.workoutName} — ${widget.durationMinutes} min',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatPill(label: 'Duration', value: '${widget.durationMinutes}m', color: widget.color),
            _StatPill(label: 'Calories', value: '~$calories', color: AppTheme.orange),
            _StatPill(label: 'Sets', value: '$_completedSets', color: AppTheme.green),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
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
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            child: Text('Do Again',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
          ),
        ]),
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
              if (!_isFinished) _start();
            },
            child: Text('Keep Going',
                style: GoogleFonts.poppins(
                    color: widget.color, fontWeight: FontWeight.w600)),
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

  String get _timeDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      (_totalSeconds - _secondsLeft) / _totalSeconds.toDouble();

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercises.isNotEmpty
        ? widget.exercises[_currentExercise]
        : null;

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
        title: Text(widget.workoutName,
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
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppTheme.darkCardLight,
                valueColor: AlwaysStoppedAnimation(widget.color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${(_progress * 100).toInt()}% complete',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
              Text('${widget.durationMinutes} min total',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
            ]),
            const SizedBox(height: 28),

            // Timer ring
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  if (_isRunning)
                    Container(
                      width: 210 + (8 * _pulseCtrl.value),
                      height: 210 + (8 * _pulseCtrl.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withOpacity(0.04 * _pulseCtrl.value),
                      ),
                    ),
                  SizedBox(
                    width: 200, height: 200,
                    child: CircularProgressIndicator(
                      value: 1.0 - _progress,
                      strokeWidth: 12,
                      backgroundColor: AppTheme.darkCardLight,
                      valueColor: AlwaysStoppedAnimation(
                          _isFinished ? AppTheme.green : widget.color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(_timeDisplay,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w700)),
                    Text(
                      _isFinished
                          ? 'Complete! 🎉'
                          : _isRunning
                              ? 'In Progress'
                              : _secondsLeft == _totalSeconds
                                  ? 'Ready'
                                  : 'Paused',
                      style: GoogleFonts.poppins(
                          color: _isFinished
                              ? AppTheme.green
                              : _isRunning
                                  ? widget.color
                                  : Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

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
                icon: _isRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: _isFinished ? AppTheme.darkCardLight : widget.color,
                iconColor: Colors.white,
                size: 70,
                onTap: _isFinished
                    ? null
                    : _isRunning
                        ? _pause
                        : _start,
                shadow: !_isFinished,
              ),
              const SizedBox(width: 16),
              _ControlBtn(
                icon: Icons.skip_next_rounded,
                color: AppTheme.darkCard,
                iconColor: widget.exercises.length > 1
                    ? Colors.white54
                    : Colors.white24,
                size: 52,
                onTap: widget.exercises.length > 1 ? _skipExercise : null,
              ),
            ]),
            const SizedBox(height: 28),

            // Current exercise
            if (exercise != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Now',
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 12)),
                    Text('${_currentExercise + 1} / ${widget.exercises.length}',
                        style: GoogleFonts.poppins(
                            color: widget.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  Text(exercise['name'] as String,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  if (exercise['desc'] != null) ...[
                    const SizedBox(height: 4),
                    Text(exercise['desc'] as String,
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 12)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if (exercise['sets'] != null)
                      _Tag(label: exercise['sets'] as String, color: widget.color),
                    if (exercise['reps'] != null)
                      _Tag(label: exercise['reps'] as String, color: widget.color),
                    if (exercise['duration'] != null)
                      _Tag(label: exercise['duration'] as String, color: AppTheme.teal),
                    if (exercise['rest'] != null)
                      _Tag(label: 'Rest: ${exercise['rest']}', color: AppTheme.orange),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),

              // Mark set done
              GestureDetector(
                onTap: () {
                  setState(() => _completedSets++);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Set complete! Total: $_completedSets 💪',
                        style: GoogleFonts.poppins(color: Colors.white)),
                    backgroundColor: widget.color,
                    duration: const Duration(seconds: 1),
                  ));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.color.withOpacity(0.35)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_outline, color: widget.color, size: 20),
                    const SizedBox(width: 8),
                    Text('Mark Set Done  •  $_completedSets done',
                        style: GoogleFonts.poppins(
                            color: widget.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Exercise list
            if (widget.exercises.length > 1) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Exercises',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              ...widget.exercises.asMap().entries.map((entry) {
                final i = entry.key;
                final ex = entry.value;
                final isDone = i < _currentExercise;
                final isCurrent = i == _currentExercise;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? widget.color.withOpacity(0.1)
                          : AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? widget.color.withOpacity(0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppTheme.green
                              : isCurrent
                                  ? widget.color
                                  : AppTheme.darkCardLight,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : Text('${i + 1}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(ex['name'] as String,
                            style: GoogleFonts.poppins(
                              color: isDone
                                  ? Colors.white30
                                  : isCurrent
                                      ? Colors.white
                                      : Colors.white60,
                              fontSize: 13,
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                      ),
                      if (ex['sets'] != null)
                        Text(ex['sets'] as String,
                            style: GoogleFonts.poppins(
                                color: Colors.white30, fontSize: 11)),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Tips
            if (widget.tips.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.color.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('💡 Tips',
                      style: GoogleFonts.poppins(
                          color: widget.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  ...widget.tips.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $t',
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 12)),
                  )),
                ]),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;
  final bool shadow;
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

class _Tag extends StatelessWidget {
  final String label; final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
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