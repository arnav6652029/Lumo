class Temple {
  final int id;
  final String name;
  final String religion;
  final double latitude;
  final double longitude;
  final String address;
  final String description;

  Temple({
    required this.id,
    required this.name,
    required this.religion,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.description,
  });

  factory Temple.fromJson(Map<String, dynamic> json) {
    return Temple(
      id: json["id"],
      name: json["name"],
      religion: json["religion"],
      latitude: double.parse(json["latitude"].toString()),
      longitude: double.parse(json["longitude"].toString()),
      address: json["address"] ?? "",
      description: json["description"] ?? "",
    );
  }
}