// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

// Import required packages and local modules
import 'package:bovitrack/core/services/monitering_service.dart';
import 'package:bovitrack/screens/home/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/providers/device_provider.dart';
import 'screens/home/home_screen.dart';
import 'core/providers/notification_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Main entry point of the application
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables
  await dotenv.load();
  // Initialize Firebase services
  await Firebase.initializeApp();
  
  // Initialize notification services
  final notificationProvider = NotificationProvider();
  await notificationProvider.initNotifications();
  // Initialize monitoring service notifications
  await MonitoringService.initializeNotifications();

  // Run the app with required providers
  runApp(
    MultiProvider(
      providers: [
        // Provider for device-related state management
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        // Provider for notification-related state management
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: MyApp(),
    ),
  );
}

// Global navigator key for accessing navigation state from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Root widget of the application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'BoviTrack',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreenWrapper(),
    );
  }
}

// Wrapper widget for the splash screen with navigation logic
class SplashScreenWrapper extends StatefulWidget {
  @override
  _SplashScreenWrapperState createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  // Method to handle navigation after splash screen duration
  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash screen duration
    if (mounted) {
      // Navigate to home screen and remove splash screen from stack
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreenWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen();
  }
}

// Wrapper widget for the home screen with monitoring initialization
class HomeScreenWrapper extends StatefulWidget {
  @override
  _HomeScreenWrapperState createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize monitoring service after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start monitoring service
      MonitoringService.startMonitoring(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}