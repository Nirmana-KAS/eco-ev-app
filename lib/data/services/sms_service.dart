// lib/data/services/sms_service.dart

import 'package:url_launcher/url_launcher.dart';

class SMSService {
  /// Sends an SMS by opening the phone's SMS app with a prefilled message.
  /// Returns true if launched successfully, otherwise throws an error.
  static Future<bool> sendSMS({
    required String message,
    required String number,
  }) async {
    if (number.trim().isEmpty) {
      throw 'No phone number provided';
    }
    // Clean up the phone number (remove spaces, dashes, etc.)
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final encodedMessage = Uri.encodeComponent(message);

    final uri = Uri.parse('sms:$cleanNumber?body=$encodedMessage');

    print('Launching SMS: $uri');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    } else {
      throw 'Could not launch SMS app';
    }
  }
}
