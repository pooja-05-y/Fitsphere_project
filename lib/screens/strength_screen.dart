import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'workout_timer_screen.dart';

class StrengthScreen extends StatelessWidget {
  const StrengthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkoutTimerScreen(
      workoutName: 'Strength',
      emoji: '💪',
      color: AppTheme.green,
      durationMinutes: 60,
      exercises: [
        {
          'name': 'Warm Up',
          'desc': 'Light cardio and dynamic stretches',
          'duration': '5 min',
        },
        {
          'name': 'Bench Press',
          'desc': 'Lie on bench, lower bar to chest, press up',
          'sets': '4 sets',
          'reps': '10 reps',
          'rest': '90 sec',
        },
        {
          'name': 'Squats',
          'desc': 'Feet shoulder-width, squat until thighs are parallel',
          'sets': '4 sets',
          'reps': '12 reps',
          'rest': '90 sec',
        },
        {
          'name': 'Deadlift',
          'desc': 'Keep back straight, drive through heels to stand',
          'sets': '3 sets',
          'reps': '8 reps',
          'rest': '2 min',
        },
        {
          'name': 'Pull Ups',
          'desc': 'Hang from bar, pull chin above bar level',
          'sets': '3 sets',
          'reps': '8 reps',
          'rest': '60 sec',
        },
        {
          'name': 'Shoulder Press',
          'desc': 'Press dumbbells overhead from shoulder height',
          'sets': '3 sets',
          'reps': '12 reps',
          'rest': '60 sec',
        },
        {
          'name': 'Plank',
          'desc': 'Hold body straight, elbows under shoulders',
          'sets': '3 sets',
          'duration': '60 sec',
          'rest': '30 sec',
        },
        {
          'name': 'Cool Down Stretch',
          'desc': 'Static stretches for all major muscle groups',
          'duration': '5 min',
        },
      ],
      tips: [
        'Warm up properly before lifting heavy',
        'Prioritise form over the amount of weight',
        'Rest fully between sets for maximum strength gains',
        'Stay hydrated throughout the session',
        'Track your weights to progressively overload each week',
      ],
    );
  }
}