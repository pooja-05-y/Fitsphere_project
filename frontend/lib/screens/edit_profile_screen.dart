import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late String _gender;
  late String _goal;
  bool _saving = false;
  bool _init = false;

  final _genders = ['Male', 'Female', 'Other'];
  final _goals = ['Lose Weight', 'Build Muscle', 'Stay Fit', 'Improve Endurance'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final svc = context.read<FirebaseService>();
      _nameCtrl = TextEditingController(text: svc.name);
      _emailCtrl = TextEditingController(text: svc.email);
      _phoneCtrl = TextEditingController(text: svc.phone);
      _ageCtrl = TextEditingController(text: svc.age.toString());
      _weightCtrl = TextEditingController(text: svc.weight.toString());
      _heightCtrl = TextEditingController(text: svc.height.toString());
      _gender = svc.gender;
      _goal = svc.primaryGoal;
      _init = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _ageCtrl.dispose(); _weightCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<FirebaseService>().saveProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 25,
      weight: double.tryParse(_weightCtrl.text) ?? 70,
      height: double.tryParse(_heightCtrl.text) ?? 175,
      gender: _gender,
      goal: _goal,
    );
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile saved to Firebase! ✅',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: GoogleFonts.poppins(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Save', style: GoogleFonts.poppins(
                color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Stack(children: [
              Container(width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.1)),
                child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 50)),
              Positioned(bottom: 0, right: 0,
                child: Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14))),
            ]),
          ),
          const SizedBox(height: 28),

          _sec('Personal Information'),
          const SizedBox(height: 12),
          _field('Full Name', _nameCtrl, Icons.person_outline),
          const SizedBox(height: 12),
          _field('Email', _emailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field('Phone', _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
          const SizedBox(height: 20),

          _sec('Body Metrics'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Age', _ageCtrl, Icons.cake_outlined, type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field('Weight (kg)', _weightCtrl, Icons.monitor_weight_outlined, type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field('Height (cm)', _heightCtrl, Icons.height_rounded, type: TextInputType.number)),
          ]),
          const SizedBox(height: 20),

          _sec('Gender'),
          const SizedBox(height: 12),
          Row(children: _genders.map((g) {
            final sel = _gender == g;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: Container(
                margin: EdgeInsets.only(right: g == _genders.last ? 0 : 10),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.lightBorder),
                ),
                alignment: Alignment.center,
                child: Text(g, style: GoogleFonts.poppins(
                    color: sel ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500, fontSize: 13)),
              ),
            ));
          }).toList()),
          const SizedBox(height: 20),

          _sec('Primary Goal'),
          const SizedBox(height: 12),
          ..._goals.map((g) {
            final sel = _goal == g;
            return GestureDetector(
              onTap: () => setState(() => _goal = g),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.lightBorder,
                      width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: sel ? AppTheme.primary : AppTheme.textLight, size: 20),
                  const SizedBox(width: 12),
                  Text(g, style: GoogleFonts.poppins(
                      color: sel ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
                ]),
              ),
            );
          }),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('Save to Firebase', style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sec(String t) => Text(t, style: GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: type,
        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.textLight, size: 18),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
      ),
    ]);
  }
}
