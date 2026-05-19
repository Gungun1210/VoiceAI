import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'voice_service.dart';

class NotificationService {
  final VoiceService _voice;
  final List<SmsMessage> _messages = [];

  NotificationService(this._voice);

  // ── SMS inbox fetch ───────────────────────────────────────
  Future<List<SmsMessage>> fetchSmsMessages() async {
    final status = await Permission.sms.request();
    if (!status.isGranted) return [];
    final query = SmsQuery();
    final msgs = await query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 20,
    );
    _messages
      ..clear()
      ..addAll(msgs);
    return msgs;
  }

  // ── Read latest SMS out loud ──────────────────────────────
  Future<void> readLatestSms() async {
    final msgs = await fetchSmsMessages();
    if (msgs.isEmpty) {
      await _voice.speak('You have no recent messages.');
      return;
    }
    final latest = msgs.first;
    final sender = latest.sender ?? 'Unknown';
    final body   = latest.body   ?? '';
    await _voice.speak('New message from $sender. $body');
  }

  Future<void> startNotificationListener() async {
 
  }

  List<SmsMessage> get cachedMessages => _messages;
}