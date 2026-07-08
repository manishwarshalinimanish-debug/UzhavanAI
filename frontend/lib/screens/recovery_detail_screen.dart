import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';

class RecoveryDetailScreen extends StatefulWidget {
  final int trackerId;

  const RecoveryDetailScreen({super.key, required this.trackerId});

  @override
  State<RecoveryDetailScreen> createState() => _RecoveryDetailScreenState();
}

class _RecoveryDetailScreenState extends State<RecoveryDetailScreen> {
  final ApiService apiService = ApiService();
  final ImagePicker picker = ImagePicker();
  final TextEditingController notesController = TextEditingController();

  late Future<Map<String, dynamic>> trackerDetails;

  File? image;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    trackerDetails = apiService.getRecoveryTrackerDetails(widget.trackerId);
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  void refreshDetails() {
    setState(() {
      trackerDetails = apiService.getRecoveryTrackerDetails(widget.trackerId);
    });
  }

  Future<void> pickFromCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  Future<void> pickFromGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  Future<void> uploadUpdate(LanguageProvider language) async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "Please select a follow-up leaf image",
              ta: "மீட்பு கண்காணிப்பிற்காக ஒரு இலை படத்தை தேர்வு செய்யவும்",
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final result = await apiService.addRecoveryUpdate(
        trackerId: widget.trackerId,
        imageFile: image!,
        notes: notesController.text,
      );

      if (!mounted) return;

      setState(() {
        image = null;
        notesController.clear();
        isUploading = false;
      });

      refreshDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "Recovery update added. Status: ${result["status"]}",
              ta: "மீட்பு பதிவு சேர்க்கப்பட்டது. நிலை: ${translateStatus(result["status"].toString(), language)}",
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "Upload failed: $e",
              ta: "பதிவேற்றம் தோல்வியடைந்தது: $e",
            ),
          ),
        ),
      );
    }
  }

  String translateStatus(String status, LanguageProvider language) {
    if (!language.isTamil) return status;

    switch (status.toLowerCase()) {
      case "monitoring":
        return "கண்காணிப்பு";
      case "improving":
        return "முன்னேற்றம்";
      case "stable":
        return "நிலையானது";
      case "worsening":
        return "மோசமடைதல்";
      case "recovered":
        return "மீண்டது";
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "improving":
      case "recovered":
        return Colors.green;
      case "worsening":
        return Colors.red;
      case "stable":
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          language.text(en: "Recovery Details", ta: "மீட்பு விவரங்கள்"),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: trackerDetails,
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

          final data = snapshot.data ?? {};
          final updates = List<dynamic>.from(data["updates"] ?? []);
          final status = data["status"].toString();
          final statusColor = getStatusColor(status);

          return RefreshIndicator(
            onRefresh: () async {
              refreshDetails();
              await trackerDetails;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${language.text(en: "Crop", ta: "பயிர்")}: ${data["crop"]}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${language.text(en: "Disease", ta: "நோய்")}: ${data["disease"]}",
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${language.text(en: "Started", ta: "தொடங்கியது")}: ${data["started_at"]}",
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              "${language.text(en: "Status", ta: "நிலை")}: ${translateStatus(status, language)}",
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    language.text(
                      en: "Add Follow-up Leaf Image",
                      ta: "பின்தொடர்பு இலை படத்தை சேர்க்கவும்",
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: image == null
                        ? Center(
                            child: Text(
                              language.text(
                                en: "No follow-up image selected",
                                ta: "பின்தொடர்பு படம் தேர்வு செய்யப்படவில்லை",
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(image!, fit: BoxFit.cover),
                          ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: language.text(
                        en: "Notes (optional)",
                        ta: "குறிப்புகள் (விருப்பம்)",
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : pickFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(language.text(en: "Camera", ta: "கேமரா")),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : pickFromGallery,
                          icon: const Icon(Icons.photo),
                          label: Text(
                            language.text(en: "Gallery", ta: "கேலரி"),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () => uploadUpdate(language),
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(
                        isUploading
                            ? language.text(
                                en: "Uploading...",
                                ta: "பதிவேற்றப்படுகிறது...",
                              )
                            : language.text(
                                en: "Upload Follow-up",
                                ta: "பின்தொடர்பை பதிவேற்று",
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    language.text(
                      en: "Recovery Updates",
                      ta: "மீட்பு பதிவுகள்",
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (updates.isEmpty)
                    Text(
                      language.text(
                        en: "No follow-up updates yet",
                        ta: "இன்னும் பின்தொடர்பு பதிவுகள் இல்லை",
                      ),
                    ),

                  ...updates.map(
                    (update) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.eco, color: Colors.white),
                        ),
                        title: Text(
                          "${language.text(en: "Confidence", ta: "நம்பகத்தன்மை")}: ${update["confidence"]}%",
                        ),
                        subtitle: Text(
                          "${language.text(en: "Notes", ta: "குறிப்புகள்")}: ${update["notes"] ?? "-"}\n"
                          "${language.text(en: "Date", ta: "தேதி")}: ${update["created_at"]}",
                        ),
                        isThreeLine: true,
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
  }
}
