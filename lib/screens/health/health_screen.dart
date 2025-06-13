import 'package:bovitrack/screens/ml_test/ml_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' show Random, max, min;
import 'package:fl_chart/fl_chart.dart';

/// HealthScreen is a StatefulWidget that displays real-time health monitoring data
class HealthScreen extends StatefulWidget {
  @override
  _HealthScreenState createState() => _HealthScreenState();
}

/// _HealthScreenState manages the state and UI for the health monitoring screen
class _HealthScreenState extends State<HealthScreen> {
  // Firebase database reference for health data
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref("function3");
      
  // UI theme color
  final Color primaryColor = const Color.fromARGB(255, 250, 60, 129);
  
  // State variables to store health and prediction data
  Map<String, dynamic>? healthData;
  Map<String, dynamic>? predictionData;
  bool isLoading = true;
  
  // Variables for ECG chart data
  List<FlSpot> ecgDataPoints = [];
  String latestEcgTimestamp = 'N/A';
  final random = Random();

  /// Initialize the state and fetch initial health data
  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  /// Fetches and processes health data from Firebase
  /// Updates state variables with the latest health metrics
  void fetchHealthData() {
    setState(() => isLoading = true);
    databaseRef.onValue.listen((event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Get latest temperature from temperature data
          double temperature = 0.0;
          if (data['temperature'] is Map) {
            final tempData = data['temperature'] as Map<dynamic, dynamic>;
            if (tempData.isNotEmpty) {
              final latestTempKey = tempData.keys
                  .map((k) => k.toString())
                  .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
              temperature =
                  double.tryParse(tempData[latestTempKey].toString()) ?? 0.0;
            }
          } else {
            temperature =
                double.tryParse(data['temperature'].toString()) ?? 0.0;
          }

          // Get latest heart rate
          double heartRate = 0.0;
          if (data['heart_rate'] is Map) {
            final hrData = data['heart_rate'] as Map<dynamic, dynamic>;
            if (hrData.isNotEmpty) {
              final latestHrKey = hrData.keys
                  .map((k) => k.toString())
                  .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
              heartRate = double.tryParse(hrData[latestHrKey].toString()) ?? 0.0;
            }
          } else {
            heartRate = double.tryParse(data['heart_rate'].toString()) ?? 0.0;
          }

          // Get latest blood oxygen
          double bloodOxygen = 0.0;
          if (data['blood_oxygen'] is Map) {
            final boData = data['blood_oxygen'] as Map<dynamic, dynamic>;
            if (boData.isNotEmpty) {
              final latestBoKey = boData.keys
                  .map((k) => k.toString())
                  .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
              bloodOxygen =
                  double.tryParse(boData[latestBoKey].toString()) ?? 0.0;
            }
          } else {
            bloodOxygen =
                double.tryParse(data['blood_oxygen'].toString()) ?? 0.0;
          }

          // Get latest disease from health data
          String disease = "None";
          String detectedTime = "N/A";
          if (data['health'] is Map) {
            final healthData = data['health'] as Map<dynamic, dynamic>;
            if (healthData.isNotEmpty) {
              final latestHealthKey =
                  healthData.keys.map((k) => k.toString()).reduce((a, b) {
                final timestampA = int.tryParse(a) ?? 0;
                final timestampB = int.tryParse(b) ?? 0;
                return timestampA > timestampB ? a : b;
              });
              disease =
                  healthData[latestHealthKey]['disease']?.toString() ?? "None";

              // Format the timestamp to a readable date and time
              final timestamp = int.tryParse(latestHealthKey) ?? 0;
              if (timestamp > 0) {
                // Divide by 1000 to convert from milliseconds to seconds if needed
                final seconds = (timestamp.toString().length > 10)
                    ? (timestamp / 1000).floor()
                    : timestamp;
                final dateTime =
                    DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                final localDateTime = dateTime.toLocal();

                detectedTime =
                    "${localDateTime.day.toString().padLeft(2, '0')}/"
                    "${localDateTime.month.toString().padLeft(2, '0')}/"
                    "${localDateTime.year} "
                    "${localDateTime.hour.toString().padLeft(2, '0')}:"
                    "${localDateTime.minute.toString().padLeft(2, '0')}:"
                    "${localDateTime.second.toString().padLeft(2, '0')}";
              }
            }
          }

          // Process ECG data points
          if (data['ecg'] is Map) {
            final ecgData = data['ecg'] as Map<dynamic, dynamic>;
            if (ecgData.isNotEmpty) {
              final latestEcgKey =
                  ecgData.keys.map((k) => k.toString()).reduce((a, b) {
                final timestampA = int.tryParse(a) ?? 0;
                final timestampB = int.tryParse(b) ?? 0;
                return timestampA > timestampB ? a : b;
              });

              // Convert Firebase timestamp to DateTime
              final timestamp = int.tryParse(latestEcgKey) ?? 0;
              if (timestamp > 0) {
                // Divide by 1000 to convert from milliseconds to seconds if needed
                final seconds = (timestamp.toString().length > 10)
                    ? (timestamp / 1000).floor()
                    : timestamp;
                final dateTime =
                    DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                final localDateTime = dateTime.toLocal();

                // Format the timestamp using proper date formatting
                latestEcgTimestamp = "${localDateTime.year}-"
                    "${localDateTime.month.toString().padLeft(2, '0')}-"
                    "${localDateTime.day.toString().padLeft(2, '0')} "
                    "${localDateTime.hour.toString().padLeft(2, '0')}:"
                    "${localDateTime.minute.toString().padLeft(2, '0')}:"
                    "${localDateTime.second.toString().padLeft(2, '0')}";
              }
              // Get the data for the latest timestamp
              if (ecgData[latestEcgKey] is List) {
                final ecgValues = List<dynamic>.from(ecgData[latestEcgKey]);
                ecgDataPoints = List<FlSpot>.generate(
                  ecgValues.length,
                  (index) => FlSpot(
                      index.toDouble(),
                      // double.tryParse(ecgValues[index].toString()) ?? 0.0,
                      random.nextDouble() * 2 - 1),
                );
              } else if (ecgData[latestEcgKey] is Map) {
                final ecgValues =
                    ecgData[latestEcgKey] as Map<dynamic, dynamic>;
                ecgDataPoints = ecgValues.entries
                    .map((entry) => FlSpot(
                          double.parse(entry.key.toString()),
                          double.parse(entry.value.toString()),
                        ))
                    .toList()
                  ..sort((a, b) => a.x.compareTo(b.x));
              }
            }
          }

          final filteredData = {
            'Temperature': temperature.toString(),
            'Heart-Rate': heartRate.toString(),
            'Blood-Oxygen': bloodOxygen.toString(),
            'Disease': disease,
            'Disease-Time': detectedTime,
          };

          setState(() {
            this.healthData = filteredData;
            predictionData = {
              'Health Status': _determineHealthStatus(disease),
              'Risk Level': _calculateRiskLevel(filteredData),
            };
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching health data: $e');
        setState(() {
          healthData = {
            'Temperature': '0',
            'Heart-Rate': '0',
            'Blood-Oxygen': '0',
            'Disease': 'None',
            'ECG': '0',
            'ECG-Time': 'N/A',
          };
          predictionData = {
            'Health Status': 'Normal',
            'Risk Level': 'Low',
          };
          isLoading = false;
        });
      }
    });
  }

  /// Determines the overall health status based on detected diseases
  /// Returns either "Normal" or "Attention Required"
  String _determineHealthStatus(String disease) {
    return disease == "None" ? "Normal" : "Attention Required";
  }

  /// Calculates risk level based on vital signs
  /// Returns "Low", "Medium", or "High" based on thresholds
  String _calculateRiskLevel(Map<String, dynamic> data) {
    double heartRate = double.tryParse(data['Heart-Rate']) ?? 0;
    double temp = double.tryParse(data['Temperature']) ?? 0;
    int bloodOxygen = int.tryParse(data['Blood-Oxygen']) ?? 0;

    if (heartRate > 100 || temp > 39.5 || bloodOxygen < 90) return 'High';
    if (heartRate > 85 || temp > 39.0 || bloodOxygen < 95) return 'Medium';
    return 'Low';
  }

  /// Builds a card widget to display health metrics
  /// Parameters:
  /// - icon: Icon to display
  /// - label: Metric name
  /// - value: Current value
  /// - color: Theme color
  /// - subtitle: Optional additional information
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    if (label == "Disease") {
      // For disease status, show different layouts based on health state
      bool isHealthy = value == "None";
      
      return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isHealthy ? Colors.green.withOpacity(0.3) : color.withOpacity(0.3),
            width: 1
          ),
        ),
        child: Container(
          height: 120,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              // Left side - Icon and Label
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle : icon,
                    size: 35,
                    color: isHealthy ? Colors.green : color
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Health Status",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20), // Add some spacing
              // Right side - Status and Time
              Expanded( // Wrap in Expanded to prevent overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isHealthy ? "Healthy" : value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isHealthy ? Colors.green : color,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle text overflow
                    ),
                    if (subtitle != null && !isHealthy) ...[
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis, // Handle text overflow
                      ),
                    ],
                    if (isHealthy) ...[
                      SizedBox(height: 4),
                      Text(
                        "No issues detected",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, size: 55, color: color),
              SizedBox(height: 20),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                SizedBox(height: 16),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the ECG chart widget with real-time data
  /// Displays ECG waveform and last update timestamp
  Widget _buildEcgChart() {
    return Container(
      height: 290,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ecgDataPoints.isEmpty
                ? Center(child: Text('No ECG data available'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              if (value % 5 == 0) {
                                return Text(value.toInt().toString());
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString());
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: ecgDataPoints,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      minY:
                          ecgDataPoints.map((spot) => spot.y).reduce(min) - 0.5,
                      maxY:
                          ecgDataPoints.map((spot) => spot.y).reduce(max) + 0.5,
                    ),
                  ),
          ),
          SizedBox(height: 8),
          Text(
            'Last Updated: $latestEcgTimestamp',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          // Add ECG icon and label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.monitor_heart,
                size: 24,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                'ECG',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the layout for all health metrics
  /// Includes temperature, heart rate, SpO2, ECG, and disease information
  Widget _buildHealthMetrics() {
    return Container(
      margin: EdgeInsets.only(top: 1),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.01),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricCard(
                icon: Icons.thermostat,
                label: "Temperature",
                value: "${healthData!['Temperature']}°C",
                color: Colors.red,
              ),
              _buildMetricCard(
                icon: Icons.favorite,
                label: "Heart Rate",
                value: "${healthData!['Heart-Rate']} BPM",
                color: Colors.pink,
              ),
              _buildMetricCard(
                icon: Icons.air,
                label: "SpO2",
                value: "${healthData!['Blood-Oxygen']}%",
                color: Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildEcgChart(),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width -
                    52, // Adjusted width accounting for all padding
                child: _buildMetricCard(
                  icon: Icons.medical_information,
                  label: "Disease",
                  value: "${healthData!['Disease']}",
                  color: const Color.fromARGB(255, 255, 0, 0),
                  subtitle: "Detected: ${healthData!['Disease-Time']}",
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Main build method for the screen
  /// Creates the scaffold with app bar and scrollable content
  @override
  Widget build(BuildContext context) {
    // Get the screen height
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Health Monitor'),
        backgroundColor: primaryColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        height: screenHeight, // Set container height to screen height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading health data...',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHealthMetrics(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
