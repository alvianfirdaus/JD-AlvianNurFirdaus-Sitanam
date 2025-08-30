import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitanam_alvian_apk/Pages/kendali.dart';
import 'package:sitanam_alvian_apk/Pages/lingkungan.dart';
import 'package:sitanam_alvian_apk/Pages/catatan.dart';
import 'package:sitanam_alvian_apk/Pages/hitung_nutrisi.dart';
import 'package:sitanam_alvian_apk/Pages/akun.dart';
import 'package:sitanam_alvian_apk/Pages/edukasi.dart';
import 'package:sitanam_alvian_apk/Pages/cuaca_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int selectedIndex;

  const DashboardScreen({Key? key, this.selectedIndex = 0}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _headerHeight = 230;

  String selectedPlot = "Plot 01"; // Default selected plot
  Map<String, dynamic> plotData = {}; // Plot data

  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadSelectedPlot(); // Load saved plot
  }

  Future<void> _loadSelectedPlot() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlot = prefs.getString('selected_plot') ?? "Plot 01";
    setState(() {
      selectedPlot = savedPlot;
    });
    listenToPlotData(savedPlot.toLowerCase().replaceAll(' ', ''));
  }

  // Listen to Firebase Realtime Database updates
  void listenToPlotData(String plot) {
    databaseReference.child(plot).onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          plotData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== Scrollable content (di belakang header) =====
          SingleChildScrollView(
            // padding top = tinggi header, supaya konten mulai tepat di bawah header
            padding: const EdgeInsets.only(top: _headerHeight),
            child: Column(
              children: [
                // Grid Menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // ikut scroll parent
                    children: [
                      DashboardItem(
                        imagePath: 'assets/images/iconcontrol.png',
                        label: 'Kendali IOT',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => KendaliScreen()),
                          );
                        },
                      ),
                      DashboardItem(
                        imagePath: 'assets/images/iconlingkungan.png',
                        label: 'Status Lingkungan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LingkunganScreen()),
                          );
                        },
                      ),
                      DashboardItem(
                        imagePath: 'assets/images/iconscript.png',
                        label: 'Catatan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CatatanScreen()),
                          );
                        },
                      ),
                      DashboardItem(
                        imagePath: 'assets/images/icondeteksi.png',
                        label: 'Rekomendasi Pupuk',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HitungNutrisiScreen()),
                          );
                        },
                      ),
                      DashboardItem(
                        imagePath: 'assets/images/iconedu.png',
                        label: 'Edukasi Pertanian',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EdukasiScreen()),
                          );
                        },
                      ),
                      DashboardItem(
                        imagePath: 'assets/images/iconcuaca.png',
                        label: 'Perkiraan Cuaca',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CuacaScreen(adm4: '35.10.16.1002'), // ganti kode ADM4 kamu
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // padding bawah
              ],
            ),
          ),

          // ===== Fixed header (tetap) =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerHeight,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/DashboardHeader.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ===== PlotBox di atas header (tetap) =====
          Positioned(
            top: 158,
            left: 90,
            right: 90,
            child: Center(
              child: PlotBox(
                plotName: selectedPlot,
                isSelected: true,
                onTap: () {
                  final plotKey = selectedPlot.toLowerCase().replaceAll(' ', '');
                  listenToPlotData(plotKey);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlotBox extends StatelessWidget {
  final bool isSelected;
  final String plotName;
  final VoidCallback onTap;

  const PlotBox({
    required this.isSelected,
    required this.plotName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color.fromARGB(255, 255, 255, 255) : Colors.green.shade900,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 8, 102, 12).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.devices,
              color: isSelected ? const Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
            ),
            const SizedBox(width: 8),
            Text(
              'Perangkat : $plotName',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const DashboardItem({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.green.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 48,
                  height: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
