// lib/data/models/station_model.dart

class StationModel {
  final String id;
  final String name;
  final String owner;
  final String address;
  final double latitude;
  final double longitude;
  final String contactNumber;
  final String gmail;
  final int slots2x;
  final int slots1x;
  final String openingHours;
  final double pricePerHour;
  final String logoUrl;
  final String? cardImageUrl; // <-- add this

  StationModel({
    required this.id,
    required this.name,
    required this.owner,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactNumber,
    required this.gmail,
    required this.slots2x,
    required this.slots1x,
    required this.openingHours,
    required this.pricePerHour,
    required this.logoUrl,
    this.cardImageUrl, // <-- add this
  });

  int get totalPorts => slots2x + slots1x;

  factory StationModel.fromMap(Map<String, dynamic> map, String docId) {
    return StationModel(
      id: docId,
      name: map['name'] ?? '',
      owner: map['owner'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      contactNumber: map['contactNumber'] ?? '',
      gmail: map['gmail'] ?? '',
      slots2x: map['slots2x'] ?? 0,
      slots1x: map['slots1x'] ?? 0,
      openingHours: map['openingHours'] ?? '',
      pricePerHour: (map['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      logoUrl: map['logoUrl'] ?? '',
      cardImageUrl: map['cardImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'owner': owner,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contactNumber': contactNumber,
      'gmail': gmail,
      'slots2x': slots2x,
      'slots1x': slots1x,
      'openingHours': openingHours,
      'pricePerHour': pricePerHour,
      'logoUrl': logoUrl,
      'cardImageUrl': cardImageUrl,
    };
  }
}
