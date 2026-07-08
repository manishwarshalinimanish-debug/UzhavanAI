import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';

class PredictionHistoryScreen extends StatefulWidget {
  const PredictionHistoryScreen({super.key});

  @override
  State<PredictionHistoryScreen> createState() =>
      _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState extends State<PredictionHistoryScreen> {
  final ApiService apiService = ApiService();

  late Future<List<dynamic>> predictions;

  @override
  void initState() {
    super.initState();
    predictions = apiService.getPredictions();
  }

  Future<void> refreshHistory() async {
    setState(() {
      predictions = apiService.getPredictions();
    });
  }

  Future<void> startRecoveryTracking(
    BuildContext context,
    int predictionId,
    LanguageProvider language,
  ) async {
    try {
      final result = await apiService.startRecoveryTracker(predictionId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"].toString())));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(en: "Failed: $e", ta: "தோல்வியடைந்தது: $e"),
          ),
        ),
      );
    }
  }

  String translateCrop(String value, LanguageProvider language) {
    if (!language.isTamil) return value;

    final cropName = value.toLowerCase();

    if (cropName.contains("tomato")) return "தக்காளி";
    if (cropName.contains("potato")) return "உருளைக்கிழங்கு";
    if (cropName.contains("corn") || cropName.contains("maize")) {
      return "மக்காச்சோளம்";
    }

    return value;
  }

  String translateDisease(String value, LanguageProvider language) {
    if (!language.isTamil) return value;

    final diseaseName = value.toLowerCase();

    if (diseaseName == "healthy") return "ஆரோக்கியமானது";
    if (diseaseName.contains("early blight")) return "ஆரம்ப கருகல் நோய்";
    if (diseaseName.contains("late blight")) return "தாமத கருகல் நோய்";
    if (diseaseName.contains("common rust")) return "பொதுவான துரு நோய்";

    return value;
  }

  String translateAdvice(String value, LanguageProvider language) {
    if (!language.isTamil) return value;

    final text = value.toLowerCase();

    if (text.contains("no treatment needed")) return "சிகிச்சை தேவையில்லை.";

    if (text.contains("continue regular watering")) {
      return "தொடர்ந்து வழக்கமான நீர்ப்பாசனம் செய்து, வாரத்திற்கு ஒருமுறை இலைகளை பரிசோதிக்கவும்.";
    }

    if (text.contains("balanced npk")) {
      return "மண் நிலைக்கு ஏற்ப சமநிலை NPK உரத்தை பயன்படுத்தவும்.";
    }

    if (text.contains("remove infected leaves")) {
      return "பாதிக்கப்பட்ட இலைகளை அகற்றி, மான்கோசெப் அல்லது காப்பர் அடிப்படையிலான பூஞ்சைநாசினி பயன்படுத்தவும்.";
    }

    if (text.contains("avoid overhead watering")) {
      return "மேலிருந்து நீர் பாய்ச்சுவதை தவிர்த்து, செடிகளுக்கு இடைவெளி வைக்கவும்.";
    }

    if (text.contains("potassium-rich")) {
      return "செடியின் எதிர்ப்பு சக்தியை அதிகரிக்க பொட்டாசியம் அதிகமான உரத்தை பயன்படுத்தவும்.";
    }

    if (text.contains("metalaxyl")) {
      return "உடனடியாக மெட்டாலாக்சில் அல்லது மான்கோசெப் பூஞ்சைநாசினி பயன்படுத்தவும்.";
    }

    if (text.contains("avoid excess moisture")) {
      return "அதிக ஈரப்பதத்தை தவிர்த்து, பாதிக்கப்பட்ட செடிகளை விரைவாக அகற்றவும்.";
    }

    if (text.contains("avoid excess nitrogen")) {
      return "சமநிலை NPK உரம் பயன்படுத்தவும். அதிக நைட்ரஜனை தவிர்க்கவும்.";
    }

    if (text.contains("propiconazole")) {
      return "மான்கோசெப் அல்லது புரோபிகோனசோல் போன்ற பொருத்தமான பூஞ்சைநாசினி பயன்படுத்தவும்.";
    }

    if (text.contains("resistant varieties")) {
      return "நோய் எதிர்ப்பு வகைகளை பயன்படுத்தி, அடர்த்தியான நடவு முறையை தவிர்க்கவும்.";
    }

    if (text.contains("nitrogen overdose")) {
      return "சமநிலை உரம் பயன்படுத்தவும். நைட்ரஜன் அதிகப்படியாக விட வேண்டாம்.";
    }

    if (text.contains("consult a local agriculture expert")) {
      return "சரியான சிகிச்சைக்காக உள்ளூர் வேளாண்மை நிபுணரை அணுகவும்.";
    }

    if (text.contains("monitor crop regularly")) {
      return "பயிரை தொடர்ந்து கண்காணித்து, பாதிக்கப்பட்ட இலைகளை அகற்றவும்.";
    }

    if (text.contains("soil test")) {
      return "மண் பரிசோதனை பரிந்துரையின் அடிப்படையில் உரம் பயன்படுத்தவும்.";
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          language.text(en: "Prediction History", ta: "கணிப்பு வரலாறு"),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: predictions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                language.text(
                  en: "Error: ${snapshot.error}",
                  ta: "பிழை: ${snapshot.error}",
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Text(
                language.text(
                  en: "No prediction history found",
                  ta: "கணிப்பு வரலாறு இல்லை",
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];

                final crop = item["crop"].toString();
                final disease = item["disease"].toString();

                final displayCrop = translateCrop(crop, language);
                final displayDisease = translateDisease(disease, language);

                final treatment = translateAdvice(
                  item["treatment"].toString(),
                  language,
                );
                final prevention = translateAdvice(
                  item["prevention"].toString(),
                  language,
                );
                final fertilizer = translateAdvice(
                  item["fertilizer"].toString(),
                  language,
                );

                final isHealthy = disease.toLowerCase() == "healthy";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.text(
                            en: "Crop: $displayCrop",
                            ta: "பயிர்: $displayCrop",
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.text(
                            en: "Disease: $displayDisease",
                            ta: "நோய்: $displayDisease",
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: isHealthy ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          language.text(
                            en: "Confidence: ${item["confidence"]}%",
                            ta: "நம்பகத்தன்மை: ${item["confidence"]}%",
                          ),
                        ),
                        const Divider(height: 25),
                        Text(
                          language.text(
                            en: "Treatment:\n$treatment",
                            ta: "சிகிச்சை:\n$treatment",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.text(
                            en: "Prevention:\n$prevention",
                            ta: "தடுப்பு முறை:\n$prevention",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.text(
                            en: "Fertilizer:\n$fertilizer",
                            ta: "உரம்:\n$fertilizer",
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${language.text(en: "Date", ta: "தேதி")}: ${item["created_at"]}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              startRecoveryTracking(
                                context,
                                item["id"],
                                language,
                              );
                            },
                            icon: const Icon(Icons.track_changes),
                            label: Text(
                              language.text(
                                en: "Start Recovery Tracking",
                                ta: "மீட்பு கண்காணிப்பை தொடங்கு",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
