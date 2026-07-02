import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class Dass21DetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const Dass21DetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    final createdAt = data['created_at'] != null
        ? data['created_at'].toDate() as DateTime
        : null;

    final aiRecommendation =
        (data['ai_recommendation'] as String?)?.trim() ?? '';
    final hasAI = aiRecommendation.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          createdAt != null
              ? DateFormat('dd MMM yyyy').format(createdAt)
              : 'Detail Hasil',
        ),
      ),
      body: Container(
        decoration: AppTheme.softBackground(color),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (createdAt != null)
                Text(
                  DateFormat('EEEE, dd MMMM yyyy \u2022 HH:mm', 'id')
                      .format(createdAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: color.onSurfaceVariant),
                ),
              const SizedBox(height: 16),
              Text(
                'Hasil Penilaian',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _ScoreRow(
                label: 'Depresi',
                score: data['depression'],
                category: data['depression_category'],
                dotColor: _categoryColor(data['depression_category']),
              ),
              _ScoreRow(
                label: 'Kecemasan',
                score: data['anxiety'],
                category: data['anxiety_category'],
                dotColor: _categoryColor(data['anxiety_category']),
              ),
              _ScoreRow(
                label: 'Stres',
                score: data['stress'],
                category: data['stress_category'],
                dotColor: _categoryColor(data['stress_category']),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: color.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Saran Positif dari AI',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    hasAI
                        ? Text(
                            aiRecommendation,
                            style: TextStyle(
                              height: 1.5,
                              color: color.onSurface,
                            ),
                          )
                        : Text(
                            'Saran AI tidak tersedia untuk hasil ini.\n'
                            'Coba selesaikan tes baru untuk mendapatkan rekomendasi.',
                            style: TextStyle(
                              color: color.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(dynamic category) {
    switch (category) {
      case 'Normal':
        return Colors.green;
      case 'Ringan':
        return Colors.lightGreen;
      case 'Sedang':
        return Colors.orange;
      case 'Parah':
        return Colors.deepOrange;
      case 'Sangat Parah':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final dynamic score;
  final dynamic category;
  final Color dotColor;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.category,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: dotColor.withOpacity(0.15),
          child: Text(
            '${score ?? '-'}',
            style: TextStyle(
              color: dotColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: dotColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${category ?? '-'}',
            style: TextStyle(
              color: dotColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
