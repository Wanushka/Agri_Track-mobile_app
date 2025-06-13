import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationProvider with ChangeNotifier {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // Handle notification tap
      },
    );
  }

  void showTemperatureAlert(String deviceId, double temperature) {
    _showOverlayNotification(
      title: 'Temperature Alert',
      message: 'Device $deviceId: ${temperature.toStringAsFixed(1)}°C',
      color: Colors.red,
      icon: Icons.thermostat,
    );

    _showLocalNotification(
      id: 1,
      title: 'Temperature Alert',
      body: 'Device $deviceId: ${temperature.toStringAsFixed(1)}°C',
      channelId: 'temperature_alerts',
      channelName: 'Temperature Alerts',
    );
  }

  void showHeartRateAlert(String deviceId, double heartRate) {
    _showOverlayNotification(
      title: 'Heart Rate Alert',
      message: 'Device $deviceId: ${heartRate.toStringAsFixed(0)} BPM',
      color: Colors.red,
      icon: Icons.favorite,
    );

    _showLocalNotification(
      id: 2,
      title: 'Heart Rate Alert',
      body: 'Device $deviceId: ${heartRate.toStringAsFixed(0)} BPM',
      channelId: 'heart_rate_alerts',
      channelName: 'Heart Rate Alerts',
    );
  }

  void showEnvironmentalAlert(String type, double value) {
    _showOverlayNotification(
      title: 'Environmental Alert',
      message: '$type: ${value.toStringAsFixed(1)}',
      color: Colors.orange,
      icon: Icons.eco,
    );

    _showLocalNotification(
      id: 3,
      title: 'Environmental Alert',
      body: '$type: ${value.toStringAsFixed(1)}',
      channelId: 'environmental_alerts',
      channelName: 'Environmental Alerts',
    );
  }

  void showWaterQualityAlert(String type, double value) {
    _showOverlayNotification(
      title: 'Water Quality Alert',
      message: '$type: ${value.toStringAsFixed(1)}',
      color: Colors.blue,
      icon: Icons.water_drop,
    );

    _showLocalNotification(
      id: 4,
      title: 'Water Quality Alert',
      body: '$type: ${value.toStringAsFixed(1)}',
      channelId: 'water_quality_alerts',
      channelName: 'Water Quality Alerts',
    );
  }

  void showBloodOxygenAlert(String deviceId, int bloodOxygen) {
    _showOverlayNotification(
      title: 'Blood Oxygen Alert',
      message: 'Device $deviceId: Blood Oxygen Level ${bloodOxygen}%',
      color: Colors.red,
      icon: Icons.bloodtype,
    );

    _showLocalNotification(
      id: 5,
      title: 'Blood Oxygen Alert',
      body: 'Device $deviceId: Blood Oxygen Level ${bloodOxygen}%',
      channelId: 'blood_oxygen_alerts',
      channelName: 'Blood Oxygen Alerts',
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _showOverlayNotification({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    OverlayState? overlayState = Overlay.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();