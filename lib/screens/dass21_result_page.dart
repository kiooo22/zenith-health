import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class Dass21ResultPage extends StatefulWidget {
  final List<int> answers;

  const Dass21ResultPage({super.key, required this.answers});

  @override
  State<Dass21ResultPage> createState() => _Dass21ResultPageState();
}

class _Dass21ResultPageState extends State<Dass21ResultPage> {
  late Map<String, int> scores;
  bool _isSaving = false;
  String? _saveError;
  String? _savedResultDocId;
  GeminiService? _geminiService;
  bool _isLoadingAI = false;
  String? _aiRecommendation;
  String? _aiStatusMessage;
  Duration? _aiResponseTime;

  @override
  void initState() {
    super.initState();
    scores = _calculateScores();
    _setupAIService();
    _saveToFirestore();
    _loadAIRecommendation();
  }

  void _setupAIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      _aiStatusMessage =
          'Saran AI belum aktif. Tambahkan `GEMINI_API_KEY` pada file `.env`.';
      return;
    }

    _geminiService = GeminiService(apiKey);
  }

  Map<String, int> _calculateScores() {
    // ✅ Indeks sesuai struktur resmi DASS-21 (0-based)
    const depressionItems = [2, 4, 9, 12, 15, 16, 20];
    const anxietyItems = [1, 3, 6, 8, 14, 18, 19];
    const stressItems = [0, 5, 7, 10, 11, 13, 17];

    int depression =
        depressionItems.map((i) => widget.answers[i]).reduce((a, b) => a + b) *
            2;
    int anxiety =
        anxietyItems.map((i) => widget.answers[i]).reduce((a, b) => a + b) * 2;
    int stress =
        stressItems.map((i) => widget.answers[i]).reduce((a, b) => a + b) * 2;

    return {
      "depression": depression,
      "anxiety": anxiety,
      "stress": stress,
    };
  }

  String getCategory(int score, String type) {
    switch (type) {
      case "depression":
        if (score <= 9) return "Normal";
        if (score <= 13) return "Ringan";
        if (score <= 20) return "Sedang";
        if (score <= 27) return "Parah";
        return "Sangat Parah";
      case "anxiety":
        if (score <= 7) return "Normal";
        if (score <= 9) return "Ringan";
        if (score <= 14) return "Sedang";
        if (score <= 19) return "Parah";
        return "Sangat Parah";
      case "stress":
        if (score <= 14) return "Normal";
        if (score <= 18) return "Ringan";
        if (score <= 25) return "Sedang";
        if (score <= 33) return "Parah";
        return "Sangat Parah";
      default:
        return "-";
    }
  }

  Future<void> _saveToFirestore() async {
    if (!mounted) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = "Kamu belum login. Hasil tidak bisa disimpan.";
      });
      return;
    }

    final data = <String, dynamic>{
      "depression": scores["depression"],
      "depression_category": getCategory(scores["depression"]!, "depression"),
      "anxiety": scores["anxiety"],
      "anxiety_category": getCategory(scores["anxiety"]!, "anxiety"),
      "stress": scores["stress"],
      "stress_category": getCategory(scores["stress"]!, "stress"),
      "created_at": FieldValue.serverTimestamp(),
    };

    if (_aiRecommendation != null && _aiRecommendation!.trim().isNotEmpty) {
      data["ai_recommendation"] = _aiRecommendation;
      data["ai_recommendation_updated_at"] = FieldValue.serverTimestamp();
    }

    try {
      final docRef = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("dass21_results")
          .add(data);

      _savedResultDocId = docRef.id;

      if (_aiRecommendation != null && _aiRecommendation!.trim().isNotEmpty) {
        await _saveAIRecommendationToFirestore(_aiRecommendation!);
      }
    } on FirebaseException catch (e) {
      String msg = "Gagal menyimpan hasil tes.";
      if (e.code == 'permission-denied') {
        msg =
            "Gagal menyimpan hasil: Firestore Rules menolak akses (permission-denied).";
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = "Gagal menyimpan hasil: ${e.message}";
      }

      if (!mounted) return;
      setState(() => _saveError = msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = "Gagal menyimpan hasil: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAIRecommendationToFirestore(String recommendation) async {
    final resultDocId = _savedResultDocId;
    final user = FirebaseAuth.instance.currentUser;

    if (resultDocId == null || user == null) return;
    if (recommendation.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("dass21_results")
          .doc(resultDocId)
          .update({
        "ai_recommendation": recommendation,
        "ai_recommendation_updated_at": FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _loadAIRecommendation() async {
    if (_geminiService == null) return;

    setState(() {
      _isLoadingAI = true;
      _aiStatusMessage = null;
      _aiResponseTime = null;
    });

    try {
      final startTime = DateTime.now();
      final recommendation =
          await _geminiService!.getDass21SupportRecommendation(
        depressionScore: scores['depression']!,
        anxietyScore: scores['anxiety']!,
        stressScore: scores['stress']!,
        depressionCategory: getCategory(scores['depression']!, 'depression'),
        anxietyCategory: getCategory(scores['anxiety']!, 'anxiety'),
        stressCategory: getCategory(scores['stress']!, 'stress'),
      );
      final elapsed = DateTime.now().difference(startTime);

      if (!mounted) return;
      setState(() {
        _aiRecommendation = recommendation;
        _aiResponseTime = elapsed;
      });

      await _saveAIRecommendationToFirestore(recommendation);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiStatusMessage =
            'Saran AI belum bisa dimuat sekarang. Kamu bisa coba lagi sebentar lagi.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingAI = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasil Tes DASS-21"),
      ),
      body: Container(
        decoration: AppTheme.softBackground(color),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (_saveError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _saveError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Text(
                  'Hasil Penilaian',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color.onSurface,
                      ),
                ),
                const SizedBox(height: 10),
                _ScoreRow(
                  label: 'Depresi',
                  score: scores['depression'],
                  category: getCategory(scores['depression']!, 'depression'),
                  dotColor: _categoryColor(
                    getCategory(scores['depression']!, 'depression'),
                  ),
                ),
                _ScoreRow(
                  label: 'Kecemasan',
                  score: scores['anxiety'],
                  category: getCategory(scores['anxiety']!, 'anxiety'),
                  dotColor: _categoryColor(
                    getCategory(scores['anxiety']!, 'anxiety'),
                  ),
                ),
                _ScoreRow(
                  label: 'Stres',
                  score: scores['stress'],
                  category: getCategory(scores['stress']!, 'stress'),
                  dotColor: _categoryColor(
                    getCategory(scores['stress']!, 'stress'),
                  ),
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
                      if (_isLoadingAI)
                        const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'AI sedang menyusun rekomendasi untukmu...',
                              ),
                            ),
                          ],
                        )
                      else if (_aiRecommendation != null &&
                          _aiRecommendation!.trim().isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _aiRecommendation!,
                              style: TextStyle(
                                height: 1.5,
                                color: color.onSurface,
                              ),
                            ),
                            if (_aiResponseTime != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Waktu respon: ${(_aiResponseTime!.inMilliseconds / 1000).toStringAsFixed(2)} detik',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _aiStatusMessage ??
                                  'Saran AI belum tersedia saat ini.',
                              style: TextStyle(
                                color: color.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (_geminiService != null) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed:
                                    _isLoadingAI ? null : _loadAIRecommendation,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba lagi'),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_saveError != null)
                  OutlinedButton(
                    onPressed: _isSaving ? null : _saveToFirestore,
                    child: const Text("Coba simpan lagi"),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: const Text("Kembali ke Beranda"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
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
  final int? score;
  final String category;
  final Color dotColor;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.category,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: dotColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
