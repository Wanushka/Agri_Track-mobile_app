import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final Color primaryColor = const Color(0xFF607D8B);
  final Color secondaryColor = const Color.fromARGB(255, 1, 71, 33);

@override
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
      title: const Text('Settings'),
      backgroundColor: primaryColor,
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 80,
              color: primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon!',
              style: TextStyle(
                color: secondaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Settings features are under development',
              style: TextStyle(
                color: secondaryColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}