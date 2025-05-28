// lib/features/booking/widgets/booking_popup.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:eco_ev_app/data/services/notification_service.dart';

class BookingPopup extends StatefulWidget {
  final String stationId;
  final Map<String, dynamic> stationData;

  const BookingPopup({
    Key? key,
    required this.stationId,
    required this.stationData,
  }) : super(key: key);

  @override
  State<BookingPopup> createState() => _BookingPopupState();
}

class _BookingPopupState extends State<BookingPopup> {
  String? _vehicleType;
  final _plateController = TextEditingController();
  String? _slotType;
  DateTime? _startTime;
  DateTime? _endTime;
  double _price = 0.0;
  bool _checking = false;
  bool _available2x = false;
  bool _available1x = false;
  bool _booking = false;
  bool _isLoading = false;

  List<String> vehicleTypes = ["Motorbike", "Three-wheeler", "Car"];

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 2)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          _endTime = null; // reset end time if start time changes
        });
      }
    }
  }

  Future<void> _pickEndTime() async {
    if (_startTime == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime!,
      firstDate: _startTime!,
      lastDate: _startTime!.add(const Duration(days: 1)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime!),
      );
      if (time != null) {
        setState(() {
          _endTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _checkAvailability() async {
    if (_startTime == null || _endTime == null) return;
    setState(() => _checking = true);

    final bookings =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('stationId', isEqualTo: widget.stationId)
            .where('endTime', isGreaterThan: _startTime)
            .where('startTime', isLessThan: _endTime)
            .get();

    int booked2x = 0;
    int booked1x = 0;
    for (var doc in bookings.docs) {
      final slotType = doc['slotType'] ?? '1x';
      if (slotType == '2x') booked2x++;
      if (slotType == '1x') booked1x++;
    }

    final max2x = widget.stationData['slots2x'] ?? 0;
    final max1x = widget.stationData['slots1x'] ?? 0;

    setState(() {
      _available2x = booked2x < max2x;
      _available1x = booked1x < max1x;
      _checking = false;
    });
  }

  void _calculatePrice() {
    if (_startTime == null || _endTime == null || _slotType == null) {
      setState(() => _price = 0.0);
      return;
    }
    final hours = _endTime!.difference(_startTime!).inMinutes / 60.0;
    double pricePerHour = (widget.stationData['pricePerHour'] ?? 0).toDouble();
    double price =
        _slotType == "2x" ? pricePerHour * 2 * hours : pricePerHour * hours;
    setState(() {
      _price = price.ceilToDouble(); // round up
    });
  }

  Future<void> _bookNow() async {
    setState(() => _booking = true);

    try {
      // Validate input
      if (_vehicleType == null ||
          _plateController.text.trim().isEmpty ||
          _slotType == null ||
          _startTime == null ||
          _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all fields')),
        );
        setState(() => _booking = false);
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        setState(() => _booking = false);
        return;
      }

      // Compose booking data
      final bookingData = {
        'stationId': widget.stationId,
        'stationName': widget.stationData['name'],
        'userId': userId,
        'vehicleType': _vehicleType,
        'plateNumber': _plateController.text.trim(),
        'startTime': _startTime,
        'endTime': _endTime,
        'slotType': _slotType,
        'price': _price,
        'status': 'booked',
        'createdAt': FieldValue.serverTimestamp(),
        'latitude': widget.stationData['latitude'], // <-- Added
        'longitude': widget.stationData['longitude'], // <-- Added
      };

      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      final bookingTime =
          '${DateFormat('yyyy-MM-dd HH:mm').format(_startTime!)} - ${DateFormat('yyyy-MM-dd HH:mm').format(_endTime!)}';

      // After successful booking (add notification)
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Booking Confirmed',
        'body':
            'Your charging slot at ${widget.stationData['name']} is booked for $bookingTime!',
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });

      // Local notification
      await NotificationService.showNotification(
        'Booking Confirmed',
        'Your charging slot at ${widget.stationData['name']} is booked for $bookingTime!',
      );

      // After a successful booking
      if (mounted) {
        Navigator.pop(context); // Close popup first
        await Future.delayed(const Duration(milliseconds: 100));
        Navigator.pushReplacementNamed(context, '/booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _calculatePrice(); // update price when build
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Book Charging Slot",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  items:
                      vehicleTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  decoration: const InputDecoration(
                    labelText: "Vehicle Type",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _vehicleType = val),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _plateController,
                  decoration: const InputDecoration(
                    labelText: "Vehicle Plate Number",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickStartTime,
                        child: Text(
                          _startTime == null
                              ? "Pick Start Time"
                              : DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(_startTime!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickEndTime,
                        child: Text(
                          _endTime == null
                              ? "Pick End Time"
                              : DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(_endTime!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _checking
                                ? null
                                : () {
                                  setState(() => _slotType = '2x');
                                  _checkAvailability();
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _slotType == '2x'
                                  ? Colors.green
                                  : _available2x
                                  ? Colors.teal[100]
                                  : Colors.grey[300],
                        ),
                        child: Text(
                          "2x Speed Slot",
                          style: TextStyle(
                            color:
                                _slotType == '2x' ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _checking
                                ? null
                                : () {
                                  setState(() => _slotType = '1x');
                                  _checkAvailability();
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _slotType == '1x'
                                  ? Colors.green
                                  : _available1x
                                  ? Colors.teal[100]
                                  : Colors.grey[300],
                        ),
                        child: Text(
                          "1x Speed Slot",
                          style: TextStyle(
                            color:
                                _slotType == '1x' ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_checking) const LinearProgressIndicator(),
                Text(
                  "Total Price: Rs. ${_price.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ||
                                    _vehicleType == null ||
                                    _plateController.text.trim().isEmpty ||
                                    _slotType == null ||
                                    _startTime == null ||
                                    _endTime == null
                                ? null
                                : () async {
                                  setState(() => _isLoading = true);
                                  await _bookNow();
                                  setState(() => _isLoading = false);
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 48),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Book Now'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
