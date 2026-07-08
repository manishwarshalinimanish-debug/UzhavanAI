import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';

class CropAIScreen extends StatefulWidget {
  const CropAIScreen({super.key});

  @override
  State<CropAIScreen> createState() => _CropAIScreenState();
}

class _CropAIScreenState extends State<CropAIScreen> {
  File? image;

  final ImagePicker picker = ImagePicker();
  final ApiService apiService = ApiService();

  bool isLoading = false;

  String crop = "";
  String disease = "";
  String confidence = "";
  String treatment = "";
  String prevention = "";
  String fertilizer = "";

  void clearResult() {
    crop = "";
    disease = "";
    confidence = "";
    treatment = "";
    prevention = "";
    fertilizer = "";
  }

  Future<void> pickFromCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
        clearResult();
      });
    }
  }

  Future<void> pickFromGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
        clearResult();
      });
    }
  }

  Future<void> predictCrop() async {
    final language = Provider.of<LanguageProvider>(context, listen: false);

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "Please select an image first",
              ta: "முதலில் ஒரு படத்தை தேர்வு செய்யவும்",
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await apiService.predictCrop(image!);

      setState(() {
        crop = result["crop"].toString();
        disease = result["disease"].toString();
        confidence = "${result["confidence"]}%";
        treatment = result["treatment"].toString();
        prevention = result["prevention"].toString();
        fertilizer = result["fertilizer"].toString();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "Prediction Failed: $error",
              ta: "கணிப்பு தோல்வியடைந்தது: $error",
            ),
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
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

    if (text.contains("no treatment needed")) {
      return "சிகிச்சை தேவையில்லை.";
    }

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

    final bool isHealthy = disease.toLowerCase() == "healthy";

    final displayCrop = translateCrop(crop, language);
    final displayDisease = translateDisease(disease, language);
    final displayTreatment = translateAdvice(treatment, language);
    final displayPrevention = translateAdvice(prevention, language);
    final displayFertilizer = translateAdvice(fertilizer, language);

    return Scaffold(
      appBar: AppBar(
        title: Text(language.text(en: "Crop AI", ta: "பயிர் AI")),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(12),
              ),
              child: image == null
                  ? Center(
                      child: Text(
                        language.text(
                          en: "No Image Selected",
                          ta: "படம் தேர்வு செய்யப்படவில்லை",
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(image!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : pickFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  language.text(en: "Take Photo", ta: "புகைப்படம் எடு"),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : pickFromGallery,
                icon: const Icon(Icons.photo),
                label: Text(
                  language.text(
                    en: "Choose From Gallery",
                    ta: "கேலரியில் இருந்து தேர்வு செய்",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : predictCrop,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  language.text(en: "Predict Disease", ta: "நோயை கணிக்கவும்"),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            if (crop.isNotEmpty)
              Card(
                color: Colors.green.shade50,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          language.text(
                            en: "AI Prediction Result",
                            ta: "AI கணிப்பு முடிவு",
                          ),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        language.text(
                          en: "Crop: $displayCrop",
                          ta: "பயிர்: $displayCrop",
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        language.text(
                          en: "Disease: $displayDisease",
                          ta: "நோய்: $displayDisease",
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          color: isHealthy ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        language.text(
                          en: "Confidence: $confidence",
                          ta: "நம்பகத்தன்மை: $confidence",
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const Divider(height: 30),
                      Text(
                        language.text(
                          en: "Treatment:\n$displayTreatment",
                          ta: "சிகிச்சை:\n$displayTreatment",
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        language.text(
                          en: "Prevention:\n$displayPrevention",
                          ta: "தடுப்பு முறை:\n$displayPrevention",
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        language.text(
                          en: "Fertilizer:\n$displayFertilizer",
                          ta: "உரம்:\n$displayFertilizer",
                        ),
                        style: const TextStyle(fontSize: 16),
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
