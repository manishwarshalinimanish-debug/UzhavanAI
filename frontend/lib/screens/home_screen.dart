import 'package:flutter/material.dart';
import '../models/farmer.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UzhavanAI Farmers"),
      ),
      body: FutureBuilder<List<Farmer>>(
        future: apiService.getFarmers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final farmers = snapshot.data!;

          return ListView.builder(
            itemCount: farmers.length,
            itemBuilder: (context, index) {
              final farmer = farmers[index];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(farmer.id.toString()),
                ),
                title: Text(farmer.name),
                subtitle: Text("${farmer.phone}\n${farmer.village}"),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}