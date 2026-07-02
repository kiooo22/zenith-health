import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'services/chat_local_service.dart';
import 'theme/app_theme.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journaling_page.dart';
import 'screens/journal_list_page.dart';
import 'screens/dass21_page.dart';
import 'screens/dass21_history_page.dart';
import 'screens/dass21_chart_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load();
  await initializeDateFormatting('id');
  // await Hive.initFlutter();
  // await ChatLocalService.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mental Health App',
      theme: AppTheme.lightTheme(),
      home: const SplashScreen(),
      routes: {
        '/gate': (context) => const AppEntryGate(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/journals': (context) => const JournalingPage(),
        '/journalList': (context) => const JournalListPage(),
        '/dass21': (context) => const Dass21Page(),
        '/dass21_history': (context) =>
            const Dass21HistoryPage(), // ✅ perbaikan
        '/dass21_chart': (context) => const Dass21ChartPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _signOutScheduled = false;

  Future<bool> _hasProfile(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      debugPrint('Profile check failed [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Profile check unknown error: $e');
      return false;
    }
  }

  Widget _buildLoading() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final user = authSnapshot.data;
        if (user == null) {
          _signOutScheduled = false;
          return const LoginScreen();
        }

        return FutureBuilder<bool>(
          future: _hasProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }

            final hasProfile = profileSnapshot.data ?? false;
            if (hasProfile) {
              _signOutScheduled = false;
              return const HomeScreen();
            }

            if (!_signOutScheduled) {
              _signOutScheduled = true;
              Future.microtask(() async {
                await FirebaseAuth.instance.signOut();
              });
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
