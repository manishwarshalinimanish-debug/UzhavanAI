import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';

import 'recovery_detail_screen.dart';

class RecoveryTrackerScreen extends StatefulWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  State<RecoveryTrackerScreen> createState() => _RecoveryTrackerScreenState();
}

class _RecoveryTrackerScreenState extends State<RecoveryTrackerScreen> {
  final ApiService apiService = ApiService();

  late Future<List<dynamic>> trackers;

  @override
  void initState() {
    super.initState();
    trackers = apiService.getRecoveryTrackers();
  }

  Future<void> refreshTrackers() async {
    setState(() {
      trackers = apiService.getRecoveryTrackers();
    });
  }

  Future<void> openDetails(int trackerId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecoveryDetailScreen(trackerId: trackerId),
      ),
    );

    refreshTrackers();
  }

  Future<void> deleteTracker(int trackerId, LanguageProvider language) async {
    try {
      await apiService.deleteRecoveryTracker(trackerId);
      await refreshTrackers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "Recovery tracker deleted",
              ta: "மீட்பு கண்காணிப்பு நீக்கப்பட்டது",
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(en: "Delete failed: $e", ta: "நீக்க முடியவில்லை: $e"),
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
          language.text(en: "Recovery Trackers", ta: "மீட்பு கண்காணிப்பு"),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: trackers,
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
                  en: "No recovery trackers found",
                  ta: "மீட்பு கண்காணிப்பு இல்லை",
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshTrackers,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];

                final status = item["status"].toString();
                final statusColor = getStatusColor(status);

                final crop = translateCrop(item["crop"].toString(), language);

                final disease = translateDisease(
                  item["disease"].toString(),
                  language,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      openDetails(item["id"]);
                    },
                    leading: CircleAvatar(
                      backgroundColor: statusColor,
                      child: const Icon(
                        Icons.track_changes,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      "$crop - $disease",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${language.text(en: "Status", ta: "நிலை")}: "
                      "${translateStatus(status, language)}\n"
                      "${language.text(en: "Started", ta: "தொடங்கியது")}: "
                      "${item["started_at"]}",
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteTracker(item["id"], language);
                      },
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
