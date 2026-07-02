import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../services/gemini_service.dart';

class JournalingPage extends StatefulWidget {
  const JournalingPage({super.key});

  @override
  State<JournalingPage> createState() => _JournalingPageState();
}

class _JournalingPageState extends State<JournalingPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();
  final _contentFieldKey = GlobalKey();
  final _journalService = JournalService();
  GeminiService? _geminiService;
  bool _isLoadingAI = false;
  String? _aiSuggestion;
  String? _aiStatusMessage;
  Duration? _aiResponseTime;

  @override
  void initState() {
    super.initState();
    _contentFocusNode.addListener(() {
      if (_contentFocusNode.hasFocus) {
        _scrollContentIntoView();
      }
    });

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      _geminiService = GeminiService(apiKey);
    } else {
      _aiStatusMessage =
          'Fitur inspirasi AI belum aktif. Tambahkan `GEMINI_API_KEY` pada file `.env`.';
    }
  }

  void _scrollContentIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final contentContext = _contentFieldKey.currentContext;
      if (contentContext == null) return;

      Scrollable.ensureVisible(
        contentContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    });
  }

  Future<void> _getAISuggestion() async {
    if (_geminiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _aiStatusMessage ?? 'Fitur AI belum tersedia saat ini.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAI = true;
      _aiResponseTime = null;
    });

    try {
      final startTime = DateTime.now();
      final suggestion =
          await _geminiService!.getJournalingPrompt('sedang menulis jurnal');
      final elapsed = DateTime.now().difference(startTime);

      if (!mounted) return;

      setState(() {
        _aiSuggestion = suggestion;
        _isLoadingAI = false;
        _aiResponseTime = elapsed;
      });
      _scrollContentIntoView();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingAI = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _saveJournal() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan isi tidak boleh kosong")),
      );
      return;
    }

    final entry = JournalEntry(
      id: "",
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      date: DateTime.now(),
    );

    await _journalService.addJournal(entry);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Jurnal berhasil disimpan!")),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tulis Jurnal"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.primary.withOpacity(0.08),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  18 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Catatan hari ini",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Curahkan apa yang Anda rasakan. Tulis sejujur mungkin untuk refleksi terbaik.",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: color.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 14,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (_aiSuggestion != null &&
                                _aiSuggestion!.isNotEmpty)
                              Card(
                                color: color.primary.withOpacity(0.08),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: color.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _aiSuggestion!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: color.onSurface,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_aiSuggestion != null &&
                                _aiSuggestion!.isNotEmpty)
                              const SizedBox(height: 12),
                            if (_aiResponseTime != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Waktu respon: ${(_aiResponseTime!.inMilliseconds / 1000).toStringAsFixed(2)} detik',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            TextField(
                              controller: _titleController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: "Judul",
                                hintText: "Contoh: Hari produktif namun lelah",
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: _contentFieldKey,
                              focusNode: _contentFocusNode,
                              controller: _contentController,
                              decoration: const InputDecoration(
                                alignLabelWithHint: true,
                                labelText: "Isi Jurnal",
                                hintText:
                                    "Tuliskan hal-hal yang terjadi, perasaan, atau hal yang disyukuri...",
                              ),
                              minLines: 8,
                              maxLines: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingAI ? null : _getAISuggestion,
                              icon: _isLoadingAI
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          color.onPrimary,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(
                                _isLoadingAI
                                    ? "Sedang mencari inspirasi..."
                                    : "💡 Butuh inspirasi?",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveJournal,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Simpan Perubahan"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
