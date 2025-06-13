import 'dart:async';
import 'package:bovitrack/screens/environment/widgets/ml_prediction.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

/// Environmental monitoring screen that displays water quality and environmental conditions
class EnvironmentalScreen extends StatefulWidget {
  @override
  _EnvironmentalScreenState createState() => _EnvironmentalScreenState();
}

/// State class for the EnvironmentalScreen widget
class _EnvironmentalScreenState extends State<EnvironmentalScreen>
    with SingleTickerProviderStateMixin {
  // Firebase database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // State variables
  bool isLoading = true;
  Map<String, dynamic>? waterData;           // Stores water quality metrics
  Map<String, dynamic>? environmentalLatestData;  // Stores environmental conditions
  StreamSubscription<DatabaseEvent>? _subscription;
  late TabController _tabController;

  // Theme colors
  final Color primaryColor = const Color.fromARGB(255, 0, 214, 193);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color cardColor = Colors.white;
  final Color textDarkColor = const Color(0xFF1E293B);
  final Color textLightColor = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();  // Initialize data on widget creation
  }

  @override
  void dispose() {
    _subscription?.cancel();  // Clean up database subscription
    _tabController.dispose(); // Clean up tab controller
    super.dispose();
  }

  /// Fetches real-time data from Firebase
  Future<void> _fetchData() async {
    try {
      setState(() => isLoading = true);
      await _subscription?.cancel();

      _subscription = _database.child('function4').onValue.listen(
        (DatabaseEvent event) {
          if (!mounted) return;

          if (event.snapshot.value != null) {
            try {
              Map<dynamic, dynamic> rawData =
                  event.snapshot.value as Map<dynamic, dynamic>;

              setState(() {
                // Initialize water data
                waterData = {};

                if (rawData.containsKey('water')) {
                  Map<dynamic, dynamic> waterNode =
                      rawData['water'] as Map<dynamic, dynamic>;

                  // Handle water suitability from alert subcollection
                  if (waterNode.containsKey('alert')) {
                    Map<dynamic, dynamic> alertData =
                        waterNode['alert'] as Map<dynamic, dynamic>;
                    final alertTimestamps = alertData.keys.where(
                        (key) => key is String && int.tryParse(key) != null);
                    if (alertTimestamps.isNotEmpty) {
                      final latestAlertTimestamp = alertTimestamps.reduce(
                          (a, b) => int.parse(a) > int.parse(b) ? a : b);
                      try {
                        waterData!['Water Suitability'] =
                            alertData[latestAlertTimestamp]
                                ['water_suitability'];
                        print(
                            'Latest Water Suitability: ${waterData!['Water Suitability']}');
                      } catch (e) {
                        print('Error parsing water suitability: $e');
                      }
                    }
                  }

                  // Handle pH from direct pH subcollection
                  if (waterNode.containsKey('pH')) {
                    Map<dynamic, dynamic> pHData =
                        waterNode['pH'] as Map<dynamic, dynamic>;
                    final latestPHTimestamp = pHData.keys
                        .where(
                            (key) => key is String && int.tryParse(key) != null)
                        .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                    try {
                      waterData!['pH'] =
                          double.parse(pHData[latestPHTimestamp].toString());
                      print('Latest pH: ${waterData!['pH']}');
                    } catch (e) {
                      print('Error parsing pH: $e');
                    }
                  }

                  // Handle TDS from direct tds subcollection
                  if (waterNode.containsKey('tds')) {
                    Map<dynamic, dynamic> tdsData =
                        waterNode['tds'] as Map<dynamic, dynamic>;
                    final latestTDSTimestamp = tdsData.keys
                        .where(
                            (key) => key is String && int.tryParse(key) != null)
                        .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                    try {
                      waterData!['TDS'] =
                          double.parse(tdsData[latestTDSTimestamp].toString());
                      print('Latest TDS: ${waterData!['TDS']}');
                    } catch (e) {
                      print('Error parsing TDS: $e');
                    }
                  }

                  // Handle temperature from direct temperature subcollection
                  if (waterNode.containsKey('temperature')) {
                    Map<dynamic, dynamic> tempData =
                        waterNode['temperature'] as Map<dynamic, dynamic>;
                    final latestTempTimestamp = tempData.keys
                        .where(
                            (key) => key is String && int.tryParse(key) != null)
                        .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                    try {
                      waterData!['Temperature'] = double.parse(
                          tempData[latestTempTimestamp].toString());
                      print('Latest Temperature: ${waterData!['Temperature']}');
                    } catch (e) {
                      print('Error parsing temperature: $e');
                    }
                  }

                  // Handle turbidity from direct turbidity subcollection
                  if (waterNode.containsKey('turbidity')) {
                    Map<dynamic, dynamic> turbidityData =
                        waterNode['turbidity'] as Map<dynamic, dynamic>;
                    final latestTurbidityTimestamp = turbidityData.keys
                        .where(
                            (key) => key is String && int.tryParse(key) != null)
                        .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                    try {
                      waterData!['Turbidity'] = double.parse(
                          turbidityData[latestTurbidityTimestamp].toString());
                      print('Latest Turbidity: ${waterData!['Turbidity']}');
                    } catch (e) {
                      print('Error parsing turbidity: $e');
                    }
                  }

                  // Debug print for water data
                  print('Complete Water Data: $waterData');
                }

                // Handle Environmental data
                environmentalLatestData = {};
                if (rawData.containsKey('Environmental')) {
                  Map<dynamic, dynamic> envData =
                      rawData['Environmental'] as Map<dynamic, dynamic>;

                  // Handle condition from alert subcollection
                  if (envData.containsKey('alert')) {
                    Map<dynamic, dynamic> alertsData =
                        envData['alert'] as Map<dynamic, dynamic>;
                    final latestAlertTimestamp = alertsData.keys
                        .where(
                            (key) => key is String && int.tryParse(key) != null)
                        .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                    environmentalLatestData!['Condition'] =
                        alertsData[latestAlertTimestamp]['condition'];
                  }
                }

                if (rawData.containsKey('Environmental')) {
                  Map<dynamic, dynamic> envMetrics =
                      rawData['Environmental'] as Map<dynamic, dynamic>;

                  if (envMetrics.containsKey('humidity')) {
                    Map<dynamic, dynamic> humidityData =
                        envMetrics['humidity'] as Map<dynamic, dynamic>;
                    final latestHumidityTimestamp = humidityData.keys
                        .where(
                            (key) => key is String && int.tryParse(key) != null)
                        .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                    environmentalLatestData!['Humidity'] =
                        humidityData[latestHumidityTimestamp];
                  }

                  if (envMetrics.containsKey('temperature')) {
                    Map<dynamic, dynamic> tempData =
                        envMetrics['temperature'] as Map<dynamic, dynamic>;
                    final latestTempTimestamp = tempData.keys
                        .where(
                            (key) => key is String && int.tryParse(key) != null)
                        .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                    environmentalLatestData!['Temperature'] =
                        tempData[latestTempTimestamp];
                  }
                }

                isLoading = false;
              });
            } catch (e) {
              print('Error parsing data: $e');
              _showErrorDialog('Error parsing data: $e');
              setState(() => isLoading = false);
            }
          } else {
            setState(() {
              waterData = null;
              environmentalLatestData = null;
              isLoading = false;
            });
          }
        },
        onError: (error) {
          print('Database error: $error');
          _showErrorDialog('Database error: $error');
          setState(() => isLoading = false);
        },
      );
    } catch (e) {
      print('Setup error: $e');
      _showErrorDialog('Setup error: $e');
      setState(() => isLoading = false);
    }
  }

  /// Formats the display value with appropriate units based on the metric type
  String _getValueWithUnit(String key, dynamic value) {
    if (value == null) return 'N/A';

    switch (key.toLowerCase()) {
      case 'temperature':
        return '${value.toString()}°C';
      case 'humidity':
        return '${value.toString()}%';
      case 'ph':
        return value.toString();
      case 'tds':
        return '${value.toString()} ppm';
      case 'turbidity':
        return '${value.toString()} NTU';
      case 'water suitability':
      case 'condition':
        return value.toString();
      default:
        return value.toString();
    }
  }

  /// Determines the status color based on the metric value ranges
  Color _getStatusColor(String key, dynamic value) {
    if (value == null) return Colors.grey;

    switch (key.toLowerCase()) {
      case 'temperature':
        if (value is num) {
          if (value < 20 || value > 35) return Colors.red;
          if (value < 22 || value > 32) return Colors.orange;
          return Colors.green;
        }
        break;
      case 'humidity':
        if (value is num) {
          if (value < 30 || value > 80) return Colors.red;
          if (value < 40 || value > 70) return Colors.orange;
          return Colors.green;
        }
        break;
      case 'ph':
        if (value is num) {
          if (value < 6.5 || value > 8.5) return Colors.red;
          if (value < 7.0 || value > 8.0) return Colors.orange;
          return Colors.green;
        }
        break;
      case 'tds':
        if (value is num) {
          if (value > 1000) return Colors.red;
          if (value > 500) return Colors.orange;
          return Colors.green;
        }
        break;
      case 'turbidity':
        if (value is num) {
          if (value > 5) return Colors.red;
          if (value > 1) return Colors.orange;
          return Colors.green;
        }
        break;
      case 'water suitability':
        return value.toString().toLowerCase() == 'suitable'
            ? Colors.green
            : Colors.red;
      case 'condition':
        return value.toString().toLowerCase() == 'healthy'
            ? Colors.green
            : Colors.orange;
    }
    return primaryColor;
  }

  /// Returns appropriate icon for each metric type
  IconData _getIconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'ph':
        return Icons.science;
      case 'tds':
        return Icons.opacity;
      case 'turbidity':
        return Icons.water;
      case 'water suitability':
        return Icons.check_circle;
      case 'condition':
        return Icons.eco;
      default:
        return Icons.data_usage;
    }
  }

  /// Builds a card widget to display individual metric status
  Widget _buildStatusCard(String title, dynamic value, String category) {
    String displayValue = _getValueWithUnit(title, value);
    Color statusColor = _getStatusColor(title, value);
    IconData iconData = _getIconForKey(title);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: statusColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textDarkColor,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          category,
          style: TextStyle(
            color: textLightColor,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          displayValue,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ),
    );
  }

  /// Creates a view to display either water quality or environmental data
  Widget _buildDataView(Map<String, dynamic>? data, String title) {
    if (data == null || data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title == "Water Quality" ? Icons.water_drop : Icons.eco,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No $title data available',
              style: TextStyle(color: textLightColor, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> cards = [];
    data.forEach((key, value) {
      cards.add(_buildStatusCard(key, value, title));
    });

    return Column(children: cards);
  }

  /// Shows error dialog when data fetching or parsing fails
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  /// Builds the main UI with TabBarView containing water quality and environmental data
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Environmental Data'),
        backgroundColor: primaryColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: const Color.fromARGB(179, 54, 54, 54),
          tabs: const [
            Tab(icon: Icon(Icons.water_drop), text: 'Water Quality'),
            Tab(icon: Icon(Icons.eco), text: 'Environment'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildDataView(waterData, 'Water Quality'),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDataView(
                          environmentalLatestData, 'Environmental Conditions'),
                      MLPredictionWidget(
                        primaryColor: primaryColor,
                        cardColor: cardColor,
                        textDarkColor: textDarkColor,
                        textLightColor: textLightColor,
                        environmentalLatestData: environmentalLatestData, // Add this line
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
