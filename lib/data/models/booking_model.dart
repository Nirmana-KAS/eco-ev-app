// lib/data/models/booking_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String stationId;
  final String userId;
  final String vehicleType;
  final String plateNumber;
  final String slotType; // '2x' or '1x'
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  final String status;
  final DateTime createdAt;
  final double? latitude; // <-- Added
  final double? longitude; // <-- Added

  BookingModel({
    required this.stationId,
    required this.userId,
    required this.vehicleType,
    required this.plateNumber,
    required this.slotType,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
    required this.createdAt,
    this.latitude, // <-- Added
    this.longitude, // <-- Added
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      stationId: map['stationId'] ?? '',
      userId: map['userId'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      slotType: map['slotType'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      latitude: (map['latitude'] as num?)?.toDouble(), // <-- Added
      longitude: (map['longitude'] as num?)?.toDouble(), // <-- Added
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'userId': userId,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'slotType': slotType,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'status': status,
      'createdAt': createdAt,
      'latitude': latitude, // <-- Added
      'longitude': longitude, // <-- Added
    };
  }
}
