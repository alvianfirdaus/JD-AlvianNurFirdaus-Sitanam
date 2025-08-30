import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CuacaScreen extends StatefulWidget {
  final String adm4;

  /// Pakai ini kalau mau default Banyuwangi
  const CuacaScreen.banyuwangi({Key? key})
      : adm4 = '35.10.16.1002',
        super(key: key);

  /// Atau constructor umum kalau mau kelurahan lain
  const CuacaScreen({Key? key, required this.adm4}) : super(key: key);

  @override
  State<CuacaScreen> createState() => _CuacaScreenState();
}

class _CuacaScreenState extends State<CuacaScreen> {
  static const double _headerHeight = 230;

  bool _loading = true;
  String? _error;

  // Map<yyyy-MM-dd, List<WeatherEntry>>
  final Map<String, List<WeatherEntry>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=${Uri.encodeComponent(widget.adm4)}',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);

      // --- NORMALISASI: selalu jadi List<Map> records ---
      final List<Map<String, dynamic>> records = [];
      if (decoded is List) {
        for (final e in decoded) {
          if (e is Map) {
            records.add(e.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
      } else if (decoded is Map) {
        final data = decoded['data'];
        if (data is List) {
          for (final e in data) {
            if (e is Map) {
              records.add(e.map((k, v) => MapEntry(k.toString(), v)));
            }
          }
        } else if (data is Map) {
          records.add(Map<String, dynamic>.from(data));
        } else {
          records.add(decoded.map((k, v) => MapEntry(k.toString(), v)));
        }
      }

      if (records.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Tidak ada data.';
        });
        return;
      }

      // --- KUMPULKAN ITEM CUACA dari berbagai bentuk ---
      final List<Map<String, dynamic>> rawItems = [];

      void collect(dynamic v) {
        if (v == null) return;
        if (v is Map) {
          final m = v.map((k, val) => MapEntry(k.toString(), val));
          // Item jika punya salah satu key berikut
          const keys = {'local_datetime', 'datetime', 't', 'weather', 'weather_desc'};
          if (m.keys.toSet().intersection(keys).isNotEmpty) {
            rawItems.add(m);
          } else {
            // bukan item, telusuri anak-anaknya
            for (final val in m.values) {
              collect(val);
            }
          }
        } else if (v is List) {
          for (final e in v) collect(e);
        }
      }

      for (final r in records) {
        collect(r['cuaca'] ?? r['forecast'] ?? r['prakiraan'] ?? r['data'] ?? r);
      }

      // --- PARSE KE WeatherEntry ---
      double _asDouble(dynamic v) {
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0.0;
      }

      int _asInt(dynamic v) {
        if (v is num) return v.toInt();
        return int.tryParse(v?.toString() ?? '') ?? 0;
      }

      DateTime? _asDate(dynamic s) {
        if (s == null) return null;
        final str = s.toString();
        return DateTime.tryParse(str.replaceFirst(' ', 'T')) ?? DateTime.tryParse(str);
      }

      final List<WeatherEntry> entries = [];
      for (final it in rawItems) {
        final dt = _asDate(it['local_datetime'] ?? it['datetime']) ?? DateTime.now();

        entries.add(WeatherEntry(
          dateTime: dt,
          temperatureC: _asDouble(it['t']),
          humidity: _asInt(it['hu']),
          windSpeed: _asDouble(it['ws']),
          windDir: (it['wd'] ?? '').toString(),
          cloud: _asInt(it['tcc']),
          weatherCode: _asInt(it['weather']),
          weatherDesc: (it['weather_desc'] ?? '').toString(),
          iconUrl: (it['image'] ?? '').toString(),
        ));
      }

      // --- KELOMPOKKAN PER HARI & URUTKAN ---
      _grouped.clear();
      for (final e in entries) {
        final key =
            '${e.dateTime.year.toString().padLeft(4, '0')}-${e.dateTime.month.toString().padLeft(2, '0')}-${e.dateTime.day.toString().padLeft(2, '0')}';
        _grouped.putIfAbsent(key, () => []).add(e);
      }
      final keys = _grouped.keys.toList()..sort();
      final sorted = <String, List<WeatherEntry>>{};
      for (final k in keys) {
        final list = _grouped[k]!..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        sorted[k] = list;
      }
      _grouped
        ..clear()
        ..addAll(sorted);

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat prakiraan: $e';
      });
    }
  }

  String _formatPretty(DateTime dt) {
    // Contoh: Sen 30/03 07:00
    const hari = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final h = hari[dt.weekday % 7];
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$h $dd/$mm $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== Konten scroll di belakang header =====
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: _headerHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _fetchForecast,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  )
                else if (_grouped.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Tidak ada data prakiraan.'),
                  )
                else
                  ..._grouped.entries.map((day) {
                    final dateLabel = day.key; // yyyy-MM-dd
                    final list = day.value;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header hari
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                              const SizedBox(width: 6),
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // List perkiraan per 3 jam
                          ...list.map((w) => WeatherCard(
                                timeLabel: _formatPretty(w.dateTime),
                                iconUrl: w.iconUrl,
                                desc: w.weatherDesc.isNotEmpty ? w.weatherDesc : 'Cuaca',
                                tempC: w.temperatureC,
                                humidity: w.humidity,
                                windMs: w.windSpeed,
                              )),
                        ],
                      ),
                    );
                  }).toList(),

                // Kredit sumber
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Text(
                    'Sumber data: BMKG',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),

          // ===== Header tetap =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerHeight,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/cuaca.png'), // ganti sesuai asetmu
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ===== Box judul di header =====
          Positioned(
            top: 158,
            left: 90,
            right: 90,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_location_alt, color: Color.fromARGB(255, 59, 125, 5)),
                  const SizedBox(width: 8),
                  const Text(
                    'Banyuwangi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:  Color.fromARGB(255, 59, 125, 5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model item cuaca
class WeatherEntry {
  final DateTime dateTime;
  final double temperatureC;
  final int humidity; // %
  final double windSpeed; // m/s
  final String windDir; // ex: 'SW'
  final int cloud; // tcc
  final int weatherCode; // BMKG code
  final String weatherDesc;
  final String iconUrl;

  WeatherEntry({
    required this.dateTime,
    required this.temperatureC,
    required this.humidity,
    required this.windSpeed,
    required this.windDir,
    required this.cloud,
    required this.weatherCode,
    required this.weatherDesc,
    required this.iconUrl,
  });
}

/// Kartu tampilan cuaca per 3 jam
class WeatherCard extends StatelessWidget {
  final String timeLabel;
  final String iconUrl;
  final String desc;
  final double tempC;
  final int humidity;
  final double windMs;

  const WeatherCard({
    Key? key,
    required this.timeLabel,
    required this.iconUrl,
    required this.desc,
    required this.tempC,
    required this.humidity,
    required this.windMs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon cuaca
            SizedBox(
              width: 56,
              height: 56,
              child: iconUrl.isNotEmpty
                  ? Image.network(
                      iconUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.cloud),
                    )
                  : const Icon(Icons.cloud),
            ),
            const SizedBox(width: 12),

            // Keterangan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.thermostat, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text('${tempC.toStringAsFixed(0)}°C'),
                      const SizedBox(width: 12),
                      const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('$humidity%'),
                      const SizedBox(width: 12),
                      const Icon(Icons.air, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('${windMs.toStringAsFixed(1)} m/s'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
