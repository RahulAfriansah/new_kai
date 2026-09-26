import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'analysis_page.dart'; // Tambahkan ini
import 'package:fl_chart/fl_chart.dart'; // Tambahkan ini ke pubspec.yaml juga


final Map<String, String> paramUnits = {
  "Engine Status": "",
  "Engine Runtime": "Hours",
  "Battery Voltage": "VDC",
  "Charger Alternator": "VDC",
  "Oil Pressure": "bar",   // ✅ ubah sesuai sheet
  "Oil Temperature": "°C",
  "Coolant Temp": "°C",
  "Engine Speed": "RPM",
  "Fuel Delivery Pump": "bar",
  "Fuel Level Daily Tank": "%",
  "Gen Freq": "Hz",
  "L1-N": "VAC",
  "L2-N": "VAC",
  "L3-N": "VAC",
  "L1-L2": "VAC",
  "L2-L3": "VAC",
  "L3-L1": "VAC",
  "Gen L1": "A",
  "Gen L2": "A",
  "Gen L3": "A",
  "Power L1": "kW",
  "Power L2": "kW",
  "Power L3": "kW",
  "Power Total": "kW",
  "Pf L1": "",
  "Pf L2": "",
  "Pf L3": "",
  "Pf Avg": "",
  "pf L1": "",   // ✅ tambahkan versi huruf kecil (bisa duplikat)
  "pf L2": "",
  "pf L3": "",
  "pf Avg": "",
  "Generator Percentage Power": "%",
  "Fuel Temperature": "°C",
  "Fuel Consumption": "L/Hours",
  "Voltage (R)": "VAC",
  "Current (R)" : "A",
  "Power (R)" : "kW",
  "Energy (R)": "kW",
  "Voltage (S)": "VAC",
  "Current (S)" : "A",
  "Power (S)" : "kW",
  "Energy (S)": "kW",
  "Voltage (T)": "VAC",
  "Current (T)" : "A",
  "Power (T)" : "kW",
  "Energy (T)": "kW",
  "LVR": "",
  "UPR": "",
  "FPK": "",
  "FPK FAILURE": "",
  "swt5State": "",
  "Power Total 3 Phase": "kW",
};

final Map<String, String> paramLabels = {
  "Location": "Location",
  "Engine Status": "Engine Status",
  "Engine Runtime": "Engine Runtime",
  "Battery Voltage": "Battery Voltage",
  "Charger Alternator": "Charger Alternator",
  "Oil Pressure": "Oil Pressure", // ✅ ubah sesuai sheet
  "Oil Temperature": "Oil Temperature",
  "Coolant Temp": "Coolant Temperature",
  "Engine Speed": "Engine Speed",
  "Fuel Level Daily Tank": "Fuel Level Daily Tank",
  "Gen Freq": "Generator Frequency",
  "L1-N": "Generator Voltage L1-N",
  "L2-N": "Generator Voltage L2-N",
  "L3-N": "Generator Voltage L3-N",
  "L1-L2": "Generator Voltage L1-L2",
  "L2-L3": "Generator Voltage L2-L3",
  "L3-L1": "Generator Voltage L3-L1",
  "Gen L1": "Generator Current L1",
  "Gen L2": "Generator Current L2",
  "Gen L3": "Generator Current L3",
  "Power L1": "Generator Power L1",
  "Power L2": "Generator Power L2",
  "Power L3": "Generator Power L3",
  "Power Total": "Generator Power Total",
  "Generator Percentage Power": "Percentage Power",
  "pf L1": "Power Factor L1",     // ✅ perbaiki huruf kecil
  "pf L2": "Power Factor L2",
  "pf L3": "Power Factor L3",
  "pf Avg": "Power Factor Average",
  "Fuel Delivery Pump": "Fuel Delivery Pump",
  "Fuel Temperature": "Fuel Temperature",
  "Fuel Consumption": "Fuel Consumption",
  "Voltage (R)": "Voltage R-N",
  "Current (R)" : "Current (R)",
  "Power (R)" : "Power (R)",
  "Energy (R)": "Energy (R)",
  "Voltage (S)": "Voltage S-N",
  "Current (S)" : "Current (S)",
  "Power (S)" : "Power (S)",
  "Energy (S)": "Energy (S)",
  "Voltage (T)": "Voltage T-N",
  "Current (T)" : "Current (T)",
  "Power (T)" : "Power (T)",
  "Energy (T)": "Energy (T)",
  "LVR": "LVR",
  "UPR": "UPR",
  "FPK": "FPK",
  "FPK FAILURE": "FPK FAILURE",
  "swt5State": "swt5State",
  "Power Total 3 Phase": "Power Total 3 Phase",
};

// ==================== DESIRED PARAMETER ORDER ====================
final Map<String, List<String>> desiredParameterOrder = {

  // ================= ENGINE PARAMETER =================
  "Engine Parameter": [
    "Engine Status",
    "Engine Runtime",
    "Battery Voltage",
    "Charger Alternator",
    "Oil Pressure",
    "Oil Temperature",
    "Coolant Temp",
    "Engine Speed",
    "Fuel Level Daily Tank",
    "Fuel Delivery Pump",
    "Fuel Temperature",
    "Fuel Consumption",
  ],

  // ================= ELECTRICAL PARAMETER =================
  "Generator Parameter": [
    "Gen Freq",
    "L1-N",
    "L2-N",
    "L3-N",
    "L1-L2",
    "L2-L3",
    "L3-L1",
    "Gen L1",
    "Gen L2",
    "Gen L3",
    "Power L1",
    "Power L2",
    "Power L3",
    "Power Total",
    "Generator Percentage Power",
    "pf L1",
    "pf L2",
    "pf L3",
    "pf Avg",
  ],

  // ================= MOTOR FAN PARAMETER =================
  "Motor Fan Radiator Parameter": [
    "Voltage R-N",
    "Voltage S-N",
    "Voltage T-N",

    "Current (R)",
    "Current (S)",
    "Current (T)",
    
    "Power (R)",
    "Power (S)",
    "Power (T)",
    "Power Total 3 Phase",

    "Energy (S)",
    "Energy (R)",
    "Energy (T)",
  ],

  // ================= FUEL PUMP CONTROL STATUS =================
  "Fuel Pump Control Status": [
    "LVR",
    "UPR",
    "FPK",
    "FPK FAILURE",
    "swt5State",
  ],
};

// ==================== PARAMETER THRESHOLDS (TETAP SESUAI DATA ASLI) ====================
final Map<String, Map<String, double>> paramThresholds = {
  "Battery Voltage": {"min": 23.0, "max": 30.0},
  "Charger Alternator": {"min": 24.0, "max": 29.0},
  "Oil Pressure": {"min": 3.0},
  "Fuel Delivery Pump": {"min": 5.0},
  "Coolant Temp": {"max": 90.0},
  "Engine Speed": {"min": 1470.0, "max": 1530.0},
  "Gen Freq": {"min": 49.0, "max": 51.0},
  "L1-L2": {"min": 360.0, "max": 400.0},
  "L2-L3": {"min": 360.0, "max": 400.0},
  "L3-L1": {"min": 360.0, "max": 400.0},
};

// ==================== MAIN APP ====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'I-Gms',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Background_Login.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// ==================== HOME PAGE ====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> sheetList = [];
  Map<String, bool> statusMap = {}; // Simpan status ON/OFF tiap pembangkit
  bool isLoading = true;

  final String baseUrl =
      "https://script.google.com/macros/s/AKfycbxWweS6KqpC9CkIcWz0peHfxfeawWVf-BqXo0QAUuXCvtNNuXlpt1PC1vOdmPDgIXNSAw/exec";

  @override
  void initState() {
    super.initState();
    _fetchSheets();
    _startAutoRefresh();
  }

  Timer? _autoRefreshTimer;
int refreshInterval = 30; // detik

void _startAutoRefresh() {
  _autoRefreshTimer?.cancel();
  _autoRefreshTimer = Timer.periodic(Duration(seconds: refreshInterval), (_) {
    _fetchSheets(); // refresh data sheet dan status engine
  });
}


@override
void dispose() {
  _autoRefreshTimer?.cancel();
  super.dispose();
}

  // Ambil daftar sheet dari Apps Script
  Future<void> _fetchSheets() async {
    setState(() => isLoading = true);
    try {
      final url = "$baseUrl?listSheets=true";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final List<String> filteredSheets = data
              .where((e) {
                final name = e.toString();
                return name.startsWith("P") ||
                    name.startsWith("M") ||
                    name.startsWith("K");
              })
              .map((e) => e.toString().split("_")[0])
              .toSet()
              .toList();

          setState(() => sheetList = filteredSheets);

          // Setelah daftar sheet didapat, ambil status masing-masing
          for (final name in filteredSheets) {
            _fetchEngineStatus(name);
          }
        }
      }
    } catch (e, st) {
      debugPrint("❌ Error koneksi: $e");
      debugPrint(st.toString());
    }
    setState(() => isLoading = false);
  }

  // Ambil baris terakhir yang berisi "ON" atau "OFF" di kolom Engine Status
  Future<void> _fetchEngineStatus(String sheetName) async {
    try {
      final url = "$baseUrl?sheet=$sheetName"; // ambil semua data sheet
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          // cari dari bawah ke atas baris terakhir yang valid
          for (int i = data.length - 1; i >= 0; i--) {
            final row = data[i];
            if (row is Map && row.containsKey("Engine Status")) {
              final val = row["Engine Status"].toString().trim().toUpperCase();
              if (val == "ON" || val == "OFF") {
                final isOn = val == "ON";
                setState(() => statusMap[sheetName] = isOn);
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Gagal ambil Engine Status $sheetName: $e");
    }

    // Jika tidak ada data valid
    setState(() => statusMap[sheetName] = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: const Text(
          "Dashboard Monitoring",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Background_Page.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : sheetList.isEmpty
                ? const Center(child: Text("Tidak ada data sheet ditemukan"))
                : ListView.builder(
                    itemCount: sheetList.length,
                    itemBuilder: (context, index) {
                      final name = sheetList[index];
                      final isOn = statusMap[name] ?? false;
                      final ledColor = isOn ? Colors.green : Colors.red;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "assets/genset.png",
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: ledColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black12, width: 1),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailPembangkitPage(sheetName: name),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// ==================== DETAIL PAGE ====================
class DetailPembangkitPage extends StatefulWidget {
  final String sheetName;
  const DetailPembangkitPage({super.key, required this.sheetName});

  @override
  State<DetailPembangkitPage> createState() => _DetailPembangkitPageState();
}

class _DetailPembangkitPageState extends State<DetailPembangkitPage> {
  Map<String, dynamic> data = {};
  Map<String, bool> enabledParams = {};
  bool isLoading = false;
  Timer? _autoRefreshTimer;
  int refreshInterval = 5;

  final String baseUrl =
      "https://script.google.com/macros/s/AKfycbxWweS6KqpC9CkIcWz0peHfxfeawWVf-BqXo0QAUuXCvtNNuXlpt1PC1vOdmPDgIXNSAw/exec";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchData();
    _startAutoRefresh();
  }

@override
void dispose() {
  // Double safety: pastikan timer benar-benar dihentikan
  if (_autoRefreshTimer != null && _autoRefreshTimer!.isActive) {
    _autoRefreshTimer!.cancel();
  }
  super.dispose();
}

  // Tambahkan ini di dalam class _DetailPembangkitPageState
void _openAnalysisPage() {
  // HENTIKAN TIMER SEBELUM NAVIGASI
  _autoRefreshTimer?.cancel();
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AnalysisPage(
        sheetName: widget.sheetName,
        baseUrl: baseUrl,
      ),
    ),
  ).then((_) {
    // LANJUTKAN TIMER SETELAH KEMBALI DARI ANALYSIS PAGE
    if (mounted) { // Cek apakah widget masih mounted
      _startAutoRefresh(); // Restart timer
    }
  });
}

  // ==================== LOAD & SAVE SETTINGS ====================
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final filtered =
        keys.where((k) => k.startsWith('param_${widget.sheetName}_')).toList();
    final Map<String, bool> temp = {};
    for (var k in filtered) {
      temp[k.replaceFirst('param_${widget.sheetName}_', '')] =
          prefs.getBool(k) ?? true;
    }

    setState(() {
      enabledParams = temp;
      refreshInterval = prefs.getInt('interval_${widget.sheetName}') ?? 5;
    });

    _startAutoRefresh();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('interval_${widget.sheetName}', refreshInterval);
    for (var entry in enabledParams.entries) {
      await prefs.setBool('param_${widget.sheetName}_${entry.key}', entry.value);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pengaturan disimpan!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ==================== AUTO REFRESH ====================
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(Duration(seconds: refreshInterval), (_) {
      _fetchData(updateOnlyValues: true);
    });
  }

  // ==================== FETCH DATA ====================
  Future<void> _fetchData({bool updateOnlyValues = false}) async {
    if (!updateOnlyValues) setState(() => isLoading = true);
    try {
      final url = "$baseUrl?sheet=${widget.sheetName}&latest=true";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final parsed = jsonDecode(response.body);
        Map<String, dynamic> newData = {};
        if (parsed is List && parsed.isNotEmpty) {
          newData = Map<String, dynamic>.from(parsed.last);
        } else if (parsed is Map) {
          newData = Map<String, dynamic>.from(parsed);
        }
        // ================= TOTAL POWER 3 PHASE =================
        // Data awal masih dalam Watt → konversi ke kW terlebih dahulu

        double parsePower(Map<String, dynamic> data, String key) {
        // Jika key tidak ada di sheet
        if (!data.containsKey(key)) return 0;

        final value = data[key];

        // Jika null
        if (value == null) return 0;

        // Bersihkan format angka
        final cleaned = value
            .toString()
            .replaceAll(",", "")
            .trim();

        return double.tryParse(cleaned) ?? 0;
      }

      // ================= TOTAL POWER 3 PHASE =================
      final powerR = parsePower(newData, "Power (R)") / 1000;
      final powerS = parsePower(newData, "Power (S)") / 1000;
      final powerT = parsePower(newData, "Power (T)") / 1000;

      // Tambahkan hanya jika minimal satu parameter tersedia
      if (
          newData.containsKey("Power (R)") ||
          newData.containsKey("Power (S)") ||
          newData.containsKey("Power (T)")
      ) {
        newData["Power Total 3 Phase"] =
            powerR + powerS + powerT;
      }

        setState(() {
          if (updateOnlyValues) {
            for (var key in newData.keys) {
              if (data.containsKey(key)) data[key] = newData[key];
            }
          } else {
            data = newData;
          }

          for (var key in newData.keys) {

            // ================= DEFAULT OFF =================
            final defaultOffParams = [

              "Power (R)",
              "Power (S)",
              "Power (T)",

              "Energy (R)",
              "Energy (S)",
              "Energy (T)",
            ];

            enabledParams.putIfAbsent(
              key,
              () => !defaultOffParams.contains(key),
            );
          }
        });
        if (newData.isNotEmpty) {
        HistoricalDataManager().addData(widget.sheetName, Map.from(newData));
      }
    }
    } catch (e, st) {
      debugPrint("Fetch error: $e");
      debugPrint(st.toString());
    }
    if (!updateOnlyValues) setState(() => isLoading = false);
  }

  // ==================== HALAMAN SETTING PARAMETER ====================
  void _openSettingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text("Pengaturan Parameter"),
            centerTitle: true,
            backgroundColor: Colors.blueAccent,
          ),
          body: StatefulBuilder(
            builder: (context, setStateDialog) {
              // 🔹 Urutkan sama seperti tampilan utama
              final orderedKeys = [
                if (enabledParams.keys.any((k) => k.toLowerCase() == 'timestamp'))
                  enabledParams.keys.firstWhere((k) => k.toLowerCase() == 'timestamp'),
                ...paramLabels.keys.where(enabledParams.keys.contains),
                ...enabledParams.keys.where(
                  (k) => !paramLabels.keys.contains(k) && k.toLowerCase() != 'timestamp',
                ),
              ];

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Auto-refresh (detik):",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text("$refreshInterval s"),
                      ],
                    ),
                    Slider(
                      value: refreshInterval.toDouble(),
                      min: 2,
                      max: 30,
                      divisions: 28,
                      label: "$refreshInterval s",
                      onChanged: (val) {
                        setStateDialog(() {
                          refreshInterval = val.round();
                          _startAutoRefresh();
                        });
                      },
                    ),
                    const Divider(height: 20),
                    const Text(
                      "Pilih Parameter yang Ditampilkan",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: orderedKeys.length,
                        itemBuilder: (context, index) {
                          String key = orderedKeys[index];
                          bool value = enabledParams[key] ?? true;
                          final label = key.toLowerCase() == 'timestamp' ? 'Time' : (paramLabels[key] ?? key);

                          return SwitchListTile(
                            title: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: value,
                            activeColor: Colors.green,
                            onChanged: (v) {
                              setStateDialog(() {
                                enabledParams[key] = v;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _saveSettings();
                        _startAutoRefresh();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Pengaturan"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: const Text(
          "Integrated Generator Monitoring System",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
          IconButton(
                    icon: const Icon(Icons.bar_chart), 
                    onPressed: _openAnalysisPage, // Tambahkan ini
                    tooltip: 'Analysis Page',
                    ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Background_Page.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: Colors.blueAccent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              widget.sheetName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const Divider(thickness: 1, color: Colors.grey),
                            _buildDataTable(),
                            const SizedBox(height: 20),
                            const Text(
                              "DIPO KERETA KELAS A MALANG",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "By ATMON",
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '"All Together Making Our Network"',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: SizedBox(
        height: 45,
        width: 45,
        child: FloatingActionButton(
          onPressed: _openSettingsPage,
          backgroundColor: Colors.grey,
          child: const Icon(Icons.settings, size: 22),
        ),
      ),
    );
  }

  // ==================== BUILD TABLE ====================
  Widget _buildDataTable() {
  if (data.isEmpty) {
    return const Center(
      child: Text("Tidak ada data."),
    );
  }

  List<Widget> sections = [];

  // ==================== LOCATION & TIMESTAMP ====================

  // LOCATION
  if (data.containsKey("Location") &&
      (enabledParams["Location"] ?? true)) {

    sections.add(
      _buildSingleRow(
        paramLabels["Location"] ?? "Location",
        data["Location"].toString(),
        "",
        Colors.black,
      ),
    );
  }

  // TIMESTAMP
  String? timestampKey = data.keys.firstWhere(
    (k) => k.toLowerCase() == 'timestamp',
    orElse: () => '',
  );

  if (timestampKey.isNotEmpty &&
      (enabledParams[timestampKey] ?? true)) {

    sections.add(
      _buildSingleRow(
        "Time",
        _formatTimestamp(data[timestampKey].toString()),
        "",
        Colors.black,
      ),
    );
  }

  sections.add(const SizedBox(height: 8));

  // ==================== PARAMETER SECTIONS ====================

  desiredParameterOrder.forEach((sectionTitle, keys) {

    final availableKeys = keys
        .where((k) => data.containsKey(k))
        .where((k) => enabledParams[k] ?? true)
        .toList();

    // Skip jika kosong
    if (availableKeys.isEmpty) return;

    // ===== SECTION TITLE =====
    sections.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Divider(
            thickness: 1.5,
            color: Colors.grey,
          ),

          const SizedBox(height: 6),

          Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );

    // ===== PARAMETER LIST =====
    for (final key in availableKeys) {

      final value = data[key];

      // Tetap menggunakan paramLabels asli
      final label = paramLabels[key] ?? key;

      final unit = paramUnits[key] ?? "";

      String displayValue;

      final numVal = num.tryParse(value.toString());

      // ================= POWER R/S/T CONVERT TO kW =================
      if (
          key == "Power (R)" ||
          key == "Power (S)" ||
          key == "Power (T)"
      ) {

        if (numVal != null) {
          displayValue = (numVal / 1000).toStringAsFixed(2);
        } else {
          displayValue = value.toString();
        }

      } else {

        displayValue = numVal != null
            ? numVal.toStringAsFixed(1)
            : value.toString();
      }

      sections.add(
        _buildSingleRow(
          label,
          displayValue,
          unit,
          _getValueColor(key, value),
        ),
      );
    }
  });

  return Column(
    children: sections,
  );
}

Widget _buildSingleRow(
  String label,
  String value,
  String unit,
  Color valueColor,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [

        // LABEL
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),

        // VALUE
        Expanded(
          flex: 2,
          child: Text(
            ":  $value",
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // UNIT
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              unit,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // ==================== Format Timestamp ke WIB ====================
  String _formatTimestamp(String raw) {
    try {
      if (raw.contains('T') && raw.endsWith('Z')) {
        final dt = DateTime.parse(raw);
        final dtWib = dt.add(const Duration(hours: 7));
        final outputFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
        return "${outputFormat.format(dtWib)} WIB";
      }

      final inputFormat = DateFormat("MM/dd/yyyy HH:mm:ss");
      final dt = inputFormat.parse(raw);
      final outputFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
      return "${outputFormat.format(dt)} WIB";
    } catch (_) {
      return raw;
    }
  }

Color _getValueColor(String key, dynamic value) {
  // 🔹 Ambil status engine dari data
  final engineStatus = (data["Engine Status"]?.toString().toLowerCase() ?? "off");

  // Jika engine OFF, semua tetap hitam
  if (engineStatus != "on") {
    return Colors.black;
  }

  // Coba ubah nilai ke numerik
  final numVal = num.tryParse(value.toString());
  if (numVal == null) return Colors.black;

  // Cek apakah parameter punya threshold
  final threshold = paramThresholds[key];
  if (threshold == null) return Colors.black;

  final min = threshold["min"];
  final max = threshold["max"];

  // 🔹 Jika keluar dari batas, tampilkan merah
  if ((min != null && numVal < min) || (max != null && numVal > max)) {
    return Colors.red;
  }

  return Colors.black;
}

}