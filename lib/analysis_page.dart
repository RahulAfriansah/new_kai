import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Import dari main file (copy definitions)
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
};

// Hanya parameter yang Anda inginkan
final List<String> analysisParameters = [
  'Oil Pressure',
  'L1-L2',
  'L2-L3', 
  'L3-L1',
  'Gen L1',
  'Gen L2',
  'Gen L3',
  'Engine Speed',
  'Coolant Temp',
  'Current (R)',
  'Current (S)',
  'Current (T)',
  'Fuel Consumption',
];

// Konfigurasi generator
const double MAX_POWER_KW = 400.0; // 500 kVA @ 70% = 350 kW, gunakan 400 untuk safety margin

// Threshold berdasarkan beban (%) - menggunakan Percentage Power sebagai referensi utama
// Threshold berdasarkan beban (%) - menggunakan Percentage Power sebagai referensi utama
// Threshold berdasarkan beban (%) - menggunakan Percentage Power sebagai referensi utama
final Map<String, Map<String, Map<String, double>>> loadBasedThresholds = {
  'Oil Pressure': {
    '0': {'min': 4.0, 'max': 10.5},     // 0% beban
    '10': {'min': 4.0, 'max': 10.5},    // 10% beban
    '20': {'min': 4.0, 'max': 10.5},    // 20% beban
    '30': {'min': 4.0, 'max': 10.5},    // 30% beban
    '40': {'min': 3.8, 'max': 10.5},    // 40% beban
    '50': {'min': 3.6, 'max': 10.5},    // 50% beban
    '60': {'min': 3.4, 'max': 10.5},    // 60% beban
    '70': {'min': 3.2, 'max': 10.5},    // 70% beban (normal max)
    '80': {'min': 3.0, 'max': 10.5},    // 80% beban (overload)
    '90': {'min': 3.0, 'max': 10.5},    // 90% beban (overload)
    '100': {'min': 3.0, 'max': 10.5},   // 100% beban (overload)
  },
  'L1-L2': {
    '0': {'min': 360.0, 'max': 400.0},   // 0% beban
    '10': {'min': 360.0, 'max': 400.0},  // 10% beban
    '20': {'min': 360.0, 'max': 400.0},  // 20% beban
    '30': {'min': 360.0, 'max': 400.0},  // 30% beban
    '40': {'min': 360.0, 'max': 400.0},  // 40% beban
    '50': {'min': 360.0, 'max': 400.0},  // 50% beban
    '60': {'min': 360.0, 'max': 400.0},  // 60% beban
    '70': {'min': 360.0, 'max': 400.0},  // 70% beban
    '80': {'min': 360.0, 'max': 400.0},  // 80% beban
    '90': {'min': 360.0, 'max': 400.0},  // 90% beban
    '100': {'min': 360.0, 'max': 400.0}, // 100% beban
  },
  'L2-L3': {
    '0': {'min': 360.0, 'max': 400.0},
    '10': {'min': 360.0, 'max': 400.0},
    '20': {'min': 360.0, 'max': 400.0},
    '30': {'min': 360.0, 'max': 400.0},
    '40': {'min': 360.0, 'max': 400.0},
    '50': {'min': 360.0, 'max': 400.0},
    '60': {'min': 360.0, 'max': 400.0},
    '70': {'min': 360.0, 'max': 400.0},
    '80': {'min': 360.0, 'max': 400.0},
    '90': {'min': 360.0, 'max': 400.0},
    '100': {'min': 360.0, 'max': 400.0},
  },
  'L3-L1': {
    '0': {'min': 360.0, 'max': 400.0},
    '10': {'min': 360.0, 'max': 400.0},
    '20': {'min': 360.0, 'max': 400.0},
    '30': {'min': 360.0, 'max': 400.0},
    '40': {'min': 360.0, 'max': 400.0},
    '50': {'min': 360.0, 'max': 400.0},
    '60': {'min': 360.0, 'max': 400.0},
    '70': {'min': 360.0, 'max': 400.0},
    '80': {'min': 360.0, 'max': 400.0},
    '90': {'min': 360.0, 'max': 400.0},
    '100': {'min': 360.0, 'max': 400.0},
  },
  'Gen L1': {
    '0': {'min': 0.0, 'max': 360.0},       // 0% beban
    '10': {'min': 0.0, 'max': 360.0},     // 10% beban = ~60A
    '20': {'min': 60.0, 'max': 360.0},    // 20% beban = ~120A
    '30': {'min': 60.0, 'max': 460.0},    // 30% beban = ~180A
    '40': {'min': 180.0, 'max': 460.0},    // 40% beban = ~240A
    '50': {'min': 180.0, 'max': 460.0},    // 50% beban = ~300A
    '60': {'min': 240.0, 'max': 560.0},    // 60% beban = ~360A
    '70': {'min': 240.0, 'max': 560.0},    // 70% beban = ~420A
    '80': {'min': 300.0, 'max': 560.0},    // 80% beban = ~480A
    '90': {'min': 300.0, 'max': 560.0},    // 90% beban = ~540A
    '100': {'min': 300.0, 'max': 600.0},   // 100% beban = ~600A
  },
  'Gen L2': {
    '0': {'min': 0.0, 'max': 360.0},       // 0% beban
    '10': {'min': 0.0, 'max': 360.0},     // 10% beban = ~60A
    '20': {'min': 60.0, 'max': 360.0},    // 20% beban = ~120A
    '30': {'min': 60.0, 'max': 460.0},    // 30% beban = ~180A
    '40': {'min': 180.0, 'max': 460.0},    // 40% beban = ~240A
    '50': {'min': 180.0, 'max': 460.0},    // 50% beban = ~300A
    '60': {'min': 240.0, 'max': 560.0},    // 60% beban = ~360A
    '70': {'min': 240.0, 'max': 560.0},    // 70% beban = ~420A
    '80': {'min': 300.0, 'max': 560.0},    // 80% beban = ~480A
    '90': {'min': 300.0, 'max': 560.0},    // 90% beban = ~540A
    '100': {'min': 300.0, 'max': 600.0},  
  },
  'Gen L3': {
    '0': {'min': 0.0, 'max': 360.0},       // 0% beban
    '10': {'min': 0.0, 'max': 360.0},     // 10% beban = ~60A
    '20': {'min': 60.0, 'max': 360.0},    // 20% beban = ~120A
    '30': {'min': 60.0, 'max': 460.0},    // 30% beban = ~180A
    '40': {'min': 180.0, 'max': 460.0},    // 40% beban = ~240A
    '50': {'min': 180.0, 'max': 460.0},    // 50% beban = ~300A
    '60': {'min': 240.0, 'max': 560.0},    // 60% beban = ~360A
    '70': {'min': 240.0, 'max': 560.0},    // 70% beban = ~420A
    '80': {'min': 300.0, 'max': 560.0},    // 80% beban = ~480A
    '90': {'min': 300.0, 'max': 560.0},    // 90% beban = ~540A
    '100': {'min': 300.0, 'max': 600.0},  
  },
  'Engine Speed': {
    '0': {'min': 1440.0, 'max': 1560.0}, // 0% beban
    '10': {'min': 1440.0, 'max': 1560.0}, // 10% beban
    '20': {'min': 1440.0, 'max': 1560.0}, // 20% beban
    '30': {'min': 1440.0, 'max': 1560.0}, // 30% beban
    '40': {'min': 1440.0, 'max': 1560.0}, // 40% beban
    '50': {'min': 1440.0, 'max': 1560.0}, // 50% beban
    '60': {'min': 1440.0, 'max': 1560.0}, // 60% beban
    '70': {'min': 1440.0, 'max': 1560.0}, // 70% beban
    '80': {'min': 1440.0, 'max': 1560.0}, // 80% beban
    '90': {'min': 1440.0, 'max': 1560.0}, // 90% beban
    '100': {'min': 1440.0, 'max': 1560.0}, // 100% beban
  },
  'Current (R)': {
  '0': {'min': 0.0, 'max': 40.0},
  '10': {'min': 0.0, 'max': 40.0},
  '20': {'min': 0.0, 'max': 40.0},
  '30': {'min': 0.0, 'max': 40.0},
  '40': {'min': 0.0, 'max': 40.0},
  '50': {'min': 0.0, 'max': 40.0},
  '60': {'min': 0.0, 'max': 40.0},
  '70': {'min': 0.0, 'max': 40.0},
  '80': {'min': 0.0, 'max': 40.0},
  '90': {'min': 0.0, 'max': 40.0},
  '100': {'min': 0.0, 'max': 40.0},
  },
  'Current (S)': {
  '0': {'min': 0.0, 'max': 40.0},
  '10': {'min': 0.0, 'max': 40.0},
  '20': {'min': 0.0, 'max': 40.0},
  '30': {'min': 0.0, 'max': 40.0},
  '40': {'min': 0.0, 'max': 40.0},
  '50': {'min': 0.0, 'max': 40.0},
  '60': {'min': 0.0, 'max': 40.0},
  '70': {'min': 0.0, 'max': 40.0},
  '80': {'min': 0.0, 'max': 40.0},
  '90': {'min': 0.0, 'max': 40.0},
  '100': {'min': 0.0, 'max': 40.0},
  },
  'Current (T)': {
  '0': {'min': 0.0, 'max': 40.0},
  '10': {'min': 0.0, 'max': 40.0},
  '20': {'min': 0.0, 'max': 40.0},
  '30': {'min': 0.0, 'max': 40.0},
  '40': {'min': 0.0, 'max': 40.0},
  '50': {'min': 0.0, 'max': 40.0},
  '60': {'min': 0.0, 'max': 40.0},
  '70': {'min': 0.0, 'max': 40.0},
  '80': {'min': 0.0, 'max': 40.0},
  '90': {'min': 0.0, 'max': 40.0},
  '100': {'min': 0.0, 'max': 40.0},
  },
  'Fuel Consumption': {
  '0': {'min': 0.0, 'max': 40.0},
  '10': {'min': 30.0, 'max': 80.0},
  '20': {'min': 30.0, 'max': 80.0},
  '30': {'min': 40.0, 'max': 90.0},
  '40': {'min': 40.0, 'max': 90.0},
  '50': {'min': 50.0, 'max': 100.0},
  '60': {'min': 50.0, 'max': 100.0},
  '70': {'min': 60.0, 'max': 110.0},
  '80': {'min': 60.0, 'max': 110.0},
  '90': {'min': 70.0, 'max': 120.0},
  '100': {'min': 70.0, 'max': 120.0},
  },
};

class AnalysisPage extends StatefulWidget {
  final String sheetName;
  final String baseUrl;

  const AnalysisPage({
    super.key,
    required this.sheetName,
    required this.baseUrl,
  });

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> historicalData = [];
  bool isLoading = true;
  late TabController _tabController;
  List<String> availableParameters = [];
  bool isSending = false;
  String sendStatus = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    final localData = HistoricalDataManager().getHistoricalData(widget.sheetName);
    
    if (localData.isNotEmpty) {
      _processData(localData);
    } else {
      if (mounted) {
        setState(() {
          historicalData = [];
          availableParameters = [];
          isLoading = false;
        });
      }
    }
  }

  void _processData(List<Map<String, dynamic>> data) {
    if (!mounted) return;
    
    final newAvailableParameters = _filterAnalysisParameters(data);
    newAvailableParameters.sort((a, b) => getParameterPriority(a).compareTo(getParameterPriority(b)));
    
    if (availableParameters.length != newAvailableParameters.length) {
      final oldController = _tabController;
      _tabController = TabController(length: newAvailableParameters.length, vsync: this);
      oldController.dispose();
    }
    
    setState(() {
      historicalData = data;
      availableParameters = newAvailableParameters;
      isLoading = false;
      _isInitialized = true;
    });
  }

  List<String> _filterAnalysisParameters(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];
    
    final allKeys = <String>{};
    for (final row in data) {
      allKeys.addAll(row.keys);
    }
    
    final filteredKeys = <String>[];
    for (final param in analysisParameters) {
      bool hasNumericData = false;
      for (final row in data) {
        if (row.containsKey(param)) {
          final value = row[param].toString();
          if (num.tryParse(value) != null) {
            hasNumericData = true;
            break;
          }
        }
      }
      
      if (hasNumericData && allKeys.contains(param)) {
        filteredKeys.add(param);
      }
    }
    
    return filteredKeys;
  }

  int getParameterPriority(String paramName) {
    final priorityOrder = [
      'Engine Speed', 'Oil Pressure', 'L1-L2', 'L2-L3', 'L3-L1',
      'Gen L1', 'Gen L2', 'Gen L3'
    ];
    
    final index = priorityOrder.indexOf(paramName);
    return index == -1 ? 999 : index;
  }

  Future<void> _sendAnalysisToSpreadsheet() async {
  if (historicalData.isEmpty || availableParameters.isEmpty || !mounted) return;

  setState(() {
    isSending = true;
    sendStatus = 'Processing analysis...';
  });

  try {
    final analysisResults = await _processAnalysis(historicalData);

    final analysisUrl = "https://script.google.com/macros/s/AKfycbxgCJB1xN-aN3xlG7CiLo1Pt46JiXirjJbnqHL8DsO9HJIhM_44VF_rqNJaUDyUMXuhMg/exec";
    

    // ================================
    // REQUEST (HANDLE REDIRECT)
    // ================================
    final request = http.Request('POST', Uri.parse(analysisUrl));

    request.headers.addAll({
      "Content-Type": "application/json",
    });

    request.body = jsonEncode({
      'deviceId': widget.sheetName,
      'analysisType': 'Analysis',
      'action': 'save',
      'data': analysisResults,
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // ================================
    // DEBUG (WAJIB SAAT TESTING)
    // ================================
    debugPrint("STATUS CODE: ${response.statusCode}");
    debugPrint("RESPONSE BODY: ${response.body}");

    // ================================
    // HANDLE REDIRECT (IMPORTANT FIX)
    // ================================
    if (response.statusCode == 302 || response.body.contains("Moved Temporarily")) {
      throw Exception("Redirect detected (302). Check deployment Web App.");
    }

    // ================================
    // VALIDASI RESPONSE
    // ================================
    final cleanBody = response.body.trim();

    if (response.statusCode == 200 && cleanBody.contains('SUCCESS')) {
      if (mounted) {
        setState(() {
          sendStatus = 'Analysis data sent successfully!';
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              sendStatus = '';
            });
          }
        });
      }
    } else {
      throw Exception("Failed to send analysis: $cleanBody");
    }
  } catch (e) {
    debugPrint("❌ Error sending analysis: $e");

    if (mounted) {
      setState(() {
        sendStatus = 'Error: ${e.toString()}';
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        isSending = false;
      });
    }
  }
}

  // Dapatkan load percentage dari data yang tersedia
  double _getCurrentLoadPercentage(List<Map<String, dynamic>> data) {
    final percentageValues = <double>[];
    final totalPowerValues = <double>[];
    
    for (final row in data) {
      // Coba ambil dari Percentage Power dulu (prioritas)
      if (row.containsKey('Generator Percentage Power')) {
        final value = num.tryParse(row['Generator Percentage Power'].toString());
        if (value != null) {
          percentageValues.add(value.toDouble());
        }
      }
      
      // Jika tidak ada, coba dari Power Total
      if (row.containsKey('Power Total')) {
        final value = num.tryParse(row['Power Total'].toString());
        if (value != null) {
          totalPowerValues.add(value.toDouble());
        }
      }
    }
    
    // Prioritas: Gunakan Percentage Power jika tersedia
    if (percentageValues.isNotEmpty) {
      final avgPercentage = percentageValues.reduce((a, b) => a + b) / percentageValues.length;
      return avgPercentage; // Sudah dalam persen
    }
    
    // Fallback: Gunakan Power Total konversi ke persen
    if (totalPowerValues.isNotEmpty) {
      final avgPower = totalPowerValues.reduce((a, b) => a + b) / totalPowerValues.length;
      return (avgPower / MAX_POWER_KW) * 100.0; // Konversi ke persen
    }
    
    return 0.0; // Default 0% load
  }

  // Dapatkan load level terdekat (kelipatan 10%)
  double _getNearestLoadLevel(double currentLoad) {
    return (currentLoad / 10).round() * 10.0; // Round to nearest 10%
  }

  // Dapatkan threshold berdasarkan load level
// Dapatkan threshold berdasarkan load level (menggunakan Percentage Power sebagai referensi utama)
// Dapatkan threshold berdasarkan load level (menggunakan Percentage Power sebagai referensi utama)
// Dapatkan threshold berdasarkan load level (menggunakan Percentage Power sebagai referensi utama)
Map<String, double> _getThresholdForLoad(String param, double loadLevel) {
  final paramThresholds = loadBasedThresholds[param];
  if (paramThresholds == null) return {}; // Return empty map jika parameter tidak ditemukan
  
  // Convert loadLevel ke string (kelipatan 10)
  final loadLevelInt = (loadLevel / 10).round() * 10; // Round ke 10 terdekat
  final loadLevelStr = loadLevelInt.toString();
  
  // Cari threshold untuk load level yang paling dekat
  if (paramThresholds.containsKey(loadLevelStr)) {
    final result = paramThresholds[loadLevelStr];
    if (result != null) {
      return result; // Ini seharusnya Map<String, double>
    }
  }
  
  // Jika tidak ditemukan, coba round down
  final roundedLoad = (loadLevel / 10).floor() * 10;
  final roundedLoadStr = roundedLoad.toString();
  
  if (paramThresholds.containsKey(roundedLoadStr)) {
    final result = paramThresholds[roundedLoadStr];
    if (result != null) {
      return result; // Ini seharusnya Map<String, double>
    }
  }
  
  // Jika masih tidak ditemukan, coba round to nearest
  final nearestLoad = (loadLevel / 10).round() * 10;
  final nearestLoadStr = nearestLoad.toString();
  
  if (paramThresholds.containsKey(nearestLoadStr)) {
    final result = paramThresholds[nearestLoadStr];
    if (result != null) {
      return result; // Ini seharusnya Map<String, double>
    }
  }
  
  // Fallback ke 0% jika semua gagal
  final result = paramThresholds['0'];
  if (result != null) {
    return result; // Ini seharusnya Map<String, double>
  }
  
  return {}; // Return empty map sebagai fallback
}

  // Status berdasarkan load
  String _getLoadBasedStatus(double value, String param, double currentLoad) {
    final loadLevel = _getNearestLoadLevel(currentLoad);
    final thresholds = _getThresholdForLoad(param, loadLevel);
    
    if (thresholds.isEmpty) return "Normal";
    
    final min = thresholds["min"];
    final max = thresholds["max"];
    
    if (min != null && max != null) {
      if (value < min) return "Critical - Below Minimum for $loadLevel% Load";
      if (value > max) return "Critical - Above Maximum for $loadLevel% Load";
      return "Normal - Within Range for $loadLevel% Load";
    }
    
    if (min != null && value < min) return "Critical - Below Minimum for $loadLevel% Load";
    if (max != null && value > max) return "Critical - Above Maximum for $loadLevel% Load";
    
    return "Normal - $loadLevel% Load";
  }

  Future<List<Map<String, dynamic>>> _processAnalysis(List<Map<String, dynamic>> data) async {
    final results = <Map<String, dynamic>>[];
    
    // Dapatkan current load dari Percentage Power atau Power Total
    final currentLoad = _getCurrentLoadPercentage(data);
    
    for (final param in availableParameters) {
      final values = <double>[];
      for (final row in data) {
        if (row.containsKey(param)) {
          final value = num.tryParse(row[param].toString());
          if (value != null) {
            values.add(value.toDouble());
          }
        }
      }
      
      if (values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        final stdDev = _calculateStdDev(values, avg);
        final trend = _analyzeTrend(values);
        final predicted = _predictNextValue(values);
        final predictionText = _predictGeneratorPerformanceBasedOnLoad(values, param, currentLoad);
        
        results.add({
          'timestamp': DateTime.now().toIso8601String(),
          'parameter': param,
          'average': avg,
          'min': min,
          'max': max,
          'stdDev': stdDev,
          'trend': trend,
          'predictedNext': predicted,
          'status': _getLoadBasedStatus(avg, param, currentLoad),
          'generatorPrediction': predictionText,
          'currentLoad': currentLoad,
          'loadLevel': _getNearestLoadLevel(currentLoad),
          'loadSource': _getReferenceLoadType(data),
          'totalDataPoints': values.length,
        });
      }
    }
    
    return results;
  }

  String _getReferenceLoadType(List<Map<String, dynamic>> data) {
    for (final row in data) {
      if (row.containsKey('Generator Percentage Power')) {
        return "Percentage";
      }
    }
    return "Power Total";
  }

  String _predictGeneratorPerformanceBasedOnLoad(List<double> values, String param, double currentLoad) {
    if (values.length < 3) return "Insufficient data for prediction";
    
    final current = values.last;
    final trend = _analyzeTrend(values);
    
    // Dapatkan threshold untuk load level saat ini
    final loadLevel = _getNearestLoadLevel(currentLoad);
    final thresholds = _getThresholdForLoad(param, loadLevel);
    
    if (param == 'Oil Pressure') {
      if (thresholds["min"] != null && current < thresholds["min"]!) {
        return "CRITICAL: Oil pressure ${current.toStringAsFixed(2)} below minimum ${thresholds["min"]!} for ${loadLevel}% load, immediate attention required";
      }
      if (thresholds["max"] != null && current > thresholds["max"]!) {
        return "CRITICAL: Oil pressure ${current.toStringAsFixed(2)} above maximum ${thresholds["max"]!} for ${loadLevel}% load, check system";
      }
      if (trend == 'Decreasing' && thresholds["min"] != null && current < thresholds["min"]! + 0.5) {
        return "MONITOR: Oil pressure ${current.toStringAsFixed(2)} trending down towards minimum for ${loadLevel}% load";
      }
      return "STABLE: Oil pressure ${current.toStringAsFixed(2)} normal for ${loadLevel}% load";
    }
    
    if (param == 'L1-L2' || param == 'L2-L3' || param == 'L3-L1') {
      if (thresholds["min"] != null && current < thresholds["min"]!) {
        return "CRITICAL: Voltage ${current.toStringAsFixed(2)}V below minimum for ${loadLevel}% load, check AVR/regulation";
      }
      if (thresholds["max"] != null && current > thresholds["max"]!) {
        return "CRITICAL: Voltage ${current.toStringAsFixed(2)}V above maximum for ${loadLevel}% load, check AVR/regulation";
      }
      if (trend == 'Decreasing' && thresholds["min"] != null && current < thresholds["min"]! + 5) {
        return "MONITOR: Voltage ${current.toStringAsFixed(2)}V trending down towards minimum for ${loadLevel}% load";
      }
      return "STABLE: Voltage ${current.toStringAsFixed(2)}V normal for ${loadLevel}% load";
    }
    
    if (param == 'Gen L1' || param == 'Gen L2' || param == 'Gen L3') {
      if (thresholds["max"] != null && current > thresholds["max"]!) {
        return "CRITICAL: Current ${current.toStringAsFixed(2)}A above maximum ${thresholds["max"]!}A for ${loadLevel}% load, overload condition";
      }
      if (trend == 'Increasing' && thresholds["max"] != null && current > thresholds["max"]! * 0.9) {
        return "MONITOR: Current ${current.toStringAsFixed(2)}A approaching maximum for ${loadLevel}% load";
      }
      return "STABLE: Current ${current.toStringAsFixed(2)}A normal for ${loadLevel}% load";
    }
    
    if (param == 'Engine Speed') {
      if (thresholds["min"] != null && current < thresholds["min"]!) {
        return "CRITICAL: Engine speed ${current.toStringAsFixed(0)} RPM below minimum for ${loadLevel}% load, check fuel/governor";
      }
      if (thresholds["max"] != null && current > thresholds["max"]!) {
        return "CRITICAL: Engine speed ${current.toStringAsFixed(0)} RPM above maximum for ${loadLevel}% load, check governor";
      }
      return "STABLE: Engine speed ${current.toStringAsFixed(0)} RPM normal for ${loadLevel}% load";
    }
    
    return "STABLE: ${trend} trend, operating normally at ${loadLevel}% load";
  }

  double _predictNextValue(List<double> values) {
    if (values.length < 3) return values.lastOrNull ?? 0;
    
    List<double> recent;
    if (values.length >= 3) {
      int startIndex = values.length - 3;
      recent = values.sublist(startIndex);
    } else {
      recent = values;
    }
    
    if (recent.length >= 3) {
      final diff1 = recent[2] - recent[1];
      final diff2 = recent[1] - recent[0];
      return recent[2] + (diff1 + diff2) / 2;
    }
    
    return values.last;
  }

  double _calculateStdDev(List<double> values, double mean) {
    if (values.length <= 1) return 0;
    final sum = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b);
    return sqrt(sum / (values.length - 1));
  }

  String _analyzeTrend(List<double> values) {
    if (values.length < 2) return "Insufficient data";
    
    final first = values.first;
    final last = values.last;
    
    if (last > first) return "Increasing";
    if (last < first) return "Decreasing";
    return "Stable";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: Text("${widget.sheetName} - Analysis"),
        actions: [
          if (historicalData.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.send,
                color: isSending ? Colors.grey : Colors.white,
              ),
              onPressed: isSending ? null : _sendAnalysisToSpreadsheet,
              tooltip: 'Send Analysis to Spreadsheet',
            ),
        ],
        bottom: availableParameters.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: availableParameters.map((param) {
                  final displayLabel = paramLabels[param] ?? param;
                  return Tab(text: displayLabel);
                }).toList(),
              )
            : null,
      ),
      body: Column(
        children: [
          if (sendStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: sendStatus.contains('Error') ? Colors.red : Colors.green,
              child: Text(
                sendStatus,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : availableParameters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              "No historical data available",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Collected ${historicalData.length} data points",
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : SafeArea(
                        child: TabBarView(
                          controller: _tabController,
                          children: availableParameters.map((param) {
                            return _buildParameterAnalysis(param);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterAnalysis(String paramName) {
    if (historicalData.isEmpty || !mounted) {
      return const Center(child: Text("No data"));
    }

    final chartData = <FlSpot>[];
    final timestamps = <DateTime>[];
    final currentLoad = _getCurrentLoadPercentage(historicalData);
    final loadLevel = _getNearestLoadLevel(currentLoad);
    final loadBasedThresholds = _getThresholdForLoad(paramName, loadLevel); // Ini sekarang benar

    final minThreshold = loadBasedThresholds["min"]; // Ini sekarang aman
    final maxThreshold = loadBasedThresholds["max"]; // Ini sekarang aman

for (int i = 0; i < historicalData.length; i++) {
  final row = historicalData[i];

  if (!row.containsKey(paramName)) continue;

  // 🔥 CLEAN VALUE (hapus unit seperti rpm, V, A, dll)
  final rawValue = row[paramName].toString();
  final cleanedValue = rawValue.replaceAll(RegExp(r'[^0-9\.\-]'), '');
  final value = num.tryParse(cleanedValue);

  if (value == null) continue;

  // ✅ Tambah ke chart
  chartData.add(FlSpot(chartData.length.toDouble(), value.toDouble()));

  // 🔥 TIMESTAMP HARUS IKUT JUMLAH chartData (bukan i)
  if (row.containsKey('Timestamp')) {
    try {
      final timestampStr = row['Timestamp'].toString();

      if (timestampStr.contains('T') && timestampStr.endsWith('Z')) {
        timestamps.add(DateTime.parse(timestampStr));
      } else {
        final inputFormat = DateFormat("MM/dd/yyyy HH:mm:ss");
        timestamps.add(inputFormat.parse(timestampStr));
      }
    } catch (e) {
      timestamps.add(DateTime.now());
    }
  } else {
    timestamps.add(DateTime.now());
  }
}

    if (chartData.isEmpty) {
      return const Center(child: Text("No numeric data for this parameter"));
    }

    // Dapatkan current load dan threshold
    //final currentLoad = _getCurrentLoadPercentage(historicalData);
    //final loadLevel = _getNearestLoadLevel(currentLoad);
    //final loadBasedThresholds = _getThresholdForLoad(paramName, loadLevel);

    //final minThreshold = loadBasedThresholds["min"];
    //final maxThreshold = loadBasedThresholds["max"];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paramLabels[paramName] ?? paramName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text("Data Points: ${chartData.length}", style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Text("Load: ${currentLoad.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Text("Ref: ${_getReferenceLoadType(historicalData)}", style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text("Status: ${_getLoadBasedStatus(chartData.lastOrNull?.y ?? 0, paramName, currentLoad)}", 
                   style: TextStyle(fontSize: 12, color: _getStatusColorBasedOnLoad(chartData.lastOrNull?.y ?? 0, paramName, currentLoad))),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: calculateGridInterval(chartData),
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: calculateTitleInterval(chartData.length),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < timestamps.length) {
                              final time = timestamps[index].add(const Duration(hours: 7)); // WIB
                              return Text(
                                '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                          leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: calculateGridInterval(chartData),
                          getTitlesWidget: (value, meta) {
                            final minY = calculateMinY(chartData, minThreshold);
                            final maxY = calculateMaxY(chartData, maxThreshold);

                            // tolerance biar aman (fl_chart kadang tidak exact)
                            const tolerance = 0.5;

                            // tampilkan MIN
                            if ((value - minY).abs() < tolerance) {
                              return Text(
                                minY.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 10),
                              );
                            }

                            // tampilkan MAX
                            if ((value - maxY).abs() < tolerance) {
                              return Text(
                                maxY.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 10),
                              );
                            }

                            // selain itu kosong
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    minX: 0,
                    maxX: chartData.length - 1 > 0 ? chartData.length - 1 : 1,
                    minY: calculateMinY(chartData, minThreshold),
                    maxY: calculateMaxY(chartData, maxThreshold),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData,
                        isCurved: false,
                        color: Colors.blue,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                      // Load-based threshold lines
                      if (minThreshold != null)
                        LineChartBarData(
                          spots: [FlSpot(0, minThreshold), FlSpot(chartData.length - 1, minThreshold)],
                          isCurved: false,
                          color: Colors.orange,
                          barWidth: 1,
                          dashArray: [5, 5],
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                        ),
                      if (maxThreshold != null)
                        LineChartBarData(
                          spots: [FlSpot(0, maxThreshold), FlSpot(chartData.length - 1, maxThreshold)],
                          isCurved: false,
                          color: Colors.red,
                          barWidth: 1,
                          dashArray: [5, 5],
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (minThreshold != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Min (${loadLevel}%): ${minThreshold.toStringAsFixed(2)}', 
                        style: const TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                  if (maxThreshold != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Max (${loadLevel}%): ${maxThreshold.toStringAsFixed(2)}', 
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  if (chartData.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Current: ${chartData.last.y.toStringAsFixed(2)}', 
                        style: const TextStyle(color: Colors.blue, fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getParameterStatus(String paramName, double currentValue) {
    final currentLoad = _getCurrentLoadPercentage(historicalData);
    return _getLoadBasedStatus(currentValue, paramName, currentLoad);
  }

  Color _getStatusColorBasedOnLoad(double currentValue, String paramName, double currentLoad) {
    final loadLevel = _getNearestLoadLevel(currentLoad);
    final thresholds = _getThresholdForLoad(paramName, loadLevel);
    
    final min = thresholds["min"];
    final max = thresholds["max"];

    if (min != null && currentValue < min) return Colors.red;
    if (max != null && currentValue > max) return Colors.red;
    return Colors.green;
  }

  double calculateGridInterval(List<FlSpot> data) {
    if (data.isEmpty) return 1;
    
    double maxValue = double.negativeInfinity;
    double minValue = double.infinity;
    
    for (final spot in data) {
      if (spot.y > maxValue) maxValue = spot.y;
      if (spot.y < minValue) minValue = spot.y;
    }
    
    if (maxValue == minValue || (maxValue == double.negativeInfinity || minValue == double.infinity)) {
      return 1.0;
    }
    
    final range = maxValue - minValue;
    final interval = range / 10;
    return interval == 0 ? 1.0 : interval;
  }

  double calculateTitleInterval(int dataLength) {
    if (dataLength <= 0) return 1;
    if (dataLength <= 10) return 1;
    if (dataLength <= 20) return 2;
    if (dataLength <= 50) return 5;
    return 10;
  }

  double calculateMinY(List<FlSpot> data, double? minThreshold) {
    if (data.isEmpty) return 0;
    final dataMin = data.fold<double>(double.infinity, (prev, spot) => spot.y < prev ? spot.y : prev);
    final thresholdMin = minThreshold ?? double.infinity;
    final min = dataMin < thresholdMin ? dataMin : thresholdMin;
    final range = calculateGridInterval(data);
    return min - (range * 0.5);
  }

  double calculateMaxY(List<FlSpot> data, double? maxThreshold) {
    if (data.isEmpty) return 1;
    final dataMax = data.fold<double>(0, (prev, spot) => spot.y > prev ? spot.y : prev);
    final thresholdMax = maxThreshold ?? 0;
    final max = dataMax > thresholdMax ? dataMax : thresholdMax;
    final range = calculateGridInterval(data);
    return max + (range * 0.5);
  }
}

// Manager untuk buffer data lokal
class HistoricalDataManager {
  static final HistoricalDataManager _instance = HistoricalDataManager._internal();
  factory HistoricalDataManager() => _instance;
  HistoricalDataManager._internal();

  Map<String, List<Map<String, dynamic>>> _buffers = {};

  void addData(String sheetName, Map<String, dynamic> data) {
    if (!_buffers.containsKey(sheetName)) {
      _buffers[sheetName] = [];
    }

    _buffers[sheetName]!.add(Map.from(data));

    if (_buffers[sheetName]!.length > 50) {
      _buffers[sheetName]!.removeAt(0);
    }
  }

  List<Map<String, dynamic>> getHistoricalData(String sheetName) {
    return _buffers[sheetName] ?? [];
  }

  void clearHistory(String sheetName) {
    _buffers.remove(sheetName);
  }
}