import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/fitness_service.dart';

class FitnessTrackerScreen extends StatefulWidget {
  final bool showBackButton;
  const FitnessTrackerScreen({super.key, this.showBackButton = false});

  @override
  State<FitnessTrackerScreen> createState() => _FitnessTrackerScreenState();
}

class _FitnessTrackerScreenState extends State<FitnessTrackerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _hrZone(double hr) {
    if (hr < 60) return 'Resting';
    if (hr < 100) return 'Normal';
    if (hr < 140) return 'Aerobic';
    return 'High';
  }

  Color _hrColor(double hr) {
    if (hr < 60) return AppTheme.primary;
    if (hr < 100) return AppTheme.green;
    if (hr < 140) return AppTheme.yellow;
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessService>(
      builder: (context, svc, _) => Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: AppTheme.darkBg,
          automaticallyImplyLeading: false,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context))
              : null,
          title: Text('Fitness Tracker',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.green.withOpacity(0.4 + 0.6 * _pulse.value),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('LIVE',
                      style: GoogleFonts.poppins(
                          color: AppTheme.green, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ]),
              ),
            ),
          ],
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status banner ──────────────────────────────────────────────
              if (!svc.pedometerAvailable)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.yellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.yellow.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppTheme.yellow, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Step sensor unavailable on this device. Make sure activity permission is granted.',
                        style: GoogleFonts.poppins(color: AppTheme.yellow, fontSize: 11),
                      ),
                    ),
                  ]),
                ),

              // ── Step ring ──────────────────────────────────────────────────
              Center(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow
                      Container(
                        width: 190 + (6 * _pulse.value),
                        height: 190 + (6 * _pulse.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withOpacity(0.04 * _pulse.value),
                        ),
                      ),
                      SizedBox(
                        width: 178, height: 178,
                        child: CircularProgressIndicator(
                          value: svc.stepProgress,
                          strokeWidth: 13,
                          backgroundColor: AppTheme.darkCardLight,
                          valueColor: AlwaysStoppedAnimation(
                            svc.stepProgress >= 1.0 ? AppTheme.green : AppTheme.primary,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${svc.todaySteps}',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700)),
                        Text('/ ${svc.stepGoal} steps',
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: svc.pedometerStatus == 'walking'
                                ? AppTheme.green.withOpacity(0.2)
                                : AppTheme.darkCardLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            svc.pedometerStatus == 'walking' ? '🚶 Walking' : '🧍 Still',
                            style: GoogleFonts.poppins(
                                color: svc.pedometerStatus == 'walking'
                                    ? AppTheme.green
                                    : Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  svc.stepProgress >= 1.0
                      ? '🎉 Daily goal reached!'
                      : '${(svc.stepGoal - svc.todaySteps).clamp(0, svc.stepGoal)} steps to your goal',
                  style: GoogleFonts.poppins(
                      color: svc.stepProgress >= 1.0 ? AppTheme.green : Colors.white38,
                      fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),

              // ── Live stats row ─────────────────────────────────────────────
              Row(children: [
                Expanded(child: _LiveCard(icon: Icons.local_fire_department_rounded, color: AppTheme.orange, label: 'Calories', value: svc.caloriesBurned.toStringAsFixed(0), unit: 'kcal')),
                const SizedBox(width: 10),
                Expanded(child: _LiveCard(icon: Icons.straighten_rounded, color: AppTheme.teal, label: 'Distance', value: svc.distanceKm.toStringAsFixed(2), unit: 'km')),
                const SizedBox(width: 10),
                Expanded(child: _LiveCard(icon: Icons.timer_outlined, color: AppTheme.purple, label: 'Active', value: '${svc.activeMinutes}', unit: 'min')),
              ]),
              const SizedBox(height: 14),

              // ── Heart rate ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Icon(Icons.favorite_rounded,
                        color: AppTheme.accent.withOpacity(0.5 + 0.5 * _pulse.value), size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Heart Rate', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    Text('${svc.heartRate.toInt()} BPM',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _hrColor(svc.heartRate).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_hrZone(svc.heartRate),
                        style: GoogleFonts.poppins(
                            color: _hrColor(svc.heartRate), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Hourly bar chart ──────────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Steps by Hour', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                Text('Today', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              Container(
                height: 160,
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1500,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.darkCardLight,
                      getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                        '${rod.toY.toInt()}\n${g.x}:00',
                        GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}h',
                          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9)),
                    )),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(24, (i) {
                    final steps = svc.hourlySteps[i].toDouble();
                    final isCurrent = i == DateTime.now().hour;
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: steps,
                        width: 9,
                        color: isCurrent ? AppTheme.primary : steps > 0 ? AppTheme.primary.withOpacity(0.45) : AppTheme.darkCardLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ]);
                  }),
                )),
              ),
              const SizedBox(height: 20),

              // ── Weekly line chart ─────────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('This Week', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(
                  'Avg ${(svc.weeklySteps.reduce((a, b) => a + b) / 7).toInt()} steps',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                height: 170,
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
                child: LineChart(LineChartData(
                  minY: 0,
                  maxY: (svc.stepGoal * 1.3),
                  lineTouchData: LineTouchData(
                    touchTooltipData: const LineTouchTooltipData(),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final i = v.toInt();
                        return i >= 0 && i < 7
                            ? Text(days[i], style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10))
                            : const Text('');
                      },
                    )),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    horizontalInterval: svc.stepGoal / 3,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.darkCardLight, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Goal dashed line
                    LineChartBarData(
                      spots: List.generate(7, (i) => FlSpot(i.toDouble(), svc.stepGoal.toDouble())),
                      isCurved: false,
                      color: AppTheme.green.withOpacity(0.45),
                      barWidth: 1.5,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                    // Actual steps
                    LineChartBarData(
                      spots: List.generate(7, (i) => FlSpot(i.toDouble(), svc.weeklySteps[i].toDouble())),
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, i) => FlDotCirclePainter(
                          radius: i == 6 ? 5 : 3,
                          color: i == 6 ? AppTheme.primary : AppTheme.primary.withOpacity(0.7),
                          strokeWidth: 2,
                          strokeColor: AppTheme.darkBg,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [AppTheme.primary.withOpacity(0.3), AppTheme.primary.withOpacity(0.0)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                )),
              ),
              const SizedBox(height: 20),

              // ── Calorie balance ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Calorie Balance', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _CalorieItem(label: 'Consumed', value: '${svc.caloriesConsumed.toInt()}', color: AppTheme.orange),
                    Text('−', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 22)),
                    _CalorieItem(label: 'Burned', value: '${svc.caloriesBurned.toInt()}', color: AppTheme.teal),
                    Text('=', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 22)),
                    _CalorieItem(
                      label: 'Net',
                      value: '${(svc.caloriesConsumed - svc.caloriesBurned).toInt()}',
                      color: (svc.caloriesConsumed - svc.caloriesBurned) < 600 ? AppTheme.green : AppTheme.accent,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (svc.caloriesBurned / svc.caloriesConsumed).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.darkCardLight,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.teal),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${((svc.caloriesBurned / svc.caloriesConsumed) * 100).toStringAsFixed(1)}% of calories consumed have been burned',
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Step goal slider ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Adjust Step Goal', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('${svc.stepGoal}', style: GoogleFonts.poppins(color: AppTheme.primary, fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.darkCardLight,
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withOpacity(0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: svc.stepGoal.toDouble(),
                      min: 1000, max: 20000, divisions: 19,
                      onChanged: (v) => svc.setStepGoal(v.toInt()),
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('1k', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                    Text('20k', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                  ]),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final IconData icon; final Color color; final String label; final String value; final String unit;
  const _LiveCard({required this.icon, required this.color, required this.label, required this.value, required this.unit});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      Text(unit, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
      Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
    ]),
  );
}

class _CalorieItem extends StatelessWidget {
  final String label; final String value; final Color color;
  const _CalorieItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.poppins(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
    Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
  ]);
}