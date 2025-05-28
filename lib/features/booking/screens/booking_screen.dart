import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late Stream<QuerySnapshot> _bookingsStream;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('endTime', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookingsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookings = snapshot.data!.docs;
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final booking = bookings[i];
              final data = booking.data() as Map<String, dynamic>;
              final stationName = data['stationName'] ?? 'Station';
              final startTime = (data['startTime'] as Timestamp).toDate();
              final endTime = (data['endTime'] as Timestamp).toDate();
              final slotType = data['slotType'] ?? '';
              final plate = data['plateNumber'] ?? '';
              final vehicle = data['vehicleType'] ?? '';
              final price = data['price'] ?? '';
              final status = data['status'] ?? '';
              final lat = data['latitude']?.toString() ?? '';
              final lng = data['longitude']?.toString() ?? '';
              final bookingId = booking.id;

              // Get latitude and longitude as double (null safe)
              double? latitude, longitude;
              try {
                if (data['latitude'] != null && data['longitude'] != null) {
                  latitude = data['latitude'] is double
                      ? data['latitude']
                      : double.tryParse(data['latitude'].toString());
                  longitude = data['longitude'] is double
                      ? data['longitude']
                      : double.tryParse(data['longitude'].toString());
                }
              } catch (_) {
                latitude = null;
                longitude = null;
              }

              final isEnded = DateTime.now().isAfter(endTime);

              return Opacity(
                opacity: isEnded ? 0.45 : 1,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Station Name + Countdown
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                stationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (!isEnded)
                              _BookingCountdown(
                                endTime: endTime,
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            else
                              const Text(
                                "Ended",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Status Row
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Colors.green[400],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              status.toString().toUpperCase(),
                              style: TextStyle(
                                color: Colors.green[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Date/time row
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 17,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${DateFormat('MMM d, HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Vehicle/Plate/Speed (No overflow)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 18,
                              color: Colors.teal[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vehicle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.confirmation_number,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                "Plate: $plate",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        if (slotType != null && slotType.toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flash_on,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$slotType Speed",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Price row
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 20,
                              color: Colors.green[700],
                            ),
                            Text(
                              " Rs. ${price is num ? price.toStringAsFixed(1) : price}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Buttons
                       Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isEnded
                                    ? null
                                    : () async {
                                        final lat = data['latitude']?.toString() ?? '';
                                        final lng = data['longitude']?.toString() ?? '';
                                        if (lat.isNotEmpty && lng.isNotEmpty && lat != 'null' && lng != 'null') {
                                          final url = Uri.parse(
                                            "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                                          );
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(
                                              url,
                                              mode: LaunchMode.externalApplication,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Could not open Maps!")),
                                            );
                                          }
                                        } else {
                                          final addressStr = data['stationAddress'] ?? data['address'] ?? '';
                                          if (addressStr.isNotEmpty) {
                                            final addressUrl = Uri.encodeComponent(addressStr);
                                            final url = Uri.parse(
                                              'https://www.google.com/maps/search/?api=1&query=$addressUrl',
                                            );
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(
                                                url,
                                                mode: LaunchMode.externalApplication,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Could not open Maps!")),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Location not available")),
                                            );
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.directions, color: Colors.white),
                                label: const Text("Direction"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  minimumSize: const Size(double.infinity, 48),
                                  elevation: 1.5,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red[100]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: const Size(90, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 0,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: isEnded
                                    ? null
                                    : () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Cancel Booking?"),
                                            content: const Text("Are you sure you want to cancel this booking?"),
                                            actions: [
                                              TextButton(
                                                child: const Text("No"),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              TextButton(
                                                child: const Text("Yes"),
                                                onPressed: () => Navigator.pop(context, true),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await FirebaseFirestore.instance
                                              .collection('bookings')
                                              .doc(bookingId)
                                              .delete();
                                        }
                                      },
                                icon: const Icon(Icons.cancel, size: 16),
                                label: const Text(
                                  "Cancel",
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Booking Countdown Widget (updates every second)
class _BookingCountdown extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? style;

  const _BookingCountdown({required this.endTime, this.style});

  @override
  State<_BookingCountdown> createState() => _BookingCountdownState();
}

class _BookingCountdownState extends State<_BookingCountdown> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    setState(() {
      _remaining = widget.endTime.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.inSeconds <= 0) {
      return const Text(
        "Ended",
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      );
    }
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final mins = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Text("$hours:$mins:$secs", style: widget.style);
  }
}
