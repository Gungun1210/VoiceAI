import 'package:flutter/material.dart';
import '../../services/voice_service.dart';
import '../../services/contacts_service.dart';
import '../../services/notification_service.dart';
import '../../services/payment_service.dart';
import '../../services/food_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // ── Services ───────────────────────────────────────────────
  final _voice    = VoiceService();
  final _contacts = AppContactsService();
  late final _notification = NotificationService(_voice);
  late final _payment      = PaymentService(_contacts);
  final _food              = FoodService();
  final _auth              = AuthService();

  // ── State ──────────────────────────────────────────────────
  bool   _listening   = false;
  String _transcript  = '';
  String _statusMsg   = 'Tap the mic and speak a command';
  String _userName    = 'User';
  final List<_LogEntry> _log = [];

  // ── Animations ─────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulse = Tween(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _init();
  }

  Future<void> _init() async {
    await _voice.initTts();
    await _voice.initSpeech();
    await _notification.startNotificationListener();
    final name = await _auth.getUserName();
    setState(() {
      _userName  = name;
      _statusMsg = 'Loading contacts…';
    });
    // Fetch contacts and tell user how many loaded
    final contacts = await _contacts.fetchContacts();
    setState(() => _statusMsg =
        contacts.isEmpty
            ? 'No contacts loaded. Check permission.'
            : 'Loaded ${contacts.length} contacts. Tap mic to speak.');
    await _voice.speak(
      contacts.isEmpty
          ? 'Hello $_userName. Could not load contacts. Please allow contacts permission.'
          : 'Hello $_userName. I have loaded ${contacts.length} contacts. How can I help you?',
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  // ── Mic toggle ─────────────────────────────────────────────
  void _toggleListening() {
    if (_listening) {
      _voice.stopListening();
      setState(() {
        _listening = false;
        _statusMsg = 'Tap the mic and speak a command';
      });
      _waveCtrl.stop();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    setState(() {
      _listening  = true;
      _transcript = '';
      _statusMsg  = 'Listening…';
    });
    _waveCtrl.repeat();
    _voice.startListening(
      onResult: (words) => setState(() => _transcript = words),
      onDone: _handleCommand,
    );
  }

  // ── Command dispatcher ─────────────────────────────────────
  Future<void> _handleCommand() async {
    if (_transcript.isEmpty) {
      setState(() {
        _listening = false;
        _statusMsg = 'Nothing heard. Try again.';
      });
      _waveCtrl.stop();
      return;
    }

    setState(() {
      _listening = false;
      _statusMsg = 'Processing…';
    });
    _waveCtrl.stop();

    final cmd = await _voice.parseCommand(_transcript);
    _addLog(_transcript, cmd.intent);

    switch (cmd.intent) {
      case 'call':
        await _handleCall(cmd.target ?? '');
        break;
      case 'pay':
        await _handlePayment(cmd.target ?? '', cmd.amount ?? '0');
        break;
      case 'food':
        await _handleFood();
        break;
      case 'sms_read':
        await _notification.readLatestSms();
        setState(() => _statusMsg = 'Reading your messages…');
        break;
      default:
        await _voice.speak('Sorry, I did not understand that. Please try again.');
        setState(() => _statusMsg = 'Command not recognised');
    }
  }

  Future<void> _handleCall(String name) async {
    if (name.isEmpty) {
      await _voice.speak('Who would you like to call?');
      setState(() => _statusMsg = 'Contact name not found');
      return;
    }
    setState(() => _statusMsg = 'Calling $name…');
    await _voice.speak('Calling $name');
    final ok = await _contacts.callContact(name);
    if (!ok) {
      await _voice.speak(
          'Sorry, I could not find $name in your contacts. '
          'I have ${_contacts.contactCount} contacts loaded.');
      setState(() => _statusMsg = 'Contact not found: $name');
    }
  }

  Future<void> _handlePayment(String name, String amount) async {
    setState(() => _statusMsg = 'Opening payment for $name…');
    await _voice.speak('Opening payment of ₹$amount to $name');
    final ok = await _payment.initiatePayment(
        contactName: name, amount: amount);
    if (!ok) {
      await _voice.speak(
          'Could not open a payment app. Please install Google Pay or PhonePe.');
      setState(() => _statusMsg = 'No UPI app found');
    }
  }

  Future<void> _handleFood() async {
    setState(() => _statusMsg = 'Opening food delivery app…');
    await _voice.speak('Opening food delivery app');
    final result = await _food.orderFood();
    setState(() => _statusMsg = 'Opened $result');
  }

  void _addLog(String text, String intent) {
    setState(() {
      _log.insert(0, _LogEntry(
          text: text, intent: intent,
          time: TimeOfDay.now().format(context)));
      if (_log.length > 20) _log.removeLast();
      _statusMsg = 'Done';
    });
  }

  // ── Sign out ───────────────────────────────────────────────
  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A0F), Color(0xFF0D0D20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  const SizedBox(height: 24),
                  _buildMicCard(),
                  const SizedBox(height: 24),
                  _buildQuickCmds(),
                  const SizedBox(height: 24),
                  _buildLog(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('VoiceAI',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 18)),
          Text('Hello, $_userName',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ]),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white54),
          onPressed: _signOut,
        ),
      ]),
    );
  }

  Widget _buildMicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C4DFF).withOpacity(0.15),
            const Color(0xFF448AFF).withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
      ),
      child: Column(children: [
        AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _waveCtrl]),
          builder: (_, __) {
            return GestureDetector(
              onTap: _toggleListening,
              child: Stack(alignment: Alignment.center, children: [
                if (_listening) ...[
                  _ring(80, _waveCtrl.value),
                  _ring(64, (_waveCtrl.value + 0.3) % 1.0),
                ],
                ScaleTransition(
                  scale: _listening
                      ? _pulse
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _listening
                            ? [const Color(0xFFFF4081), const Color(0xFFFF1744)]
                            : [const Color(0xFF7C4DFF), const Color(0xFF448AFF)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_listening
                              ? const Color(0xFFFF4081)
                              : const Color(0xFF7C4DFF))
                              .withOpacity(0.5),
                          blurRadius: 32, spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white, size: 40,
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _listening
                ? _transcript.isEmpty ? 'Say something…' : _transcript
                : _statusMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _listening
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
              fontSize: _listening && _transcript.isNotEmpty ? 16 : 14,
              fontWeight:
                  _listening ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _ring(double maxR, double t) {
    final r = maxR * t;
    return Container(
      width: 88 + r, height: 88 + r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFF4081).withOpacity(1 - t),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildQuickCmds() {
    final cmds = [
      _QuickCmd(Icons.call_rounded, 'Call', '"Call name"',
          const Color(0xFF00BFA5)),
      _QuickCmd(Icons.payment_rounded, 'Pay', '"Pay ₹500 to name"',
          const Color(0xFFFFAB00)),
      _QuickCmd(Icons.fastfood_rounded, 'Food', '"Order food"',
          const Color(0xFFFF6D00)),
      _QuickCmd(Icons.sms_rounded, 'SMS', '"Read messages"',
          const Color(0xFF448AFF)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick Commands',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: cmds.map((c) => _quickCard(c)).toList(),
      ),
    ]);
  }

  Widget _quickCard(_QuickCmd c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(c.icon, color: c.color, size: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            Text(c.example,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  Widget _buildLog() {
    if (_log.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Command History',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 12),
      ..._log.map((e) => _logTile(e)),
    ]);
  }

  Widget _logTile(_LogEntry e) {
    final colors = {
      'call':     const Color(0xFF00BFA5),
      'pay':      const Color(0xFFFFAB00),
      'food':     const Color(0xFFFF6D00),
      'sms_read': const Color(0xFF448AFF),
      'unknown':  Colors.white38,
    };
    final icons = {
      'call':     Icons.call_rounded,
      'pay':      Icons.payment_rounded,
      'food':     Icons.fastfood_rounded,
      'sms_read': Icons.sms_rounded,
      'unknown':  Icons.help_outline_rounded,
    };
    final color = colors[e.intent] ?? Colors.white38;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icons[e.intent] ?? Icons.help_outline_rounded,
            color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(e.text,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13))),
        Text(e.time,
            style: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: 11)),
      ]),
    );
  }
}

// ── Data classes ───────────────────────────────────────────
class _QuickCmd {
  final IconData icon;
  final String title, example;
  final Color color;
  const _QuickCmd(this.icon, this.title, this.example, this.color);
}

class _LogEntry {
  final String text, intent, time;
  const _LogEntry(
      {required this.text, required this.intent, required this.time});
}