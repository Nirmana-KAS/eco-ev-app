class StationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final int availablePorts;

  StationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.availablePorts,
  });

  factory StationModel.fromMap(Map<String, dynamic> map, String id) {
    return StationModel(
      id: id,
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] ?? '',
      availablePorts: map['availablePorts'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'availablePorts': availablePorts,
    };
  }
}
