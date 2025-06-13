import 'package:bovitrack/screens/setting.dart';
import 'package:flutter/material.dart';
import 'package:bovitrack/screens/behavior/behavior_screen.dart';
import 'package:bovitrack/screens/communication/communication_screen.dart';
import 'package:bovitrack/screens/health/health_screen.dart';
import 'package:bovitrack/screens/environment/environmental_screen.dart';
import 'package:bovitrack/screens/prediction/prediction_screen.dart';
import 'package:bovitrack/screens/reports/reports_screen.dart';
import 'package:bovitrack/screens/livestock/livestock_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        // Beautiful gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 0, 255, 115),  // Darker green
              Color.fromARGB(255, 108, 233, 114),  // Mid green
              Color.fromARGB(255, 165, 255, 169),  // Lighter green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar with modern design
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'AgriTrack',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Greeting section
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              
              // Main content area - grid of cards that fills available space
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate item size based on available space
                        double itemHeight = (constraints.maxHeight - 60) / 4;
                        double itemWidth = (constraints.maxWidth - 16) / 2;
                        return GridView.custom(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: itemWidth / itemHeight,
                          ),
                          childrenDelegate: SliverChildListDelegate([
                            _buildNavigationCard(
                              context,
                              'Behavior',
                              'assets/images/behavior.png',
                              'Monitor behavior patterns',
                              const Color.fromARGB(255, 74, 165, 245),
                              () => Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => BehaviorScreen())),
                            ),
                            _buildNavigationCard(
                              context,
                              'Livestock',
                              'assets/images/livestock.png',
                              'Track livestock details',
                              const Color.fromARGB(255, 0, 255, 115),
                              () => Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => const LivestockScreen())),
                            ),
                            _buildNavigationCard(
                              context,
                              'Communication',
                              'assets/images/communication.png',
                              'Live Connection with animals',
                              const Color.fromARGB(255, 110, 208, 4),
                              () => Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => CommunicationScreen())),
                            ),
                            _buildNavigationCard(
                              context,
                              'Health',
                              'assets/images/health.png',
                              'Track health metrics',
                              const Color.fromARGB(255, 250, 60, 129),
                              () => Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => HealthScreen())),
                            ),
                            _buildNavigationCard(
                              context,
                              'Environmental',
                              'assets/images/environment.png',
                              'Track environmental metrics',
                              const Color.fromARGB(255, 0, 214, 193),
                              () => Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => EnvironmentalScreen())),
                            ),
                            _buildNavigationCard(
                              context,
                              'Prediction',
                              'assets/images/prediction.png',
                              'AI-based forecasting',
                              const Color.fromARGB(255, 140, 84, 252),
                              () => Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => PredictionScreen())),
                            ),
                            _buildNavigationCard(
                              context,
                              'Reports',
                              'assets/images/report.png',
                              'View analytics and reports',
                              const Color.fromARGB(255, 255, 150, 63),
                              () => Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => WeeklyReportScreen())),
                            ),
                            _buildNavigationCard(
                              context,
                              'Settings',
                              'assets/images/settings.png',
                              'Configure app preferences',
                              const Color(0xFF607D8B),
                              () => Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => SettingScreen())),
                            ),
                          ]),
                        );
                      }
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, 
    String title, 
    String logoPath,
    String subtitle,
    Color color,
    VoidCallback onPressed
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo with circular background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    logoPath,
                    width: 30,
                    height: 30,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}