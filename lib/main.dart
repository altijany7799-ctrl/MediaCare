import 'screens/doctor_dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/doctor_applications_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/doctor_admin_screen.dart';

const String adminUid = '4SRutGLlc3QxKUURSymYwWCNb9H3';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MediCareApp());
}

class MediCareApp extends StatelessWidget {
  const MediCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediCare',
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D6E78),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D6E78),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6E78),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const String adminUid =
      '4SRutGLlc3QxKUURSymYwWCNb9H3';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authSnapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('تعذر التحقق من تسجيل الدخول'),
            ),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen(
            key: ValueKey('login_screen'),
          );
        }

        if (user.uid == adminUid) {
          return const DoctorApplicationsScreen();
        }

        return FutureBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('doctorApplications')
              .doc(user.uid)
              .get(),
          builder: (context, doctorSnapshot) {
            if (doctorSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (doctorSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'تعذر التحقق من حالة حساب الطبيب',
                  ),
                ),
              );
            }

            final application = doctorSnapshot.data;

            if (application != null &&
                application.exists) {
              final status =
                  application.data()?['status'];

              if (status == 'approved') {
                return const DoctorDashboardScreen();
              }

              return Scaffold(
                appBar: AppBar(
                  title: const Text('طلب حساب الطبيب'),
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      status == 'rejected'
                          ? 'تم رفض طلبك. يرجى التواصل مع الإدارة.'
                          : 'طلبك قيد المراجعة. انتظر موافقة الإدارة.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              );
            }

            return const HomeScreen(
              key: ValueKey('home_screen'),
            );
          },
        );
      },
    );
  }
}