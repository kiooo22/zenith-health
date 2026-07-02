import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  static const List<String> _modelCandidates = [
    'gemini-2.0-flash',
    'gemini-2.5-flash',
  ];

  GeminiService(this.apiKey);

  String _sanitizeBoldText(String text) {
    var s = text;
    s = s.replaceAllMapped(
        RegExp(r'\*\*(.*?)\*\*', dotAll: true), (m) => m.group(1) ?? '');
    s = s.replaceAllMapped(
        RegExp(r'__(.*?)__', dotAll: true), (m) => m.group(1) ?? '');
    s = s.replaceAll(RegExp(r'<\s*/?\s*b\s*>', caseSensitive: false), '');
    return s.trim();
  }

  GenerativeModel _createModel(String modelName) {
    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      ],
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
      ),
    );
  }

  Future<String> _generate(String prompt) async {
    Object? lastError;

    for (final modelName in _modelCandidates) {
      try {
        final model = _createModel(modelName);
        final response = await model.generateContent([Content.text(prompt)]);

        if (response.promptFeedback?.blockReason != null) {
          return "Maaf, saya tidak bisa menjawab itu karena kebijakan keamanan terkait topik sensitif.";
        }

        if (response.text != null && response.text!.trim().isNotEmpty) {
          return _sanitizeBoldText(response.text!);
        }
      } catch (e) {
        lastError = e;
        print("Gagal menggunakan $modelName: $e");
      }
    }

    return "Terjadi error sistem. Mohon coba lagi nanti. (Detail: $lastError)";
  }

  // Chatbot response
//   Future<String> getChatResponse(
//     String userMessage, {
//     List<Map<String, String>> history = const [],
//   }) async {
//     String historyText = '';

//     if (history.isNotEmpty) {
//       final previousMessages = history
//           .take(history.length > 10 ? 10 : history.length)
//           .map((message) {
//         final role = message['role'] == 'user' ? 'User' : 'Assistant';
//         final content = (message['content'] ?? '').trim();
//         return '$role: $content';
//       }).join('\n');

//       historyText = '\nKonteks percakapan sebelumnya:\n$previousMessages\n';
//     }

//     final prompt = """
// Kamu adalah mental health chatbot yang supportif, tidak menghakimi, dan profesional bernama Zeni.

// Berikan respons yang:
// 1. Empati
// 2. Informatif
// 3. Singkat (2-3 paragraf)
// 4. Dalam Bahasa Indonesia, Ramah Dan Santai
// $historyText

// User: $userMessage
// """;

//     return await _generate(prompt);
//   }

  // Prompt journaling
  Future<String> getJournalingPrompt(String userMood) async {
    final prompt = """
Kamu adalah assistant kesehatan mental yang supportif dan empati bernama Zeni.
User saat ini sedang merasa: $userMood.

Berikan saran singkat (2-3 kalimat) untuk memulai journaling.
Gunakan bahasa Indonesia yang hangat dan ramah serta santai dan relatable.
""";

    return await _generate(prompt);
  }

  // Analisis jurnal
  Future<String> analyzeJournal(String journalContent) async {
    final prompt = """
Analisis jurnal berikut:

"$journalContent"

Berikan:
1. Sentimen/emosi yang terdeteksi
2. Pola atau concern utama
3. Saran positif

Gunakan Bahasa Indonesia yang ramah serta santai dan supportif.
""";

    return await _generate(prompt);
  }

  // Rekomendasi aktivitas
  Future<String> getActivityRecommendation(
    int depressionScore,
    int anxietyScore,
    int stressScore,
  ) async {
    return await getDass21SupportRecommendation(
      depressionScore: depressionScore,
      anxietyScore: anxietyScore,
      stressScore: stressScore,
    );
  }

  Future<String> getDass21SupportRecommendation({
    required int depressionScore,
    required int anxietyScore,
    required int stressScore,
    String? depressionCategory,
    String? anxietyCategory,
    String? stressCategory,
  }) async {
    final prompt = """
Kamu adalah asisten kesehatan mental yang suportif, hangat, ramah dan tidak menghakimi bernama Zeni.

Data hasil DASS-21 user:
- Depresi: $depressionScore${depressionCategory != null ? ' ($depressionCategory)' : ''}
- Kecemasan: $anxietyScore${anxietyCategory != null ? ' ($anxietyCategory)' : ''}
- Stres: $stressScore${stressCategory != null ? ' ($stressCategory)' : ''}

Tugas:
1. Berikan 3-5 saran aktivitas positif yang realistis untuk dilakukan hari ini.
2. Sertakan penjelasan sangat singkat tiap aktivitas (maksimal 1 kalimat).
3. Gunakan bahasa Indonesia yang hangat, ramah, santai, sederhana, dan memotivasi.
4. Hindari diagnosis, hindari nada menakutkan, dan jangan menggurui.
5. Tambahkan 1 kalimat penutup yang mendorong user mencari bantuan profesional jika gejala berat/berlanjut.

Format jawaban:
- Judul singkat: "Saran untuk hari ini"
- Daftar bernomor
- Kalimat penutup suportif
""";

    return await _generate(prompt);
  }
}
