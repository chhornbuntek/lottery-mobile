import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottery/core/config.dart';
import 'package:lottery/core/firebase_option.dart';
import 'package:lottery/core/firebase_service.dart';
import 'package:lottery/feature/login-register/service/auth_service.dart';
import 'package:lottery/feature/main_screen/service/data_service.dart';
import 'package:lottery/feature/login-register/view/login_screen.dart';
import 'package:lottery/feature/main_screen/view/view_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Services
  Get.put(AuthService());
  Get.put(DataService());
  Get.put(FirebaseService());

  runApp(const LotteryApp());
}

class LotteryApp extends StatelessWidget {
  const LotteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dataService = Get.find<DataService>();

      // Show loading while checking authentication
      if (dataService.isLoading) {
        return const Scaffold(
          backgroundColor: Color(0xFF2C5F5F),
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }

      // Navigate based on authentication status
      if (dataService.isAuthenticated) {
        return const MainScreen();
      } else {
        return const LoginScreen();
      }
    });
  }
}
