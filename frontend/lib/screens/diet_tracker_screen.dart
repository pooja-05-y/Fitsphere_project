import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'food_log_screen.dart';

class DietTrackerScreen extends StatelessWidget {
  const DietTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseService>(
      builder: (context, svc, _) {
        final todayMeals = svc.todayMeals;
        final totalCal = svc.totalCaloriesToday;
        final goal = svc.calorieGoal;
        final progress = goal > 0 ? (totalCal / goal).clamp(0.0, 1.0) : 0.0;

        return Scaffold(
          backgroundColor: AppTheme.lightBg,
          appBar: AppBar(
            backgroundColor: AppTheme.lightBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: AppTheme.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Diet Tracker',
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Calorie ring ────────────────────────────────────────────
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          backgroundColor: Colors.orange.shade100,
                          valueColor: AlwaysStoppedAnimation(
                            totalCal > goal && goal > 0
                                ? AppTheme.accent
                                : AppTheme.orange,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          '${totalCal.toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '/ ${goal.toInt()} kcal',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal > 0
                              ? '${((1 - progress) * goal).toInt().clamp(0, 99999)} kcal remaining'
                              : 'Set goal in Goals screen',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Macro summary row
                Row(children: [
                  Expanded(child: _MacroCard(
                    label: 'Consumed', value: '${totalCal.toInt()}',
                    unit: 'kcal', color: AppTheme.orange)),
                  const SizedBox(width: 10),
                  Expanded(child: _MacroCard(
                    label: 'Goal', value: '${goal.toInt()}',
                    unit: 'kcal', color: AppTheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _MacroCard(
                    label: 'Meals', value: '${todayMeals.length}',
                    unit: 'today', color: AppTheme.green)),
                ]),
                const SizedBox(height: 20),

                // ── Add meal button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FoodLogScreen()),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Add Meal',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Today's meals from Firebase ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Meals",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text('${todayMeals.length} logged',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),

                if (todayMeals.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.lightBorder),
                    ),
                    child: Column(children: [
                      const Text('🍽️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No meals logged today',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Tap "Add Meal" to log your first meal',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textLight, fontSize: 12)),
                    ]),
                  )
                else
                  // Group meals by type
                  ...['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                    final typeMeals = todayMeals
                        .where((m) => m['type'] == type)
                        .toList();
                    if (typeMeals.isEmpty) return const SizedBox.shrink();
                    final typeTotal = typeMeals.fold(
                        0.0, (sum, m) => sum + (m['calories'] as num).toDouble());
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Text(_mealEmoji(type),
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(type,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary)),
                              ]),
                              Text('${typeTotal.toInt()} kcal',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.orange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        ...typeMeals.map((meal) => Dismissible(
                          key: Key(meal['id'] ?? meal['time'] ?? '${meal['name']}${meal['time']}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            final id = meal['id'] ?? '';
                            if (id.isNotEmpty) svc.deleteMeal(id);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8)],
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(meal['name'] ?? '',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppTheme.textPrimary)),
                                    Text(meal['time'] ?? '',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppTheme.textLight)),
                                  ],
                                ),
                              ),
                              Text(
                                '${(meal['calories'] as num).toInt()} kcal',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.orange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15),
                              ),
                            ]),
                          ),
                        )),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),

                // ── Weekly summary ───────────────────────────────────────────
                if (svc.meals.length > todayMeals.length) ...[
                  const SizedBox(height: 8),
                  Text('All Logged Meals',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Total meals logged',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        Text('${svc.meals.length}',
                            style: GoogleFonts.poppins(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Today\'s total',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        Text('${totalCal.toInt()} kcal',
                            style: GoogleFonts.poppins(
                                color: AppTheme.orange,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ]),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _mealEmoji(String type) {
    switch (type) {
      case 'Breakfast': return '🌅';
      case 'Lunch': return '☀️';
      case 'Dinner': return '🌙';
      case 'Snack': return '🍎';
      default: return '🍽️';
    }
  }
}

class _MacroCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _MacroCard({required this.label, required this.value,
      required this.unit, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Text(value, style: GoogleFonts.poppins(
          color: color, fontSize: 18, fontWeight: FontWeight.w700)),
      Text(unit, style: GoogleFonts.poppins(
          color: color.withOpacity(0.7), fontSize: 10)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.poppins(
          color: AppTheme.textSecondary, fontSize: 11),
          textAlign: TextAlign.center),
    ]),
  );
}