import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:guideme/core/translate_cubit.dart';
import 'package:guideme/place/place_screen.dart';
import 'package:guideme/profile/profile.dart';
import 'package:guideme/guide/profileGuide.dart';
import 'package:guideme/welcome/welcome_screen.dart';
import 'core/recommend_cubit.dart';
import 'guide/GuideBookingsScreen.dart';
import 'auth/forgetpassword.dart';
import 'auth/guide_register.dart';
import 'guide/guide_screen.dart';
import 'auth/login_screen.dart';
import 'guide/homeguide.dart';
import 'recommendation.dart';
import 'auth/register_screen.dart';
import 'place/place_model.dart';
import 'welcome/home_screen.dart';

late List<Place> places = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();

  places = await loadPlacesFromCsv();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
        Locale('de'),
        Locale('it'),
        Locale('tr'),
        Locale('es'),
        Locale('hi'),
        Locale('ur'),
        Locale('bn'),
        Locale('id'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: const AppWrapper(),
    ),
  );
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TranslationCubit>(create: (_) => TranslationCubit()),
        BlocProvider<RecommendationCubit>(create: (_) => RecommendationCubit()),
      ],
      child: MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guide Me',
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterUserScreen(),
        '/registerGuide': (context) => const RegisterGuideScreen(),
        '/userHome': (_) => const PlacesAndGuidesScreen(),
        '/forgotPassword': (_) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/places': (context) => const PlacesScreen(),
        '/GuideBookingsScreen': (context) => const GuideBookingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/guide': (context) => const GuidesScreen(),
        '/ProfileGuideScreen': (context) => const ProfileGuideScreen(),
        '/homeGuide': (context) => const HomeGuideScreen(),
      },
    );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const FirstPage();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const LoginPage();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final type = data['type'];
        final status = data['status'];

        if (type == 'user') {
          return const PlacesAndGuidesScreen();
        } else if (type == 'guide') {
          if (status == 'approved') {
            return const HomeScreen();
          } else {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info, size: 80, color: Colors.orange),
                    const SizedBox(height: 20),
                    const Text(
                      'حسابك قيد المراجعة من قبل الإدارة.\nيرجى الانتظار حتى يتم الموافقة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('تسجيل الخروج'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            // شاشة تقول "نحن نراجع حسابك"
          }
        }

        return const FirstPage(); // fallback
      },
    );
  }
}