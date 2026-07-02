import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/main_bottom_nav.dart';

class Dass21ChartPage extends StatelessWidget {
  const Dass21ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Kamu belum login")),
      );
    }

    final resultsRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("dass21_results")
        .orderBy("created_at", descending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grafik DASS-21"),
      ),
      body: Container(
        decoration: AppTheme.softBackground(Theme.of(context).colorScheme),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: resultsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              String message = "Terjadi kesalahan";

              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                message =
                    "Akses ditolak Firestore Rules (permission-denied) untuk dass21_results.";
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text("Belum ada hasil tes DASS-21"));
            }

            final depressionScores = <FlSpot>[];
            final anxietyScores = <FlSpot>[];
            final stressScores = <FlSpot>[];
            final labels = <String>[];

            for (int i = 0; i < docs.length; i++) {
              final data = docs[i].data();
              final depression = (data['depression'] ?? 0).toDouble();
              final anxiety = (data['anxiety'] ?? 0).toDouble();
              final stress = (data['stress'] ?? 0).toDouble();

              depressionScores.add(FlSpot(i.toDouble(), depression));
              anxietyScores.add(FlSpot(i.toDouble(), anxiety));
              stressScores.add(FlSpot(i.toDouble(), stress));

              final date = (data['created_at'] as Timestamp?)?.toDate();
              labels.add(date != null ? DateFormat('dd/MM').format(date) : '');
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Perkembangan Hasil Tes DASS-21",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 16, 10),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            lineBarsData: [
                              LineChartBarData(
                                spots: depressionScores,
                                isCurved: true,
                                color: Colors.redAccent,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: anxietyScores,
                                isCurved: true,
                                color: Colors.blueAccent,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: stressScores,
                                isCurved: true,
                                color: Colors.orangeAccent,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= labels.length) {
                                      return const Text('');
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        labels[index],
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withOpacity(0.35),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Legend(color: Colors.redAccent, text: "Depresi"),
                      _Legend(color: Colors.blueAccent, text: "Kecemasan"),
                      _Legend(color: Colors.orangeAccent, text: "Stres"),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 4),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
