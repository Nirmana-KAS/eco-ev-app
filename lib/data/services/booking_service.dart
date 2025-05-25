import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final CollectionReference bookings = FirebaseFirestore.instance.collection('bookings');

  Future<bool> hasActiveBooking(String userId) async {
    final now = DateTime.now();
    final active = await bookings
        .where('userId', isEqualTo: userId)
        .where('endTime', isGreaterThan: now)
        .get();
    return active.docs.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getStationBookings(String stationId, DateTime start, DateTime end, String slotType) async {
    final result = await bookings
        .where('stationId', isEqualTo: stationId)
        .where('slotType', isEqualTo: slotType)
        .where('endTime', isGreaterThan: start)
        .where('startTime', isLessThan: end)
        .get();
    return result.docs.map((e) => e.data() as Map<String, dynamic>).toList();
  }

  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    await bookings.add(bookingData);
  }
}
