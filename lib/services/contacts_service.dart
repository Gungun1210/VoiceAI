import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class AppContactsService {
  List<Contact> _contacts = [];

  Future<List<Contact>> fetchContacts() async {
    try {

      final status = await Permission.contacts.request();

      if (status.isDenied || status.isPermanentlyDenied) {
        if (status.isPermanentlyDenied) await openAppSettings();
        return [];
      }

      _contacts = await FlutterContacts.getContacts(withProperties: true);
      return _contacts;
    } catch (e) {
      return [];
    }
  }

 
  Future<void> ensureContactsLoaded() async {
    if (_contacts.isEmpty) {
      await fetchContacts();
    }
  }


  Contact? findContact(String name) {
    if (_contacts.isEmpty) return null;
    final lower = name.toLowerCase().trim();

    // Level 1: exact full name match
    try {
      return _contacts.firstWhere(
        (c) => c.displayName.toLowerCase() == lower,
      );
    } catch (_) {}

    
    try {
      return _contacts.firstWhere(
        (c) => c.displayName.toLowerCase().contains(lower),
      );
    } catch (_) {}

    try {
      return _contacts.firstWhere(
        (c) => c.displayName
            .toLowerCase()
            .split(' ')
            .any((word) => word.startsWith(lower)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> callContact(String name) async {
    await ensureContactsLoaded();
    final contact = findContact(name);
    if (contact == null) return false;
    if (contact.phones.isEmpty) return false;
    final phone =
        contact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  int get contactCount => _contacts.length;
}