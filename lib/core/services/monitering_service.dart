import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class MonitoringService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static String? _previousDisease;
  static String? _previousWaterSuitability;
  static String? _previousEnvironmentalCondition;

  static Future<void> initializeNotifications() async {
    if (_isInitialized) return;

    const androidChannel = AndroidNotificationChannel(
      'bovitrack_alerts', // id
      'BoviTrack Alerts', // title
      description: 'Important alerts from BoviTrack', // description
      importance: Importance.high,
    );

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
    
    _isInitialized = true;
  }

  static Future<void> showNotification(String title, String message) async {
    if (!_isInitialized) await initializeNotifications();

    const androidDetails = AndroidNotificationDetails(
      'bovitrack_alerts',
      'BoviTrack Alerts',
      channelDescription: 'Important alerts from BoviTrack',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().microsecond,
        title,
        message,
        details,
        payload: 'default',
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> _saveReport({
    required String category,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      final report = {
        'category': category,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      await _database.child('reports').push().set(report);
    } catch (e) {
      print('Error saving report: $e');
    }
  }

  static void startMonitoring(BuildContext context) {
    final databaseRef = FirebaseDatabase.instance.ref();

    // Monitor health data (function3)
    databaseRef.child('function3').onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          if (data['health'] != null) {
            final healthData = data['health'] as Map<dynamic, dynamic>;
            if (healthData.isNotEmpty) {
              final latestKey = healthData.keys
                  .map((k) => k.toString())
                  .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
              final currentDisease = healthData[latestKey]['disease']?.toString();

              // Only show notification if disease is detected, different from previous one, and not healthy
              if (currentDisease != null && 
                  currentDisease != "None" && 
                  currentDisease != "Healthy" &&  // Added check for Healthy
                  currentDisease != _previousDisease) {
                
                // Collect vital signs data
                Map<String, dynamic> healthMetrics = {
                  'Disease': currentDisease,
                };

                // Get temperature if available
                if (data['temperature'] != null) {
                  if (data['temperature'] is Map) {
                    final tempData = data['temperature'] as Map<dynamic, dynamic>;
                    final latestTempKey = tempData.keys
                        .map((k) => k.toString())
                        .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                    healthMetrics['Temperature'] = tempData[latestTempKey];
                  } else {
                    healthMetrics['Temperature'] = data['temperature'];
                  }
                }

                // Get and save latest heart rate
                if (data['heart_rate'] != null) {
                  if (data['heart_rate'] is Map) {
                    final hrData = data['heart_rate'] as Map<dynamic, dynamic>;
                    if (hrData.isNotEmpty) {
                      final latestHrKey = hrData.keys
                          .map((k) => k.toString())
                          .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                      final latestHrValue = hrData[latestHrKey];
                      healthMetrics['Heart Rate'] = latestHrValue;
                      
                      // Save only if disease is not healthy
                      await databaseRef.child('function3/heart_rate').set(latestHrValue);
                    }
                  } else {
                    healthMetrics['Heart Rate'] = data['heart_rate'];
                    await databaseRef.child('function3/heart_rate').set(data['heart_rate']);
                  }
                }

                // Get and save latest blood oxygen
                if (data['blood_oxygen'] != null) {
                  if (data['blood_oxygen'] is Map) {
                    final boData = data['blood_oxygen'] as Map<dynamic, dynamic>;
                    if (boData.isNotEmpty) {
                      final latestBoKey = boData.keys
                          .map((k) => k.toString())
                          .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                      final latestBoValue = boData[latestBoKey];
                      healthMetrics['Blood Oxygen'] = latestBoValue;
                      
                      // Save only the latest blood oxygen value
                      await databaseRef.child('function3/blood_oxygen').set(latestBoValue);
                    }
                  } else {
                    healthMetrics['Blood Oxygen'] = data['blood_oxygen'];
                    await databaseRef.child('function3/blood_oxygen').set(data['blood_oxygen']);
                  }
                }

                await showNotification('⚠ Health Alert', 'Disease detected: $currentDisease');
                await _saveReport(
                  category: 'Health',
                  message: 'Disease Alert\nPotential disease detected',
                  data: healthMetrics,
                );
                
                // Update previous disease state
                _previousDisease = currentDisease;
              }
            }
          }
        } catch (e) {
          print('Error monitoring health data: $e');
        }
      }
    });

    // Monitor environmental data (function4)
    databaseRef.child('function4').onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          if (data['water']?['alert'] != null) {
            final alertData = data['water']['alert'] as Map<dynamic, dynamic>;
            final latestKey = alertData.keys
                .map((k) => k.toString())
                .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
            final currentSuitability = alertData[latestKey]['water_suitability']?.toString();
            
            // Only show notification if suitability changes and is not suitable
            if (currentSuitability != null && 
                currentSuitability.toLowerCase() != 'suitable' && 
                currentSuitability != _previousWaterSuitability) {
              // Collect additional water quality data
              Map<String, dynamic> waterQualityData = {
                'Water Suitability': currentSuitability,
              };

              // Get pH data if available
              if (data['water']['pH'] != null) {
                final pHData = data['water']['pH'] as Map<dynamic, dynamic>;
                final latestPHKey = pHData.keys
                    .map((k) => k.toString())
                    .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                waterQualityData['pH'] = pHData[latestPHKey];
              }

              // Get TDS data if available
              if (data['water']['tds'] != null) {
                final tdsData = data['water']['tds'] as Map<dynamic, dynamic>;
                final latestTDSKey = tdsData.keys
                    .map((k) => k.toString())
                    .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                waterQualityData['TDS'] = tdsData[latestTDSKey];
              }

              // Get temperature data if available
              if (data['water']['temperature'] != null) {
                final tempData = data['water']['temperature'] as Map<dynamic, dynamic>;
                final latestTempKey = tempData.keys
                    .map((k) => k.toString())
                    .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                waterQualityData['Temperature'] = tempData[latestTempKey];
              }

              // Get turbidity data if available
              if (data['water']['turbidity'] != null) {
                final turbidityData = data['water']['turbidity'] as Map<dynamic, dynamic>;
                final latestTurbidityKey = turbidityData.keys
                    .map((k) => k.toString())
                    .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                waterQualityData['Turbidity'] = turbidityData[latestTurbidityKey];
              }

              await showNotification('🚰⚠ Water Alert', 'Water quality is not suitable');
              await _saveReport(
                category: 'Water',
                message: 'Water Suitability Alert',
                data: waterQualityData,
              );
              // Update previous water suitability state
              _previousWaterSuitability = currentSuitability;
            }
          }

          if (data['Environmental']?['alert'] != null) {
            final environmentData = data['Environmental']['alert'] as Map<dynamic, dynamic>;
            if (environmentData.isNotEmpty) {
              final latestKey = environmentData.keys
                  .map((k) => k.toString())
                  .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
              final currentCondition = environmentData[latestKey]['condition']?.toString();
              
              // Only show notification if environmental condition changes and is not healthy/good
              if (currentCondition != null && 
                  !['healthy', 'good'].contains(currentCondition.toLowerCase()) && 
                  currentCondition != _previousEnvironmentalCondition) {

                // Collect environmental data
                Map<String, dynamic> environmentalData = {
                  'Condition': currentCondition,
                };

                // Get temperature data if available
                if (data['Environmental']['temperature'] != null) {
                  final tempData = data['Environmental']['temperature'] as Map<dynamic, dynamic>;
                  final latestTempKey = tempData.keys
                      .map((k) => k.toString())
                      .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                  environmentalData['Temperature'] = tempData[latestTempKey];
                }

                // Get humidity data if available
                if (data['Environmental']['humidity'] != null) {
                  final humidityData = data['Environmental']['humidity'] as Map<dynamic, dynamic>;
                  final latestHumidityKey = humidityData.keys
                      .map((k) => k.toString())
                      .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
                  environmentalData['Humidity'] = humidityData[latestHumidityKey];
                }

                await showNotification('🍃⚠ Environmental Alert', 'Environmental condition is not healthy');
                await _saveReport(
                  category: 'Environmental',
                  message: 'Environmental Condition Alert',
                  data: environmentalData,
                );
                // Update previous environmental condition state
                _previousEnvironmentalCondition = currentCondition;
              }
            }
          }
        } catch (e) {
          print('Error monitoring environmental data: $e');
        }
      }
    });

    // Monitor behavior data (function1)
    databaseRef.child('function1').onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          if (data['heat'] != null) {
            final heatData = data['heat'] as Map<dynamic, dynamic>;
            if (heatData.isNotEmpty) {
              final latestKey = heatData.keys
                  .map((k) => k.toString())
                  .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
              final isHeatDetected = heatData[latestKey]['isDetected'] ?? false;
              if (isHeatDetected) {
                await showNotification('⚠ Behavior Alert', 'Heat detected in animal');
                await _saveReport(
                  category: 'Health',
                  message: 'Heat Detection Alert',
                  data: {'Heat Detected': true},
                );
              }
            }
          }
        } catch (e) {
          print('Error monitoring behavior data: $e');
        }
      }
    });
  }
}