import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _auth      = AuthService();
  bool _loading    = false;
  bool _obscure    = true;
  String? _error;

  Future<void> _signUp() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _auth.signUp(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      if (res['user'] != null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _error = res['message'] ?? 'Sign up failed');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A0F), Color(0xFF1A0A2E)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(children: [
              const SizedBox(height: 24),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF7C4DFF).withOpacity(0.4),
                    blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Create Account',
                  style: TextStyle(fontSize: 28,
                      fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Join VoiceAI today',
                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 40),
              _field(_nameCtrl, 'Full Name', Icons.badge_outlined),
              const SizedBox(height: 14),
              _field(_emailCtrl, 'Email Address', Icons.email_outlined),
              const SizedBox(height: 14),
              _field(_passCtrl, 'Password', Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                        color: Colors.white38),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _loading ? null : _signUp,
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.4),
                      blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Create Account',
                            style: TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                    style: TextStyle(color: Colors.white.withOpacity(0.5))),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Sign In',
                      style: TextStyle(color: Color(0xFF7C4DFF),
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool obscure = false, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}