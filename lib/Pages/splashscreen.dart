import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitanam_alvian_apk/Routes/routes.dart';

const _kIsLoggedIn = 'isLoggedIn';
const _kLoginAtMs  = 'loginAt';
const _kSessionTTL = 24 * 60 * 60 * 1000; // 24 jam (ms)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showFirst = true;

  @override
  void initState() {
    super.initState();

    // Ganti gambar setelah 2 detik (slideshow)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showFirst = false);
    });

    // Tentukan tujuan (login / daftar alat) lalu navigasi setelah total 4 detik
    _decideAndNavigate();
  }

  Future<void> _decideAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_kIsLoggedIn) ?? false;
    final loginAt  = prefs.getInt(_kLoginAtMs) ?? 0;
    final nowMs    = DateTime.now().millisecondsSinceEpoch;

    final hasAuth  = FirebaseAuth.instance.currentUser != null;
    final notExpired = (nowMs - loginAt) < _kSessionTTL;

    final targetRoute = (loggedIn && hasAuth && notExpired)
        ? '/daftaralatpage' // langsung ke daftar alat
        : Routes.loginPage; // ke login

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          child: _showFirst
              ? Image.asset('assets/images/logositanam.png',
                  key: const ValueKey('sitanam'), width: 170, height: 170)
              : Image.asset('assets/images/jagoandigital.png',
                  key: const ValueKey('jagoandigital'), width: 170, height: 170),
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Sitanam X Jagoan Banyuwangi',
          style: TextStyle(fontFamily: 'Urbanist', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xff4a4a4a)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
