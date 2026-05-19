import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl = dotenv.env['BACKEND_URL'] ?? '';


  String? _sessionCookie;

  Future<void> _loadCookie() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
  }

  Future<void> _saveCookie(http.Response response) async {
    final raw = response.headers['set-cookie'];
    if (raw != null) {
      // Extract just the session ID part (before the first semicolon)
      final cookie = raw.split(';').first.trim();
      _sessionCookie = cookie;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_cookie', cookie);
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_sessionCookie != null) 'Cookie': _sessionCookie!,
  };

  // ── Check if user is logged in ────────────────────────────
  Future<bool> isLoggedIn() async {
    await _loadCookie();
    if (_sessionCookie == null) return false;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Sign Up ───────────────────────────────────────────────
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) {
      await _saveCookie(res);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', data['user']['name'] ?? name);
    }
    return data;
  }

  // ── Sign In ───────────────────────────────────────────────
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await _saveCookie(res);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', data['user']['name'] ?? '');
    }
    return data;
  }

  // ── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _loadCookie();
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/signout'),
        headers: _headers,
      );
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
    await prefs.remove('userName');
    _sessionCookie = null;
  }

  // ── Get stored user name ──────────────────────────────────
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? 'User';
  }

  // ── Check signup/signin response success ──────────────────
  bool isSuccess(Map<String, dynamic> data, int statusCode) {
    return statusCode == 200 || statusCode == 201;
  }
}