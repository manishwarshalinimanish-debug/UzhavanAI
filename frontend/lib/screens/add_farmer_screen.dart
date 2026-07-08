import 'package:flutter/material.dart';
import '../models/farmer.dart';
import '../services/api_service.dart';

class AddFarmerScreen extends StatefulWidget {
  final Farmer? farmer;

  const AddFarmerScreen({
    super.key,
    this.farmer,
  });

  @override
  State<AddFarmerScreen> createState() => _AddFarmerScreenState();
}

class _AddFarmerScreenState extends State<AddFarmerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController villageController = TextEditingController();

  final ApiService apiService = ApiService();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.farmer != null) {
      nameController.text = widget.farmer!.name;
      phoneController.text = widget.farmer!.phone;
      villageController.text = widget.farmer!.village;
    }
  }

  Future<void> saveFarmer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.farmer == null) {
        // ADD FARMER
        await apiService.addFarmer(
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          village: villageController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Farmer Added Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // UPDATE FARMER
        await apiService.updateFarmer(
          id: widget.farmer!.id,
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          village: villageController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Farmer Updated Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    villageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.farmer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? "Edit Farmer" : "Add Farmer",
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Farmer Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter farmer name";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter phone number";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: villageController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Village",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter village";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveFarmer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit
                              ? "Update Farmer"
                              : "Save Farmer",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}