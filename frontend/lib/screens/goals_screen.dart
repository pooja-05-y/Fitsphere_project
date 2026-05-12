import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  double _steps = 10000;
  double _calories = 2000;
  double _water = 8;
  double _workouts = 5;
  double _sleep = 8;
  bool _init = false;

  final _achievements = [
    {'title': '7-Day Streak', 'desc': 'Work out 7 days in a row', 'icon': '🔥', 'done': true},
    {'title': 'Step Master', 'desc': 'Hit 10,000 steps in a day', 'icon': '👟', 'done': true},
    {'title': 'Calorie Crusher', 'desc': 'Burn 500 cal in one session', 'icon': '💥', 'done': false},
    {'title': 'Early Bird', 'desc': 'Work out before 7 AM', 'icon': '🌅', 'done': false},
    {'title': 'Hydration Hero', 'desc': 'Drink 8 glasses daily for a week', 'icon': '💧', 'done': false},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final svc = context.read<FirebaseService>();
      _steps = svc.stepGoal;
      _calories = svc.calorieGoal;
      _water = svc.waterGoal;
      _workouts = svc.workoutsGoal;
      _sleep = svc.sleepGoal;
      _init = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Goals', style: GoogleFonts.poppins(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Text('🎯', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your Goals', style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                Text('Drag sliders · tap Save · syncs to Firebase',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          Text('Daily Targets', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),

          _GoalSlider(icon: '👟', label: 'Daily Steps', unit: 'steps',
              value: _steps, min: 1000, max: 20000, divisions: 19,
              color: AppTheme.primary, onChanged: (v) => setState(() => _steps = v)),
          const SizedBox(height: 12),
          _GoalSlider(icon: '🔥', label: 'Calorie Goal', unit: 'kcal',
              value: _calories, min: 500, max: 5000, divisions: 18,
              color: AppTheme.orange, onChanged: (v) => setState(() => _calories = v)),
          const SizedBox(height: 12),
          _GoalSlider(icon: '💧', label: 'Water Intake', unit: 'glasses',
              value: _water, min: 4, max: 16, divisions: 12,
              color: AppTheme.teal, onChanged: (v) => setState(() => _water = v)),
          const SizedBox(height: 12),
          _GoalSlider(icon: '💪', label: 'Workouts / Week', unit: 'days',
              value: _workouts, min: 1, max: 7, divisions: 6,
              color: AppTheme.green, onChanged: (v) => setState(() => _workouts = v)),
          const SizedBox(height: 12),
          _GoalSlider(icon: '😴', label: 'Sleep Goal', unit: 'hours',
              value: _sleep, min: 4, max: 12, divisions: 8,
              color: AppTheme.purple, onChanged: (v) => setState(() => _sleep = v)),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () async {
                await context.read<FirebaseService>().saveGoals(
                  steps: _steps, calories: _calories, water: _water,
                  workoutsPerWeek: _workouts, sleep: _sleep,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Goals saved to Firebase! 🎯',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                    backgroundColor: AppTheme.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Save to Firebase', style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 28),

          Text('Achievements', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          ..._achievements.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (a['done'] as bool)
                    ? AppTheme.green.withOpacity(0.4) : AppTheme.lightBorder),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Row(children: [
                Text(a['icon'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['title'] as String, style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                  Text(a['desc'] as String, style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textSecondary)),
                ])),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: (a['done'] as bool) ? AppTheme.green : AppTheme.lightBorder),
                  child: Icon((a['done'] as bool) ? Icons.check : Icons.lock_outline,
                      color: Colors.white, size: 14),
                ),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

class _GoalSlider extends StatelessWidget {
  final String icon, label, unit;
  final double value, min, max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;

  const _GoalSlider({required this.icon, required this.label, required this.unit,
      required this.value, required this.min, required this.max,
      required this.divisions, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(children: [
      Row(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toInt()} $unit', style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ),
      ]),
      SliderTheme(
        data: SliderThemeData(activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            thumbColor: color, overlayColor: color.withOpacity(0.15), trackHeight: 4),
        child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
      ),
    ]),
  );
}