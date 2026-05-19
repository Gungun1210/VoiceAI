import 'package:url_launcher/url_launcher.dart';
import 'contacts_service.dart';

class PaymentService {
  final AppContactsService _contacts;

  PaymentService(this._contacts);

  Future<bool> initiatePayment({
    required String contactName,
    required String amount,
  }) async {
    final contact = _contacts.findContact(contactName);
    String phone = '';

    if (contact != null && contact.phones.isNotEmpty) {
      phone = contact.phones.first.number.replaceAll(RegExp(r'[^\d]'), '');
      if (phone.length > 10) phone = phone.substring(phone.length - 10);
    }

    // UPI Intent URI — opens Google Pay, PhonePe, Paytm, etc.
    final upiUri = Uri.parse(
      'upi://pay?'
      'pa=${phone.isNotEmpty ? "$phone@ybl" : "merchant@upi"}'
      '&pn=${Uri.encodeComponent(contactName)}'
      '&am=$amount'
      '&cu=INR'
      '&tn=${Uri.encodeComponent("Payment via VoiceAI")}',
    );

    if (await canLaunchUrl(upiUri)) {
      await launchUrl(upiUri, mode: LaunchMode.externalApplication);
      return true;
    }

    // Fallback: open Google Pay directly
    final gpay = Uri.parse(
      'intent://pay#Intent;scheme=upi;'
      'package=com.google.android.apps.nbu.paisa.user;end',
    );
    if (await canLaunchUrl(gpay)) {
      await launchUrl(gpay, mode: LaunchMode.externalApplication);
      return true;
    }

    // Fallback: PhonePe
    final phonepe = Uri.parse('phonepe://pay');
    if (await canLaunchUrl(phonepe)) {
      await launchUrl(phonepe, mode: LaunchMode.externalApplication);
      return true;
    }

    return false;
  }
}