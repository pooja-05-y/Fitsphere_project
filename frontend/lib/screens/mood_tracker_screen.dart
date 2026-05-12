import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});
  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  String? _selected;
  bool _saving = false;

  final _moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😄', 'label': 'Excited'},
    {'emoji': '😌', 'label': 'Calm'},
    {'emoji': '😤', 'label': 'Stressed'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '😠', 'label': 'Angry'},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseService>(
      builder: (context, svc, _) => Scaffold(
        backgroundColor: AppTheme.lightBg,
        appBar: AppBar(
          backgroundColor: AppTheme.lightBg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Mood Tracker', style: GoogleFonts.poppins(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
          actions: [
            if (svc.moods.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.textLight),
                onPressed: () => _confirmClear(context, svc),
              ),
          ],
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('How do you feel?', style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text('Tap a mood and tap Save — it syncs to Firebase instantly',
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),

            // Mood grid
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: _moods.map((m) {
                final sel = _selected == m['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selected = m['label']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: sel ? AppTheme.primary : AppTheme.lightBorder,
                          width: sel ? 2 : 1),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(m['emoji']!, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(m['label']!, style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: sel ? AppTheme.primary : AppTheme.textPrimary)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _selected == null || _saving ? null : () async {
                  setState(() => _saving = true);
                  final m = _moods.firstWhere((x) => x['label'] == _selected);
                  await svc.logMood(m['emoji']!, m['label']!);
                  setState(() { _saving = false; _selected = null; });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: [
                        Text(m['emoji']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('${m['label']} saved to Firebase! ✅',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                      ]),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.lightBorder,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_selected == null ? 'Select a mood first' : 'Save to Firebase',
                        style: GoogleFonts.poppins(
                            color: _selected == null ? AppTheme.textLight : Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 28),

            // History from Firebase (live)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Mood History', style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text('${svc.moods.length} entries',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 12),

            if (svc.moods.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.lightBorder)),
                child: Column(children: [
                  const Text('📊', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  Text('No moods logged yet', style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary, fontSize: 14)),
                  Text('Select a mood and tap Save', style: GoogleFonts.poppins(
                      color: AppTheme.textLight, fontSize: 12)),
                ]),
              )
            else
              ...svc.moods.map((log) => Dismissible(
                key: Key(log['id'] ?? log['time'] ?? ''),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: AppTheme.accent, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => svc.deleteMood(log['id'] ?? ''),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                  child: Row(children: [
                    Text(log['emoji'] ?? '😊', style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(log['label'] ?? '', style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                      Text(log['date'] ?? '', style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textLight)),
                    ])),
                    Text(log['time'] ?? '', style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
                ),
              )),
          ]),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, FirebaseService svc) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Clear Mood History', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      content: Text('Delete all moods from Firebase?',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); svc.clearMoods(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Clear', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    ));
  }
}
