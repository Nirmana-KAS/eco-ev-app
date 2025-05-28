// lib/dat/services/screens/station_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/station_model.dart'; // Make sure this path is correct and StationModel is defined there

class StationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _stationsCollection = _firestore.collection('stations');

  /// Get all stations from Firestore
  static Future<List<StationModel>> getAllStations() async {
    try {
      final QuerySnapshot querySnapshot = await _stationsCollection.get();
      return querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch stations: $e');
    }
  }

  /// Get a specific station by ID
  static Future<StationModel?> getStationById(String stationId) async {
    try {
      final DocumentSnapshot doc = await _stationsCollection.doc(stationId).get();
      if (doc.exists) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch station: $e');
    }
  }

  /// Add a new station to Firestore
  static Future<String> addStation({
    required String name,
    required String owner,
    required String address,
    required double latitude,
    required double longitude,
    required String contactNumber,
    required String gmail,
    required int slots2x,
    required int slots1x,
    required String openingHours,
    required double pricePerHour,
    required String logoUrl,
    String? cardImageUrl,
  }) async {
    try {
      final DocumentReference docRef = await _stationsCollection.add({
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add station: $e');
    }
  }

  /// Update an existing station
  static Future<void> updateStation(String stationId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _stationsCollection.doc(stationId).update(updates);
    } catch (e) {
      throw Exception('Failed to update station: $e');
    }
  }

  /// Delete a station
  static Future<void> deleteStation(String stationId) async {
    try {
      await _stationsCollection.doc(stationId).delete();
    } catch (e) {
      throw Exception('Failed to delete station: $e');
    }
  }

  /// Get stations within a specific radius using GeoPoint
  static Future<List<StationModel>> getStationsNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Simple implementation - in production, use GeoFlutterFire or similar
      final QuerySnapshot querySnapshot = await _stationsCollection.get();
      final stations = querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filter by distance (simple calculation)
      return stations.where((station) {
        final distance = _calculateDistance(
          latitude, longitude,
          station.latitude, station.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby stations: $e');
    }
  }

  /// Search stations by name, owner, or address
  static Future<List<StationModel>> searchStations(String searchTerm) async {
    try {
      final String searchLower = searchTerm.toLowerCase();
      final QuerySnapshot querySnapshot = await _stationsCollection.get();
      
      final stations = querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      return stations.where((station) {
        return station.name.toLowerCase().contains(searchLower) ||
               station.owner.toLowerCase().contains(searchLower) ||
               station.address.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search stations: $e');
    }
  }

  /// Get filtered stations based on criteria
  static Future<List<StationModel>> getFilteredStations({
    double? maxPricePerHour,
    double? minPricePerHour,
    int? minSlots2x,
    int? minSlots1x,
    int? minTotalSlots,
    bool? is24Hours,
    String? ownerFilter,
  }) async {
    try {
      Query query = _stationsCollection;

      // Apply Firestore queries where possible
      if (maxPricePerHour != null) {
        query = query.where('pricePerHour', isLessThanOrEqualTo: maxPricePerHour);
      }
      if (minPricePerHour != null) {
        query = query.where('pricePerHour', isGreaterThanOrEqualTo: minPricePerHour);
      }
      if (minSlots2x != null) {
        query = query.where('slots2x', isGreaterThanOrEqualTo: minSlots2x);
      }
      if (minSlots1x != null) {
        query = query.where('slots1x', isGreaterThanOrEqualTo: minSlots1x);
      }
      if (is24Hours == true) {
        query = query.where('openingHours', isEqualTo: '24/7');
      }
      if (ownerFilter != null) {
        query = query.where('owner', isEqualTo: ownerFilter);
      }

      final QuerySnapshot querySnapshot = await query.get();
      final stations = querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Apply additional client-side filters
      return stations.where((station) {
        if (minTotalSlots != null && station.totalPorts < minTotalSlots) {
          return false;
        }
        return true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to filter stations: $e');
    }
  }

  /// Get stations with pagination
  static Future<List<StationModel>> getStationsPaginated({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? orderBy = 'createdAt',
    bool descending = true,
  }) async {
    try {
      Query query = _stationsCollection
          .orderBy(orderBy!, descending: descending)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch paginated stations: $e');
    }
  }

  /// Get stations by owner
  static Future<List<StationModel>> getStationsByOwner(String ownerEmail) async {
    try {
      final QuerySnapshot querySnapshot = await _stationsCollection
          .where('gmail', isEqualTo: ownerEmail)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch stations by owner: $e');
    }
  }

  /// Get stations sorted by price
  static Future<List<StationModel>> getStationsSortedByPrice({bool ascending = true}) async {
    try {
      final QuerySnapshot querySnapshot = await _stationsCollection
          .orderBy('pricePerHour', descending: !ascending)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch stations sorted by price: $e');
    }
  }

  /// Get stations with most slots
  static Future<List<StationModel>> getStationsWithMostSlots({int limit = 10}) async {
    try {
      final QuerySnapshot querySnapshot = await _stationsCollection.get();
      final stations = querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sort by total ports and take top N
      stations.sort((a, b) => b.totalPorts.compareTo(a.totalPorts));
      return stations.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch stations with most slots: $e');
    }
  }

  /// Get station statistics
  static Future<Map<String, dynamic>> getStationStatistics() async {
    try {
      final QuerySnapshot querySnapshot = await _stationsCollection.get();
      final stations = querySnapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (stations.isEmpty) {
        return {
          'totalStations': 0,
          'totalSlots2x': 0,
          'totalSlots1x': 0,
          'totalSlots': 0,
          'averagePrice': 0.0,
          'stations24h': 0,
          'averageSlots2x': 0.0,
          'averageSlots1x': 0.0,
          'priceRange': {'min': 0.0, 'max': 0.0},
        };
      }

      final totalSlots2x = stations.fold<int>(0, (sum, station) => sum + station.slots2x);
      final totalSlots1x = stations.fold<int>(0, (sum, station) => sum + station.slots1x);
      final totalSlots = totalSlots2x + totalSlots1x;
      final totalPrice = stations.fold<double>(0, (sum, station) => sum + station.pricePerHour);
      final stations24h = stations.where((station) => station.openingHours == '24/7').length;
      
      final prices = stations.map((s) => s.pricePerHour).toList();
      prices.sort();

      return {
        'totalStations': stations.length,
        'totalSlots2x': totalSlots2x,
        'totalSlots1x': totalSlots1x,
        'totalSlots': totalSlots,
        'averagePrice': totalPrice / stations.length,
        'stations24h': stations24h,
        'averageSlots2x': totalSlots2x / stations.length,
        'averageSlots1x': totalSlots1x / stations.length,
        'priceRange': {
          'min': prices.first,
          'max': prices.last,
        },
      };
    } catch (e) {
      throw Exception('Failed to get station statistics: $e');
    }
  }

  /// Listen to real-time station updates
  static Stream<List<StationModel>> getStationsStream() {
    return _stationsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Listen to a specific station updates
  static Stream<StationModel?> getStationStream(String stationId) {
    return _stationsCollection.doc(stationId).snapshots().map((doc) {
      if (doc.exists) {
        return StationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// Batch operations - Add multiple stations
  static Future<List<String>> addMultipleStations(List<Map<String, dynamic>> stationsData) async {
    try {
      final WriteBatch batch = _firestore.batch();
      final List<String> docIds = [];

      for (final stationData in stationsData) {
        final DocumentReference docRef = _stationsCollection.doc();
        docIds.add(docRef.id);
        
        stationData['createdAt'] = FieldValue.serverTimestamp();
        stationData['updatedAt'] = FieldValue.serverTimestamp();
        
        batch.set(docRef, stationData);
      }

      await batch.commit();
      return docIds;
    } catch (e) {
      throw Exception('Failed to add multiple stations: $e');
    }
  }

  /// Batch operations - Delete multiple stations
  static Future<void> deleteMultipleStations(List<String> stationIds) async {
    try {
      final WriteBatch batch = _firestore.batch();

      for (final stationId in stationIds) {
        batch.delete(_stationsCollection.doc(stationId));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete multiple stations: $e');
    }
  }

  /// Check if station name already exists
  static Future<bool> isStationNameExists(String name, {String? excludeStationId}) async {
    try {
      Query query = _stationsCollection.where('name', isEqualTo: name);
      final QuerySnapshot querySnapshot = await query.get();
      
      if (excludeStationId != null) {
        return querySnapshot.docs.any((doc) => doc.id != excludeStationId);
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check station name: $e');
    }
  }

  /// Get stations count
  static Future<int> getStationsCount() async {
    try {
      final AggregateQuerySnapshot aggregateQuery = await _stationsCollection.count().get();
      return aggregateQuery.count ?? 0;
    } catch (e) {
      // Fallback if count() is not available
      final QuerySnapshot querySnapshot = await _stationsCollection.get();
      return querySnapshot.docs.length;
    }
  }

  /// Helper method to calculate distance between two points (Haversine formula)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Helper method to convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}