import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'cardio_screen.dart';
import 'meditation_screen.dart';
import 'strength_screen.dart';
import 'hiit_screen.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  final List<Map<String, dynamic>> workouts = const [
    {
      'title': 'Cardio',
      'desc': 'Tap to view workout details',
      'icon': Icons.directions_run,
      'color': Color(0xFF2563EB),
      'bg': Color(0xFFDBEAFE),
    },
    {
      'title': 'Yoga',
      'desc': 'Tap to view workout details',
      'icon': Icons.self_improvement,
      'color': Color(0xFF8B5CF6),
      'bg': Color(0xFFEDE9FE),
    },
    {
      'title': 'Strength',
      'desc': 'Tap to view workout details',
      'icon': Icons.fitness_center,
      'color': Color(0xFF22C55E),
      'bg': Color(0xFFDCFCE7),
    },
    {
      'title': 'HIIT',
      'desc': 'Tap to view workout details',
      'icon': Icons.flash_on,
      'color': Color(0xFFF97316),
      'bg': Color(0xFFFFEDD5),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Workouts',
          style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18),
        ),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              'Choose Your Workout',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Select a workout to view details and start',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: workouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final w = workouts[i];
                return GestureDetector(
                  onTap: () {
                    if (w['title'] == 'Cardio') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CardioScreen()),
                      );
                    } else if (w['title'] == 'Yoga') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MeditationScreen()),
                      );
                    } else if (w['title'] == 'Strength') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StrengthScreen()),
                      );
                    } else if (w['title'] == 'HIIT') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HiitScreen()),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: w['bg'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(w['icon'] as IconData,
                              color: w['color'] as Color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w['title'] as String,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                w['desc'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.textLight),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // This Week stats
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _WeekStat(value: '12', label: 'Workouts'),
                    _WeekStat(value: '6.5', label: 'Hours'),
                    _WeekStat(value: '2.4k', label: 'Calories'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String value;
  final String label;

  const _WeekStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
