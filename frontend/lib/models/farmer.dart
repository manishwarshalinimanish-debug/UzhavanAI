class Farmer {
  final int id;
  final String name;
  final String phone;
  final String village;

  Farmer({
    required this.id,
    required this.name,
    required this.phone,
    required this.village,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      village: json['village'],
    );
  }
}