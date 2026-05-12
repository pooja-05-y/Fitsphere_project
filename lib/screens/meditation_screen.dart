import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'workout_timer_screen.dart';

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkoutTimerScreen(
      workoutName: 'Yoga & Meditation',
      emoji: '🧘',
      color: AppTheme.purple,
      durationMinutes: 20,
      exercises: [
        {
          'name': 'Seated Breathing',
          'desc': 'Sit cross-legged, close eyes, breathe deeply',
          'duration': '3 min',
          'rest': '30 sec',
        },
        {
          'name': "Child's Pose",
          'desc': 'Kneel and extend arms forward, rest forehead on floor',
          'duration': '2 min',
          'rest': '20 sec',
        },
        {
          'name': 'Cat-Cow Stretch',
          'desc': 'On all fours, alternate arching and rounding your back',
          'sets': '3 sets',
          'reps': '10 reps',
          'rest': '20 sec',
        },
        {
          'name': 'Downward Dog',
          'desc': 'Form an inverted V-shape, press heels toward floor',
          'duration': '2 min',
          'rest': '30 sec',
        },
        {
          'name': 'Warrior I',
          'desc': 'Lunge forward, raise arms overhead, open chest',
          'sets': '2 sets',
          'duration': '60 sec each side',
          'rest': '20 sec',
        },
        {
          'name': 'Tree Pose',
          'desc': 'Balance on one leg, press foot to inner thigh',
          'sets': '2 sets',
          'duration': '45 sec each side',
          'rest': '20 sec',
        },
        {
          'name': 'Savasana',
          'desc': 'Lie flat, close eyes, fully relax every muscle',
          'duration': '5 min',
        },
      ],
      tips: [
        'Focus on your breath throughout each pose',
        'Never force a stretch — go to your comfortable edge',
        'Move slowly and mindfully between poses',
        'Keep your core lightly engaged',
        'Let your mind settle — redirect focus to breath if it wanders',
      ],
    );
  }
}
