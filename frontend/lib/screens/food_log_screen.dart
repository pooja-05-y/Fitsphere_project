import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});
  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  String _type = 'Breakfast';
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  bool _saving = false;
  final _types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  final _quick = [
    {'emoji': '🍎', 'name': 'Apple', 'cal': 95.0},
    {'emoji': '🍌', 'name': 'Banana', 'cal': 105.0},
    {'emoji': '🥚', 'name': 'Egg', 'cal': 78.0},
    {'emoji': '🍚', 'name': 'Rice (cup)', 'cal': 206.0},
    {'emoji': '🍗', 'name': 'Chicken', 'cal': 165.0},
    {'emoji': '🥦', 'name': 'Broccoli', 'cal': 55.0},
  ];

  @override
  void dispose() { _nameCtrl.dispose(); _calCtrl.dispose(); super.dispose(); }

  Future<void> _save(FirebaseService svc) async {
    final name = _nameCtrl.text.trim();
    final cal = double.tryParse(_calCtrl.text.trim());
    if (name.isEmpty || cal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter food name and calories'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _saving = true);
    await svc.logMeal(type: _type, foodName: name, calories: cal);
    _nameCtrl.clear(); _calCtrl.clear();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$name saved to Firebase! ✅',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseService>(
      builder: (context, svc, _) {
        final todayMeals = svc.todayMeals;
        final total = svc.totalCaloriesToday;
        return Scaffold(
          backgroundColor: AppTheme.lightBg,
          appBar: AppBar(
            backgroundColor: AppTheme.lightBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Food Logging', style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Calorie summary — live from Firebase
              Container(
                width: double.infinity, padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.orange, const Color(0xFFEA580C)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Today\'s Calories', style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 13)),
                    Text('${total.toInt()} kcal', style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    Text('Goal: ${svc.calorieGoal.toInt()} kcal', style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 12)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${todayMeals.length}', style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    Text('meals today', style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 13)),
                    Text('${((svc.calorieGoal - total).toInt()).clamp(0, 99999)} remaining',
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
                  ]),
                ]),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: svc.calorieGoal > 0
                      ? (total / svc.calorieGoal).clamp(0.0, 1.0) : 0,
                  backgroundColor: Colors.orange.shade100,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.orange),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),

              // Meal type
              Text('Meal Type', style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView(scrollDirection: Axis.horizontal,
                  children: _types.map((t) {
                    final sel = _type == t;
                    return GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? AppTheme.primary : AppTheme.lightBorder),
                        ),
                        child: Text(t, style: GoogleFonts.poppins(
                            color: sel ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.w500, fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Food name + calories
              _buildField(_nameCtrl, 'Food name (e.g. Banana)', TextInputType.text),
              const SizedBox(height: 10),
              _buildField(_calCtrl, 'Calories (kcal)', TextInputType.number),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _save(svc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('+ Add Meal', style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 20),

              // Quick add
              Text('Quick Add', style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3, shrinkWrap: true,
                crossAxisSpacing: 10, mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                children: _quick.map((item) => GestureDetector(
                  onTap: () async {
                    await svc.logMeal(
                        type: _type,
                        foodName: item['name'] as String,
                        calories: item['cal'] as double);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${item['name']} added! ✅',
                            style: GoogleFonts.poppins(color: Colors.white)),
                        backgroundColor: AppTheme.green,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(item['emoji'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(item['name'] as String, style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${(item['cal'] as double).toInt()} kcal', style: GoogleFonts.poppins(
                          fontSize: 10, color: AppTheme.textSecondary)),
                    ]),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Today's log — live from Firebase
              if (todayMeals.isNotEmpty) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Today's Log", style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text('${todayMeals.length} items', style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textSecondary)),
                ]),
                const SizedBox(height: 10),
                ...todayMeals.map((meal) => Dismissible(
                  key: Key(meal['id'] ?? meal['time'] ?? ''),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => svc.deleteMeal(meal['id'] ?? ''),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(meal['type'] ?? '', style: GoogleFonts.poppins(
                            color: AppTheme.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(meal['name'] ?? '', style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                        Text(meal['time'] ?? '', style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.textLight)),
                      ])),
                      Text('${(meal['calories'] as num).toInt()} kcal', style: GoogleFonts.poppins(
                          color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 15)),
                    ]),
                  ),
                )),
              ] else Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.lightBorder)),
                child: Column(children: [
                  const Text('🍽️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  Text('No meals logged today', style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary, fontSize: 14)),
                  Text('Add your first meal above', style: GoogleFonts.poppins(
                      color: AppTheme.textLight, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, TextInputType type) =>
      TextField(
        controller: ctrl, keyboardType: type,
        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 14),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
      );
}
