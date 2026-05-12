import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/fitness_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialise Firebase — if firebase_options.dart doesn't exist yet,
  // the app still runs using local data only
  try {
    // ignore: undefined_identifier
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured yet — app runs without it
  }

  await FitnessService().init();
  runApp(const FitSphereApp());
}

class FitSphereApp extends StatelessWidget {
  const FitSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FirebaseService>.value(
            value: FirebaseService()),
        ChangeNotifierProvider<FitnessService>.value(
            value: FitnessService()),
      ],
      child: MaterialApp(
        title: 'FitSphere',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}

