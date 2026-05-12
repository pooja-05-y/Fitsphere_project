import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/fitness_service.dart';
import 'fitness_tracker_screen.dart';
import 'diet_tracker_screen.dart';
import 'mood_tracker_screen.dart';
import 'workouts_screen.dart';
import 'food_log_screen.dart';
import 'progress_screen.dart';
import 'notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'goals_screen.dart';
import 'meditation_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirebaseService, FitnessService>(
      builder: (context, svc, fitness, _) => Scaffold(
        backgroundColor: AppTheme.darkBg,
        drawer: _AppDrawer(svc: svc),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Builder(builder: (ctx) => GestureDetector(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.menu, color: Colors.white, size: 22),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('FitSphere 🔥', style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Hi, ${svc.name} 👋', style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 12)),
                  ]),
                ]),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(10)),
                    child: Stack(children: [
                      const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      Positioned(top: 0, right: 0,
                          child: Container(width: 8, height: 8,
                              decoration: const BoxDecoration(
                                  color: AppTheme.accent, shape: BoxShape.circle))),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Live Steps from phone sensor
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FitnessTrackerScreen(showBackButton: true))),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.directions_walk_rounded,
                                color: AppTheme.green, size: 16)),
                        const SizedBox(width: 8),
                        Text('Steps', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                      ]),
                      const SizedBox(height: 10),
                      Text('${fitness.todaySteps}', style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fitness.stepProgress,
                          backgroundColor: AppTheme.darkCardLight,
                          valueColor: AlwaysStoppedAnimation(
                              fitness.stepProgress >= 1.0 ? AppTheme.green : AppTheme.primary),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('/ ${svc.stepGoal.toInt()} goal', style: GoogleFonts.poppins(
                          color: Colors.white38, fontSize: 11)),
                    ]),
                  ),
                )),
                const SizedBox(width: 12),
                // Live calories from Firebase meals
                Expanded(child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.local_fire_department_rounded,
                              color: AppTheme.orange, size: 16)),
                      const SizedBox(width: 8),
                      Text('Calories', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                    ]),
                    const SizedBox(height: 10),
                    Text('${svc.totalCaloriesToday.toInt()}', style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: svc.calorieGoal > 0
                            ? (svc.totalCaloriesToday / svc.calorieGoal).clamp(0.0, 1.0) : 0,
                        backgroundColor: AppTheme.darkCardLight,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.orange),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('/ ${svc.calorieGoal.toInt()} kcal goal', style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 11)),
                  ]),
                )),
              ]),
              const SizedBox(height: 10),

              // Distance + Active
              Row(children: [
                Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.straighten_rounded, color: AppTheme.teal, size: 18),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${fitness.distanceKm.toStringAsFixed(2)} km',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('Distance', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                    ]),
                  ]),
                )),
                const SizedBox(width: 10),
                Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.timer_outlined, color: AppTheme.purple, size: 18),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${fitness.activeMinutes} min',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('Active', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                    ]),
                  ]),
                )),
              ]),
              const SizedBox(height: 12),

              // Latest mood from Firebase
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MoodTrackerScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Text(svc.moods.isNotEmpty ? svc.moods.first['emoji'] ?? '😊' : '😊',
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Mood', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      Text(svc.moods.isNotEmpty ? svc.moods.first['label'] ?? 'Not logged' : 'Tap to log mood',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ])),
                    const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Quick actions
              Row(children: [
                Expanded(child: _ActionBtn(label: 'Workouts', color: AppTheme.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutsScreen())))),
                const SizedBox(width: 10),
                Expanded(child: _ActionBtn(label: 'Meditation', color: AppTheme.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeditationScreen())))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _ActionBtn(label: 'Food Log', color: AppTheme.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodLogScreen())))),
                const SizedBox(width: 10),
                Expanded(child: _ActionBtn(label: 'Progress', color: AppTheme.accent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen(showBackButton: true))))),
              ]),
              const SizedBox(height: 20),

              // Banners
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessTrackerScreen(showBackButton: true))),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('View Full Tracker →', style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DietTrackerScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.orange.withOpacity(0.3))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Diet Tracker', style: GoogleFonts.poppins(
                          color: AppTheme.orange, fontWeight: FontWeight.w600, fontSize: 13)),
                      Icon(Icons.arrow_forward_ios, color: AppTheme.orange, size: 14),
                    ]),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodTrackerScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.purple.withOpacity(0.3))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Mood Tracker', style: GoogleFonts.poppins(
                          color: AppTheme.purple, fontWeight: FontWeight.w600, fontSize: 13)),
                      Icon(Icons.arrow_forward_ios, color: AppTheme.purple, size: 14),
                    ]),
                  ),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final FirebaseService svc;
  const _AppDrawer({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.darkBg,
      child: SafeArea(child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2)),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 34)),
            const SizedBox(height: 12),
            Text(svc.name, style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            Text(svc.email, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          _DI(icon: Icons.home_rounded, label: 'Home', color: AppTheme.primary,
              onTap: () => Navigator.pop(context)),
          _DI(icon: Icons.monitor_heart_outlined, label: 'Fitness Tracker', color: AppTheme.teal,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessTrackerScreen(showBackButton: true))); }),
          _DI(icon: Icons.restaurant_menu_rounded, label: 'Diet Tracker', color: AppTheme.orange,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DietTrackerScreen())); }),
          _DI(icon: Icons.mood_rounded, label: 'Mood Tracker', color: AppTheme.purple,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodTrackerScreen())); }),
          _DI(icon: Icons.fitness_center_rounded, label: 'Workouts', color: AppTheme.green,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutsScreen())); }),
          _DI(icon: Icons.self_improvement_rounded, label: 'Meditation', color: AppTheme.purple,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MeditationScreen())); }),
          _DI(icon: Icons.fastfood_rounded, label: 'Food Log', color: AppTheme.orange,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodLogScreen())); }),
          _DI(icon: Icons.bar_chart_rounded, label: 'Progress', color: AppTheme.accent,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen(showBackButton: true))); }),
          Divider(color: AppTheme.darkCardLight, height: 24, indent: 16, endIndent: 16),
          _DI(icon: Icons.person_outline_rounded, label: 'Profile', color: AppTheme.primary,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen(showBackButton: true))); }),
          _DI(icon: Icons.edit_outlined, label: 'Edit Profile', color: AppTheme.teal,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())); }),
          _DI(icon: Icons.flag_outlined, label: 'Goals', color: AppTheme.yellow,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())); }),
          _DI(icon: Icons.notifications_outlined, label: 'Notifications', color: AppTheme.purple,
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())); }),
        ])),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await svc.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout_rounded, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                Text('Logout', style: GoogleFonts.poppins(
                    color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ),
        ),
      ])),
    );
  }
}

class _DI extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _DI({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18)),
    title: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(label, style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
    ),
  );
}
