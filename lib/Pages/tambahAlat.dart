import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sitanam_alvian_apk/Pages/akun.dart';

class TambahAlatPage extends StatefulWidget {
  const TambahAlatPage({Key? key}) : super(key: key);

  @override
  State<TambahAlatPage> createState() => _TambahAlatPageState();
}

class _TambahAlatPageState extends State<TambahAlatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final TextEditingController _alatController = TextEditingController();
  bool _scanned = false; // Untuk mencegah scan berulang-ulang

  void _onScan(Barcode barcode) {
    if (_scanned) return;
    setState(() {
      _alatController.text = barcode.rawValue ?? '';
      _scanned = true;
    });
  }

  Future<void> _connectDevice() async {
    print("🔘 Tombol Connect ditekan"); // Debug log

    final String plotName = _alatController.text.trim();
    final String? userUid = _auth.currentUser?.uid;

    print("📌 Plot name: $plotName");
    print("👤 User UID: $userUid");

    if (plotName.isEmpty || userUid == null) {
      _showAlert(
        title: "Gagal",
        message: "ID alat kosong atau pengguna belum login.",
      );
      return;
    }

    try {
      final plotRef = _dbRef.child(plotName);
      final snapshot = await plotRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // Ambil id list (bisa List atau Map)
        List<dynamic> idList = [];
        if (data.containsKey('id')) {
          if (data['id'] is List) {
            idList = List.from(data['id']);
          } else if (data['id'] is Map) {
            idList = (data['id'] as Map).values.toList();
          }
        }

        // Tambahkan user UID kalau belum ada
        if (!idList.contains(userUid)) {
          idList.add(userUid);

          // Simpan kembali dalam bentuk map { "1": uid1, "2": uid2 }
          final newMap = {
            for (int i = 0; i < idList.length; i++) "${i + 1}": idList[i],
          };

          await plotRef.update({'id': newMap});
        }

        _showAlert(
          title: "Berhasil",
          message: "Berhasil terkoneksi dengan $plotName",
          success: true,
        );
      } else {
        _showAlert(
          title: "Gagal",
          message: 'Plot "$plotName" tidak ditemukan di database.',
        );
      }
    } catch (e) {
      _showAlert(
        title: "Error",
        message: "Terjadi kesalahan: $e",
      );
    }
  }

  void _showAlert({required String title, required String message, bool success = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (success) {
                    Navigator.pushReplacementNamed(context, '/daftaralatpage');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("OK"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _alatController.clear();
      _scanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006400),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006400),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AkunScreen()),

              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Arahkan kamera ke QR Code Perangkat",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 300,
                        child: MobileScanner(
                          fit: BoxFit.cover,
                          onDetect: (BarcodeCapture capture) {
                            final barcode = capture.barcodes.firstOrNull;
                            if (barcode != null) {
                              _onScan(barcode);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      controller: _alatController,
                      enabled: false,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color.fromARGB(255, 224, 224, 224),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _connectDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 100, 0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'CONNECT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetScanner,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'RESET SCANNER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
