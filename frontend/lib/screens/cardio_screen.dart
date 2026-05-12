import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'workout_timer_screen.dart';

class CardioScreen extends StatelessWidget {
  const CardioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkoutTimerScreen(
      workoutName: 'Cardio',
      emoji: '🏃',
      color: AppTheme.primary,
      durationMinutes: 30,
      exercises: [
        {
          'name': 'Warm Up Jog',
          'desc': 'Light jog to get your heart rate up',
          'duration': '5 min',
          'rest': '30 sec',
        },
        {
          'name': 'Sprint Intervals',
          'desc': 'Sprint for 30 sec, walk for 30 sec',
          'sets': '8 sets',
          'duration': '30 sec each',
          'rest': '30 sec',
        },
        {
          'name': 'Jumping Jacks',
          'desc': 'Full body cardio movement',
          'sets': '3 sets',
          'reps': '50 reps',
          'rest': '30 sec',
        },
        {
          'name': 'High Knees',
          'desc': 'Drive knees up to hip level',
          'sets': '3 sets',
          'duration': '45 sec',
          'rest': '20 sec',
        },
        {
          'name': 'Burpees',
          'desc': 'Full body explosive movement',
          'sets': '3 sets',
          'reps': '15 reps',
          'rest': '45 sec',
        },
        {
          'name': 'Cool Down Walk',
          'desc': 'Slow walk to bring heart rate down',
          'duration': '5 min',
        },
      ],
      tips: [
        'Stay hydrated — drink water every 10 minutes',
        'Maintain a pace where you can still talk',
        'Land softly on your feet during jumps',
        'Keep your core engaged throughout',
        'Breathe steadily — inhale through nose, exhale mouth',
      ],
    );
  }
}


