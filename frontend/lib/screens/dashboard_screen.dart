import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/farmer.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

import 'add_farmer_screen.dart';
import 'crop_ai_screen.dart';
import 'prediction_history_screen.dart';
import 'recovery_tracker_screen.dart';
import 'report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();

  late Future<List<Farmer>> farmers;
  late Future<Map<String, dynamic>> analytics;
  Future<Map<String, dynamic>>? weather;

  bool isLoadingLocation = false;
  String? locationError;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
    _loadAnalytics();
  }

  void _loadFarmers() {
    farmers = apiService.getFarmers();
  }

  void _loadAnalytics() {
    analytics = apiService.getAnalytics();
  }

  Future<void> _loadWeatherFromCurrentLocation() async {
    if (isLoadingLocation) return;

    setState(() {
      isLoadingLocation = true;
      locationError = null;
    });

    try {
      final weatherFuture = apiService.getWeatherByLocation(
        latitude: 10.9323,
        longitude: 76.9764,
      );

      if (!mounted) return;

      setState(() {
        weather = weatherFuture;
        isLoadingLocation = false;
      });

      await weatherFuture;
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
        locationError = error.toString();
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _loadFarmers();
      _loadAnalytics();
    });

    await Future.wait([farmers, analytics]);
  }

  Future<void> _openAddFarmer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFarmerScreen()),
    );

    if (result == true && mounted) {
      setState(() {
        _loadFarmers();
        _loadAnalytics();
      });
    }
  }

  Future<void> _openEditFarmer(Farmer farmer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddFarmerScreen(farmer: farmer)),
    );

    if (result == true && mounted) {
      setState(() {
        _loadFarmers();
        _loadAnalytics();
      });
    }
  }

  Future<void> _deleteFarmer(Farmer farmer) async {
    final language = Provider.of<LanguageProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(language.text(en: "Delete Farmer", ta: "விவசாயியை நீக்கு")),
        content: Text(
          language.text(
            en: "Are you sure you want to delete ${farmer.name}?",
            ta: "${farmer.name} விவசாயியை நீக்க வேண்டுமா?",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(language.text(en: "Cancel", ta: "ரத்து செய்")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(language.text(en: "Delete", ta: "நீக்கு")),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await apiService.deleteFarmer(farmer.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.text(
              en: "Farmer deleted successfully",
              ta: "விவசாயி வெற்றிகரமாக நீக்கப்பட்டார்",
            ),
          ),
        ),
      );

      setState(() {
        _loadFarmers();
        _loadAnalytics();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $error")));
    }
  }

  void _openCropAI() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CropAIScreen()),
    );
  }

  void _openPredictionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PredictionHistoryScreen()),
    );
  }

  void _openRecoveryTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecoveryTrackerScreen()),
    );
  }

  void _openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );
  }

  Widget _buildWeatherCard(LanguageProvider language) {
    if (isLoadingLocation && weather == null) {
      return _weatherContainer(
        child: Row(
          children: [
            const SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                language.text(
                  en: "Loading weather...",
                  ta: "வானிலை ஏற்றப்படுகிறது...",
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (locationError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.text(
                en: "Unable to load weather",
                ta: "வானிலையை பெற முடியவில்லை",
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(locationError!),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isLoadingLocation
                  ? null
                  : _loadWeatherFromCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: Text(
                language.text(en: "Try Again", ta: "மீண்டும் முயற்சி செய்"),
              ),
            ),
          ],
        ),
      );
    }

    final currentWeather = weather;

    if (currentWeather == null) {
      return _weatherContainer(
        child: ElevatedButton.icon(
          onPressed: _loadWeatherFromCurrentLocation,
          icon: const Icon(Icons.cloud),
          label: Text(language.text(en: "Load Weather", ta: "வானிலை காண்க")),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: currentWeather,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _weatherContainer(
            child: Row(
              children: [
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    language.text(
                      en: "Loading live weather...",
                      ta: "நேரடி வானிலை ஏற்றப்படுகிறது...",
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Weather Error: ${snapshot.error}"),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loadWeatherFromCurrentLocation,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    language.text(en: "Retry Weather", ta: "மீண்டும் முயற்சி"),
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                language.text(en: "Today's Weather", ta: "இன்றைய வானிலை"),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                language.text(
                  en: "Temperature: ${data["temperature"] ?? "--"}",
                  ta: "வெப்பநிலை: ${data["temperature"] ?? "--"}",
                ),
              ),
              Text(
                language.text(
                  en: "Condition: ${data["condition"] ?? "--"}",
                  ta: "நிலை: ${data["condition"] ?? "--"}",
                ),
              ),
              Text(
                language.text(
                  en: "Rain: ${data["rain"] ?? "--"}",
                  ta: "மழை: ${data["rain"] ?? "--"}",
                ),
              ),
              const SizedBox(height: 8),
              Text(
                language.text(
                  en: "Farming Advice: ${data["farming_advice"] ?? "No advice available"}",
                  ta: "விவசாய ஆலோசனை: ${data["farming_advice"] ?? "ஆலோசனை இல்லை"}",
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _weatherContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  Widget _buildAnalyticsSection(LanguageProvider language) {
    return FutureBuilder<Map<String, dynamic>>(
      future: analytics,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Text(
            language.text(
              en: "Analytics Error: ${snapshot.error}",
              ta: "புள்ளிவிவர பிழை: ${snapshot.error}",
            ),
          );
        }

        final data = snapshot.data ?? {};

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            AnalyticsCard(
              icon: Icons.people,
              title: language.text(en: "Farmers", ta: "விவசாயிகள்"),
              value: "${data["total_farmers"] ?? 0}",
            ),
            AnalyticsCard(
              icon: Icons.analytics,
              title: language.text(en: "Predictions", ta: "கணிப்புகள்"),
              value: "${data["total_predictions"] ?? 0}",
            ),
            AnalyticsCard(
              icon: Icons.health_and_safety,
              title: language.text(en: "Healthy", ta: "ஆரோக்கியம்"),
              value: "${data["healthy_predictions"] ?? 0}",
            ),
            AnalyticsCard(
              icon: Icons.bug_report,
              title: language.text(en: "Diseased", ta: "நோய்"),
              value: "${data["diseased_predictions"] ?? 0}",
            ),
            AnalyticsCard(
              icon: Icons.track_changes,
              title: language.text(en: "Recovery", ta: "மீட்பு"),
              value: "${data["recovery_trackers"] ?? 0}",
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("UzhavanAI"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: language.toggleLanguage,
            child: Text(
              language.isTamil ? "English" : "தமிழ்",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _openAddFarmer,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Farmer>>(
        future: farmers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                language.text(
                  en: "Failed to load farmers",
                  ta: "விவசாயிகள் தகவலை ஏற்ற முடியவில்லை",
                ),
              ),
            );
          }

          final farmerList = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  language.text(
                    en: "Welcome, Manish 👋",
                    ta: "வரவேற்கிறோம், மணிஷ் 👋",
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildWeatherCard(language),
                const SizedBox(height: 20),
                Text(
                  language.text(en: "Analytics", ta: "புள்ளிவிவரம்"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildAnalyticsSection(language),
                const SizedBox(height: 20),
                Text(
                  language.text(en: "Quick Actions", ta: "விரைவு செயல்கள்"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.15,
                  children: [
                    ActionCard(
                      icon: Icons.people,
                      title: language.text(en: "Farmers", ta: "விவசாயிகள்"),
                      onTap: _openAddFarmer,
                    ),
                    ActionCard(
                      icon: Icons.grass,
                      title: language.text(en: "Crop AI", ta: "பயிர் AI"),
                      onTap: _openCropAI,
                    ),
                    ActionCard(
                      icon: Icons.history,
                      title: language.text(en: "History", ta: "வரலாறு"),
                      onTap: _openPredictionHistory,
                    ),
                    ActionCard(
                      icon: Icons.track_changes,
                      title: language.text(en: "Recovery", ta: "மீட்பு"),
                      onTap: _openRecoveryTracker,
                    ),
                    ActionCard(
                      icon: Icons.description,
                      title: language.text(en: "Reports", ta: "அறிக்கை"),
                      onTap: _openReport,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  language.text(
                    en: "Recent Farmers (${farmerList.length})",
                    ta: "சமீபத்திய விவசாயிகள் (${farmerList.length})",
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (farmerList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        language.text(
                          en: "No farmers found",
                          ta: "விவசாயிகள் இல்லை",
                        ),
                      ),
                    ),
                  ),
                ...farmerList.map(
                  (farmer) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(farmer.name),
                      subtitle: Text("${farmer.phone}\n${farmer.village}"),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _openEditFarmer(farmer),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteFarmer(farmer),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const AnalyticsCard({
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
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.green, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
