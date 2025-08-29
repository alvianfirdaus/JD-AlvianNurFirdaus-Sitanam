import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sitanam_alvian_apk/Routes/routes.dart';

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

    // Ganti gambar setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFirst = false;
        });
      }
    });

    // Lanjut ke login setelah total 4 detik
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.loginPage);
      }
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
              ? Image.asset(
                  'assets/images/logositanam.png',
                  key: const ValueKey('sitanam'),
                  width: 170,
                  height: 170,
                )
              : Image.asset(
                  'assets/images/jagoandigital.png',
                  key: const ValueKey('jagoandigital'),
                  width: 170,
                  height: 170,
                ),
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Sitanam X Jagoan Banyuwangi',
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xff4a4a4a),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
