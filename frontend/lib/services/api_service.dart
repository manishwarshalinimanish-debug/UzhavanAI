import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/farmer.dart';

class ApiService {
  static const String baseUrl = "https://uzhavanai-backend.onrender.com";

  Future<List<Farmer>> getFarmers() async {
    final response = await http.get(Uri.parse('$baseUrl/farmers'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Farmer.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load farmers: ${response.body}");
    }
  }

  Future<void> addFarmer({
    required String name,
    required String phone,
    required String village,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/farmers'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "phone": phone, "village": village}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to add farmer: ${response.body}");
    }
  }

  Future<void> updateFarmer({
    required int id,
    required String name,
    required String phone,
    required String village,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/farmers/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "phone": phone, "village": village}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update farmer: ${response.body}");
    }
  }

  Future<void> deleteFarmer(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/farmers/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete farmer: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> predictCrop(File imageFile) async {
    final uri = Uri.parse("$baseUrl/predict-crop");

    final request = http.MultipartRequest("POST", uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        imageFile.path,
        contentType: MediaType("image", "jpeg"),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );

    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(body));
    } else {
      throw Exception(
        "Prediction failed. Status: ${streamedResponse.statusCode}, Body: $body",
      );
    }
  }

  Future<List<dynamic>> getPredictions() async {
    final response = await http.get(Uri.parse('$baseUrl/predictions'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load prediction history: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getWeatherByLocation({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/weather-by-location').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load location weather: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getWeather(String city) async {
    final response = await http.get(Uri.parse('$baseUrl/weather/$city'));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load weather: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> startRecoveryTracker(int predictionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recovery-trackers/$predictionId'),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to start recovery tracker: ${response.body}");
    }
  }

  Future<List<dynamic>> getRecoveryTrackers() async {
    final response = await http.get(Uri.parse('$baseUrl/recovery-trackers'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load recovery trackers: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getRecoveryTrackerDetails(int trackerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recovery-trackers/$trackerId'),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception(
        "Failed to load recovery tracker details: ${response.body}",
      );
    }
  }

  Future<Map<String, dynamic>> addRecoveryUpdate({
    required int trackerId,
    required File imageFile,
    String? notes,
  }) async {
    final uri = Uri.parse('$baseUrl/recovery-trackers/$trackerId/update')
        .replace(
          queryParameters: {
            if (notes != null && notes.trim().isNotEmpty) "notes": notes.trim(),
          },
        );

    final request = http.MultipartRequest("POST", uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        imageFile.path,
        contentType: MediaType("image", "jpeg"),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );

    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(body));
    } else {
      throw Exception(
        "Failed to add recovery update. Status: ${streamedResponse.statusCode}, Body: $body",
      );
    }
  }

  Future<void> deleteRecoveryTracker(int trackerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/recovery-trackers/$trackerId'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete recovery tracker: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics'));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load analytics: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getReportData() async {
    final response = await http.get(Uri.parse('$baseUrl/report-data'));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load report data: ${response.body}");
    }
  }
}
