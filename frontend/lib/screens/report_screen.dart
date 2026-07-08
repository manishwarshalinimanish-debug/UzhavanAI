import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/pdf_report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ApiService apiService = ApiService();

  late Future<Map<String, dynamic>> reportData;
  bool isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    reportData = apiService.getReportData();
  }

  Future<void> _refreshReport() async {
    setState(() {
      _loadReport();
    });

    await reportData;
  }

  Future<void> _exportPdf(LanguageProvider language) async {
    setState(() {
      isExporting = true;
    });

    try {
      final data = await apiService.getReportData();

      await PdfReportService.generateAndShareReport(reportData: data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "PDF report generated successfully",
              ta: "PDF அறிக்கை வெற்றிகரமாக உருவாக்கப்பட்டது",
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "PDF export failed: $e",
              ta: "PDF உருவாக்க முடியவில்லை: $e",
            ),
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isExporting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(language.text(en: "Project Report", ta: "திட்ட அறிக்கை")),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: language.text(en: "Export PDF", ta: "PDF ஏற்றுமதி"),
            onPressed: isExporting ? null : () => _exportPdf(language),
            icon: isExporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: language.text(
              en: "Refresh Report",
              ta: "அறிக்கையை புதுப்பிக்க",
            ),
            onPressed: _refreshReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: reportData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorView(
              language: language,
              error: snapshot.error.toString(),
            );
          }

          final data = snapshot.data ?? {};

          final analytics = Map<String, dynamic>.from(data["analytics"] ?? {});

          final farmers = List<dynamic>.from(data["farmers"] ?? []);

          final predictions = List<dynamic>.from(data["predictions"] ?? []);

          final recoveryTrackers = List<dynamic>.from(
            data["recovery_trackers"] ?? [],
          );

          return RefreshIndicator(
            onRefresh: _refreshReport,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildProjectHeader(
                  project: data["project"]?.toString() ?? "UzhavanAI",
                  description:
                      data["description"]?.toString() ??
                      "AI Crop Disease Detection and Smart Farming Assistant",
                ),

                const SizedBox(height: 20),

                _buildSectionTitle(
                  language.text(
                    en: "Analytics Summary",
                    ta: "புள்ளிவிவர சுருக்கம்",
                  ),
                ),

                const SizedBox(height: 10),

                _buildAnalyticsGrid(language: language, analytics: analytics),

                const SizedBox(height: 24),

                _buildSectionTitle(
                  language.text(en: "Farmers", ta: "விவசாயிகள்"),
                ),

                const SizedBox(height: 10),

                _buildFarmersSection(language: language, farmers: farmers),

                const SizedBox(height: 24),

                _buildSectionTitle(
                  language.text(en: "Prediction History", ta: "கணிப்பு வரலாறு"),
                ),

                const SizedBox(height: 10),

                _buildPredictionsSection(
                  language: language,
                  predictions: predictions,
                ),

                const SizedBox(height: 24),

                _buildSectionTitle(
                  language.text(
                    en: "Recovery Trackers",
                    ta: "மீட்பு கண்காணிப்புகள்",
                  ),
                ),

                const SizedBox(height: 10),

                _buildRecoverySection(
                  language: language,
                  recoveryTrackers: recoveryTrackers,
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView({
    required LanguageProvider language,
    required String error,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              language.text(
                en: "Failed to load report",
                ta: "அறிக்கையை ஏற்ற முடியவில்லை",
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loadReport();
                });
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                language.text(en: "Try Again", ta: "மீண்டும் முயற்சி செய்"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader({
    required String project,
    required String description,
  }) {
    return Card(
      elevation: 5,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.green,
              child: Icon(Icons.agriculture, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              project,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAnalyticsGrid({
    required LanguageProvider language,
    required Map<String, dynamic> analytics,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        ReportAnalyticsCard(
          icon: Icons.people,
          title: language.text(en: "Farmers", ta: "விவசாயிகள்"),
          value: "${analytics["total_farmers"] ?? 0}",
        ),
        ReportAnalyticsCard(
          icon: Icons.analytics,
          title: language.text(en: "Predictions", ta: "கணிப்புகள்"),
          value: "${analytics["total_predictions"] ?? 0}",
        ),
        ReportAnalyticsCard(
          icon: Icons.health_and_safety,
          title: language.text(en: "Healthy", ta: "ஆரோக்கியம்"),
          value: "${analytics["healthy_predictions"] ?? 0}",
        ),
        ReportAnalyticsCard(
          icon: Icons.bug_report,
          title: language.text(en: "Diseased", ta: "நோய்"),
          value: "${analytics["diseased_predictions"] ?? 0}",
        ),
        ReportAnalyticsCard(
          icon: Icons.track_changes,
          title: language.text(en: "Recovery", ta: "மீட்பு"),
          value: "${analytics["recovery_trackers"] ?? 0}",
        ),
      ],
    );
  }

  Widget _buildFarmersSection({
    required LanguageProvider language,
    required List<dynamic> farmers,
  }) {
    if (farmers.isEmpty) {
      return _buildEmptyCard(
        language.text(en: "No farmers found", ta: "விவசாயிகள் இல்லை"),
      );
    }

    return Column(
      children: farmers.map((item) {
        final farmer = Map<String, dynamic>.from(item);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(farmer["name"]?.toString() ?? "--"),
            subtitle: Text(
              "${farmer["phone"] ?? "--"}\n"
              "${farmer["village"] ?? "--"}",
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPredictionsSection({
    required LanguageProvider language,
    required List<dynamic> predictions,
  }) {
    if (predictions.isEmpty) {
      return _buildEmptyCard(
        language.text(en: "No predictions found", ta: "கணிப்புகள் இல்லை"),
      );
    }

    return Column(
      children: predictions.map((item) {
        final prediction = Map<String, dynamic>.from(item);
        final disease = prediction["disease"]?.toString() ?? "Unknown";
        final isHealthy = disease.toLowerCase() == "healthy";

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isHealthy ? Colors.green : Colors.red,
              child: Icon(
                isHealthy ? Icons.check : Icons.warning_amber,
                color: Colors.white,
              ),
            ),
            title: Text(
              "${prediction["crop"] ?? "--"} - $disease",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${language.text(en: "Confidence", ta: "நம்பகத்தன்மை")}: "
              "${prediction["confidence"] ?? 0}%",
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildDetailText(
                language.text(en: "Treatment", ta: "சிகிச்சை"),
                prediction["treatment"],
              ),
              _buildDetailText(
                language.text(en: "Prevention", ta: "தடுப்பு முறை"),
                prediction["prevention"],
              ),
              _buildDetailText(
                language.text(en: "Fertilizer", ta: "உரம்"),
                prediction["fertilizer"],
              ),
              _buildDetailText(
                language.text(en: "Date", ta: "தேதி"),
                prediction["created_at"],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecoverySection({
    required LanguageProvider language,
    required List<dynamic> recoveryTrackers,
  }) {
    if (recoveryTrackers.isEmpty) {
      return _buildEmptyCard(
        language.text(
          en: "No recovery trackers found",
          ta: "மீட்பு கண்காணிப்புகள் இல்லை",
        ),
      );
    }

    return Column(
      children: recoveryTrackers.map((item) {
        final tracker = Map<String, dynamic>.from(item);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.track_changes, color: Colors.white),
            ),
            title: Text(
              "${tracker["crop"] ?? "--"} - ${tracker["disease"] ?? "--"}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${language.text(en: "Status", ta: "நிலை")}: "
              "${tracker["status"] ?? "--"}\n"
              "${language.text(en: "Started", ta: "தொடங்கியது")}: "
              "${tracker["started_at"] ?? "--"}",
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailText(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("$title:\n${value ?? "--"}"),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(message)),
      ),
    );
  }
}

class ReportAnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ReportAnalyticsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
