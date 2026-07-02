import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class JournalDetailPage extends StatefulWidget {
  final JournalEntry journal;

  const JournalDetailPage({super.key, required this.journal});

  @override
  State<JournalDetailPage> createState() => _JournalDetailPageState();
}

class _JournalDetailPageState extends State<JournalDetailPage> {
  GeminiService? _geminiService;
  String? _serviceStatusMessage;
  String? _aiSuggestion;
  String? _aiError;
  bool _isLoadingAI = false;
  Duration? _aiResponseTime;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget async initialization to ensure dotenv is loaded
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      var apiKey = dotenv.env['GEMINI_API_KEY']?.trim();

      // Jika belum ter-load, coba load dotenv (safe to call multiple times)
      if (apiKey == null || apiKey.isEmpty) {
        try {
          await dotenv.load();
        } catch (_) {
          // ignore load errors here; we will set a friendly message below
        }
        apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
      }

      if (apiKey == null || apiKey.isEmpty) {
        if (!mounted) return;
        setState(() {
          _serviceStatusMessage =
              'Fitur AI belum aktif. Periksa file `.env` atau aktifkan GEMINI_API_KEY di konfigurasi.';
        });
        return;
      }

      // Inisialisasi service tanpa menampilkan kunci di log
      _geminiService = GeminiService(apiKey);
      if (!mounted) return;
      setState(() {
        _serviceStatusMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serviceStatusMessage = 'Error inisialisasi AI.';
        _aiError = null;
      });
    }
  }

  Future<void> _requestAISuggestion() async {
    if (_isLoadingAI) return;
    // Pastikan AI diinisialisasi (retry) bila belum
    if (_geminiService == null) {
      await _initializeAI();
      if (_geminiService == null) {
        setState(() {
          _aiError =
              _serviceStatusMessage ?? 'Fitur AI belum tersedia saat ini.';
        });
        return;
      }
    }

    setState(() {
      _isLoadingAI = true;
      _aiError = null;
      _aiResponseTime = null;
    });

    final payload =
        'Judul: ${widget.journal.title}\n\nIsi Jurnal:\n${widget.journal.content}';

    try {
      final startTime = DateTime.now();
      final result = await _geminiService!.analyzeJournal(payload);
      final elapsed = DateTime.now().difference(startTime);
      if (!mounted) return;

      if (result.isEmpty ||
          result.contains('error') ||
          result.contains('Error')) {
        setState(() {
          _aiError = result.isEmpty ? 'Saran AI kosong. Coba lagi.' : result;
        });
      } else {
        setState(() {
          _aiSuggestion = result;
          _aiResponseTime = elapsed;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = 'Gagal memproses saran AI: ${e.toString()}';
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
        title: const Text('Detail Jurnal'),
      ),
      body: Container(
        decoration: AppTheme.softBackground(color),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.journal.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(widget.journal.date),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    widget.journal.content,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingAI ? null : _requestAISuggestion,
                  icon: _isLoadingAI
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isLoadingAI ? 'Memproses...' : 'Minta saran AI?',
                  ),
                ),
              ),
              if (_serviceStatusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _serviceStatusMessage!,
                    style: TextStyle(color: color.error),
                  ),
                ),
              if (_aiError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _aiError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_aiSuggestion != null && _aiSuggestion!.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: color.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Saran AI untuk Jurnalmu',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _aiSuggestion!,
                        style: TextStyle(color: color.onSurface, height: 1.45),
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
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
