import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dass21_result_page.dart';

class Dass21Page extends StatefulWidget {
  const Dass21Page({super.key});

  @override
  State<Dass21Page> createState() => _Dass21PageState();
}

class _Dass21PageState extends State<Dass21Page> {
  final List<int> _answers = List.filled(21, 0);

  final List<String> _optionLabels = const [
    "Tidak pernah",
    "Kadang",
    "Sering",
    "Sangat sering",
  ];

  final List<String> _questions = [
    "Saya merasa tegang atau gelisah.",
    "Saya kesulitan beristirahat.",
    "Saya merasa sedih dan murung.",
    "Saya merasa lelah.",
    "Saya tidak sabar terhadap hal kecil.",
    "Saya merasa tidak berharga.",
    "Saya merasa takut tanpa alasan jelas.",
    "Saya mudah tersinggung.",
    "Saya sulit berkonsentrasi.",
    "Saya merasa putus asa.",
    "Saya merasa panik.",
    "Saya merasa tidak bersemangat.",
    "Saya merasa tertekan.",
    "Saya sulit tidur.",
    "Saya khawatir berlebihan.",
    "Saya merasa tegang di otot.",
    "Saya merasa tidak mampu mengatasi masalah.",
    "Saya menghindari situasi sosial.",
    "Saya merasa takut hal buruk akan terjadi.",
    "Saya merasa marah tanpa alasan.",
    "Saya merasa kesepian.",
  ];

  Future<void> _submit() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi hasil'),
          content: const Text(
            'Pastikan semua jawaban sudah sesuai. Lanjut lihat hasil tes DASS-21?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );

    if (shouldContinue == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Dass21ResultPage(answers: _answers),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          title: const Text("Tes DASS-21"),
        ),
        body: Container(
          decoration: AppTheme.softBackground(color),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _questions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Jawab sesuai kondisi 1 minggu terakhir",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Gunakan skala 0-3 dari tidak pernah hingga sangat sering.",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              final int questionIndex = index - 1;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Q${questionIndex + 1}",
                              style: TextStyle(
                                color: color.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _questions[questionIndex],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(4, (i) {
                          return ChoiceChip(
                            label:
                                Text('${i.toString()} · ${_optionLabels[i]}'),
                            selected: _answers[questionIndex] == i,
                            onSelected: (_) {
                              setState(() => _answers[questionIndex] = i);
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Lihat hasil"),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
          ),
        ),
      ),
    );
  }
}
