import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';


class VoiceCommand {
  final String intent;   
  final String? target;  
  final String? amount;  
  final String raw;

  const VoiceCommand({
    required this.intent,
    this.target,
    this.amount,
    required this.raw,
  });
}

// ── Voice Service ──────────────────────────────────────────
class VoiceService {
  final _speech = stt.SpeechToText();
  final _tts    = FlutterTts();
  bool _isListening = false;

  // ── TTS init ──────────────────────────────────────────────
  Future<void> initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  // ── STT ───────────────────────────────────────────────────
  Future<bool> initSpeech() => _speech.initialize();

  bool get isListening => _isListening;

  void startListening({
    required void Function(String words) onResult,
    required void Function() onDone,
  }) {
    _isListening = true;
    _speech.listen(
      onResult: (r) {
        if (r.finalResult) {
          _isListening = false;
          onResult(r.recognizedWords);
          onDone();
        }
      },
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
  }

  // ── Groq NLU — parse intent from transcript ───────────────
  Future<VoiceCommand> parseCommand(String transcript) async {
    final groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (groqKey.isEmpty) return _localParse(transcript);

    try {
      final res = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $groqKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192',
          'messages': [
            {
              'role': 'system',
              'content': '''
You are a voice command parser. Given a user utterance, return ONLY a JSON object:
{
  "intent": "call" | "pay" | "food" | "sms_read" | "unknown",
  "target": "<contact name if applicable>",
  "amount": "<numeric amount in rupees if applicable>"
}
No explanation, only JSON.
Examples:
"Call name" → {"intent":"call","target":"name","amount":null}
"Pay 500 rupees to name" → {"intent":"pay","target":"name","amount":"500"}
"I want to order food" → {"intent":"food","target":null,"amount":null}
"Read my messages" → {"intent":"sms_read","target":null,"amount":null}
'''
            },
            {'role': 'user', 'content': transcript}
          ],
          'temperature': 0,
          'max_tokens': 100,
        }),
      );
      final body = jsonDecode(res.body);
      final content = body['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(content.trim());
      return VoiceCommand(
        intent: parsed['intent'] ?? 'unknown',
        target: parsed['target'],
        amount: parsed['amount'],
        raw: transcript,
      );
    } catch (_) {
      return _localParse(transcript);
    }
  }

  // ── Fallback regex parser (no API needed) ─────────────────
  VoiceCommand _localParse(String t) {
    final lower = t.toLowerCase();
    // CALL
    final callMatch = RegExp(r'call\s+(.+)').firstMatch(lower);
    if (callMatch != null) {
      return VoiceCommand(intent: 'call', target: _capitalize(callMatch.group(1)!.trim()), raw: t);
    }
    // PAY
    final payMatch = RegExp(r'pay\s+(\d+).*?to\s+(.+)').firstMatch(lower);
    if (payMatch != null) {
      return VoiceCommand(
        intent: 'pay',
        amount: payMatch.group(1),
        target: _capitalize(payMatch.group(2)!.trim()),
        raw: t,
      );
    }
    // FOOD
    if (lower.contains('order food') || lower.contains('food order') || lower.contains('hungry')) {
      return VoiceCommand(intent: 'food', raw: t);
    }
    // SMS READ
    if (lower.contains('message') || lower.contains('notification') || lower.contains('sms')) {
      return VoiceCommand(intent: 'sms_read', raw: t);
    }
    return VoiceCommand(intent: 'unknown', raw: t);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}