import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/main_bottom_nav.dart';
import 'dass21_detail_page.dart';

class Dass21HistoryPage extends StatelessWidget {
  const Dass21HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Pengguna tidak ditemukan.")),
      );
    }

    final resultsRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("dass21_results")
        .orderBy("created_at", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Tes DASS-21"),
        actions: [
          IconButton(
            tooltip: 'Tes DASS baru',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, '/dass21'),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.softBackground(Theme.of(context).colorScheme),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: resultsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              String message = "Terjadi kesalahan saat memuat data.";

              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                message =
                    "Akses ditolak Firestore Rules (permission-denied). Cek rules koleksi dass21_results.";
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(message, textAlign: TextAlign.center),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text("Belum ada hasil tes DASS-21."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final createdAt = (data['created_at'] as Timestamp?)?.toDate();
                final hasAI =
                    (data['ai_recommendation'] as String?)?.trim().isNotEmpty ??
                        false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Dass21DetailPage(data: data),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Depresi: ${data['depression'] ?? '-'} "
                            "(${data['depression_category'] ?? '-'})\n"
                            "Kecemasan: ${data['anxiety'] ?? '-'} "
                            "(${data['anxiety_category'] ?? '-'})\n"
                            "Stres: ${data['stress'] ?? '-'} "
                            "(${data['stress_category'] ?? '-'})",
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  createdAt != null
                                      ? DateFormat('dd MMM yyyy, HH:mm')
                                          .format(createdAt)
                                      : "Tanggal tidak tersedia",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (hasAI) ...[
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Lihat saran AI",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }
}
