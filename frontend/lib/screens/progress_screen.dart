import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/fitness_service.dart';

class ProgressScreen extends StatelessWidget {
  final bool showBackButton;
  const ProgressScreen({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirebaseService, FitnessService>(
      builder: (context, svc, fitness, _) {
        final weekly = fitness.weeklySteps;
        final avgSteps = weekly.isEmpty
            ? 0
            : weekly.reduce((a, b) => a + b) ~/ weekly.length;
        final todayMeals = svc.todayMeals;
        final totalCal = svc.totalCaloriesToday;
        final calGoal = svc.calorieGoal;
        final calBurned = fitness.caloriesBurned;
        final netCal = totalCal - calBurned;

        return Scaffold(
          backgroundColor: AppTheme.lightBg,
          appBar: AppBar(
            backgroundColor: AppTheme.lightBg,
            automaticallyImplyLeading: false,
            leading: showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppTheme.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context))
                : null,
            title: Text('Progress',
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

                // ── Live stats grid ──────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _LiveCard(
                      icon: Icons.directions_walk_rounded,
                      color: AppTheme.primary,
                      label: 'Steps Today',
                      value: '${fitness.todaySteps}',
                      sub: '/ ${svc.stepGoal.toInt()} goal',
                      progress: fitness.stepProgress,
                    ),
                    _LiveCard(
                      icon: Icons.local_fire_department_rounded,
                      color: AppTheme.orange,
                      label: 'Cal Consumed',
                      value: '${totalCal.toInt()}',
                      sub: '/ ${calGoal.toInt()} goal',
                      progress: calGoal > 0
                          ? (totalCal / calGoal).clamp(0.0, 1.0)
                          : 0.0,
                    ),
                    _LiveCard(
                      icon: Icons.fitness_center_rounded,
                      color: AppTheme.green,
                      label: 'Cal Burned',
                      value: '${calBurned.toInt()}',
                      sub: 'from activity',
                      progress: calGoal > 0
                          ? (calBurned / calGoal).clamp(0.0, 1.0)
                          : 0.0,
                    ),
                    _LiveCard(
                      icon: Icons.straighten_rounded,
                      color: AppTheme.teal,
                      label: 'Distance',
                      value: '${fitness.distanceKm.toStringAsFixed(2)} km',
                      sub: '${fitness.activeMinutes} active min',
                      progress: 0,
                      showBar: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Calorie balance ──────────────────────────────────────────
                Text('Calorie Balance — Today',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _CalPill(label: 'Consumed',
                            value: '${totalCal.toInt()}', color: AppTheme.orange),
                        Text('−', style: GoogleFonts.poppins(
                            color: AppTheme.textLight, fontSize: 22)),
                        _CalPill(label: 'Burned',
                            value: '${calBurned.toInt()}', color: AppTheme.teal),
                        Text('=', style: GoogleFonts.poppins(
                            color: AppTheme.textLight, fontSize: 22)),
                        _CalPill(
                          label: 'Net',
                          value: '${netCal.toInt()}',
                          color: netCal < calGoal
                              ? AppTheme.green
                              : AppTheme.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: calGoal > 0
                            ? (totalCal / calGoal).clamp(0.0, 1.0)
                            : 0,
                        backgroundColor: Colors.orange.shade100,
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.orange),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      calGoal > 0
                          ? '${(totalCal / calGoal * 100).toStringAsFixed(0)}% of ${calGoal.toInt()} kcal daily goal consumed'
                          : 'Set your calorie goal in Goals screen',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Weekly steps chart ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weekly Steps',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text('Avg: $avgSteps/day',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 180,
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: LineChart(LineChartData(
                    minY: 0,
                    maxY: (svc.stepGoal * 1.3),
                    lineTouchData: const LineTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                            final i = v.toInt();
                            return i >= 0 && i < 7
                                ? Text(days[i], style: GoogleFonts.poppins(
                                    color: AppTheme.textLight, fontSize: 10))
                                : const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: svc.stepGoal > 0 ? svc.stepGoal / 3 : 3000,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: AppTheme.lightBorder, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Goal dashed line
                      LineChartBarData(
                        spots: List.generate(7,
                            (i) => FlSpot(i.toDouble(), svc.stepGoal)),
                        isCurved: false,
                        color: AppTheme.green.withOpacity(0.4),
                        barWidth: 1.5,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                      ),
                      // Actual steps
                      LineChartBarData(
                        spots: List.generate(7, (i) => FlSpot(
                            i.toDouble(),
                            i < weekly.length ? weekly[i].toDouble() : 0)),
                        isCurved: true,
                        color: AppTheme.primary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, i) => FlDotCirclePainter(
                            radius: i == 6 ? 5 : 3,
                            color: AppTheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.2),
                              AppTheme.primary.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  )),
                ),
                const SizedBox(height: 20),

                // ── Today's meals from Firebase ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Meals",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text('${todayMeals.length} items · ${totalCal.toInt()} kcal',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),

                if (todayMeals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.lightBorder),
                    ),
                    child: Row(children: [
                      const Text('🍽️', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Text('No meals logged today',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 14)),
                    ]),
                  )
                else
                  ...todayMeals.map((m) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(m['type'] ?? '',
                            style: GoogleFonts.poppins(
                                color: AppTheme.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['name'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary)),
                            Text(m['time'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: AppTheme.textLight)),
                          ])),
                      Text('${(m['calories'] as num).toInt()} kcal',
                          style: GoogleFonts.poppins(
                              color: AppTheme.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ]),
                  )),
                const SizedBox(height: 20),

                // ── Mood history from Firebase ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Moods',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text('${svc.moods.length} logged',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),

                if (svc.moods.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.lightBorder),
                    ),
                    child: Row(children: [
                      const Text('😊', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Text('No moods logged yet',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 14)),
                    ]),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10)],
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: svc.moods.take(10).map((m) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.lightBorder),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(m['emoji'] ?? '',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(m['label'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary)),
                              Text(m['time'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppTheme.textLight)),
                            ],
                          ),
                        ]),
                      )).toList(),
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Workouts from Firebase ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Workouts',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text('${svc.workouts.length} total · ${svc.workoutsThisWeek} this week',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),

                if (svc.workouts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.lightBorder),
                    ),
                    child: Row(children: [
                      const Text('💪', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Text('No workouts logged yet',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 14)),
                    ]),
                  )
                else
                  ...svc.workouts.take(5).map((w) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fitness_center_rounded,
                            color: AppTheme.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w['type'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary)),
                            Text('${w['duration']} min · ${w['date']}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ])),
                      Text('${w['calories']} kcal',
                          style: GoogleFonts.poppins(
                              color: AppTheme.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ]),
                  )),
                const SizedBox(height: 20),

                // ── Summary card ─────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppTheme.yellow, AppTheme.orange]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall Summary',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SumStat(emoji: '💪',
                              value: '${svc.workouts.length}',
                              label: 'Workouts'),
                          _SumStat(emoji: '🍽️',
                              value: '${svc.meals.length}',
                              label: 'Meals'),
                          _SumStat(emoji: '😊',
                              value: '${svc.moods.length}',
                              label: 'Moods'),
                          _SumStat(emoji: '👟',
                              value: '${fitness.todaySteps}',
                              label: 'Steps'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _LiveCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value, sub;
  final double progress;
  final bool showBar;

  const _LiveCard({
    required this.icon, required this.color, required this.label,
    required this.value, required this.sub, required this.progress,
    this.showBar = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.poppins(
            color: AppTheme.textSecondary, fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 8),
      Text(value, style: GoogleFonts.poppins(
          color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      Text(sub, style: GoogleFonts.poppins(
          color: AppTheme.textLight, fontSize: 10)),
      if (showBar) ...[
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    ]),
  );
}

class _CalPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CalPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.poppins(
        color: color, fontSize: 18, fontWeight: FontWeight.w700)),
    Text(label, style: GoogleFonts.poppins(
        color: AppTheme.textSecondary, fontSize: 11)),
  ]);
}

class _SumStat extends StatelessWidget {
  final String emoji, value, label;
  const _SumStat({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 22)),
    const SizedBox(height: 4),
    Text(value, style: GoogleFonts.poppins(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
  ]);
}