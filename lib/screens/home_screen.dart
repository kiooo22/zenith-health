import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/main_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final uid = _auth.currentUser?.uid;

    return WillPopScope(
        onWillPop: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Keluar aplikasi'),
              content: const Text('Yakin untuk keluar aplikasi?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );

          if (result == true) {
            SystemNavigator.pop();
            return false;
          }

          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Zenith Health"),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                tooltip: 'Profil',
              ),
            ],
          ),
          body: Container(
            decoration: AppTheme.softBackground(color),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (uid != null)
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            _firestore.collection('users').doc(uid).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final userName = userData['name'] ?? 'Pengguna';
                            return _HeroCard(color: color, userName: userName);
                          }
                          return _HeroCard(color: color, userName: 'Pengguna');
                        },
                      )
                    else
                      _HeroCard(color: color, userName: 'Pengguna'),
                    const SizedBox(height: 20),
                    _TodayStatusCard(color: color),
                    const SizedBox(height: 12),
                    _HealthReminderCard(color: color),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: const MainBottomNav(currentIndex: 0),
        ));
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.color, required this.userName});

  final ColorScheme color;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.primary, color.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, $userName 👋",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Catat, refleksi, dan ukur kesejahteraan Kamu setiap hari.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: color.onPrimary.withOpacity(0.9)),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.onPrimary,
                    foregroundColor: color.primary,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/journalList'),
                  child: const Text("Buka jurnal"),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.self_improvement,
              color: Colors.white,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.color});

  final ColorScheme color;

  String _statusByHour(int hour) {
    if (hour < 11) return 'Pagi yang tenang';
    if (hour < 16) return 'Siang tetap mindful';
    if (hour < 20) return 'Sore jaga energi';
    return 'Malam untuk recovery';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final statusLabel = _statusByHour(now.hour);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.primary.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wb_sunny_outlined, color: color.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status hari ini: $statusLabel',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tanggal $dateLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthReminderCard extends StatelessWidget {
  const _HealthReminderCard({required this.color});

  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    final reminders = <String>[
      'Tarik napas selama 4 detik, tahan selama 7 detik dan buang perlahan selama 8 detik (4x) untuk menenangkan diri.',
      'Minum air putih sebelum lanjut aktivitas.',
      'Istirahat layar 5-15 menit tiap 1 jam.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_border, color: color.primary),
                const SizedBox(width: 8),
                Text(
                  'Reminder sehat',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...reminders.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        size: 18, color: color.primary.withOpacity(0.9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
