// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 0, 255, 115),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        unselectedLabelStyle: const TextStyle(
          height: 1.5,
        ),
        items: [
          _buildNavigationBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_outlined,
            label: 'Behavior',
          ),
          _buildNavigationBarItem(
            icon: Icons.chat_outlined,
            activeIcon: Icons.chat_outlined,
            label: 'Communication',
          ),
          _buildNavigationBarItem(
            icon: Icons.health_and_safety_outlined,
            activeIcon: Icons.health_and_safety_outlined,
            label: 'Health',
          ),
          _buildNavigationBarItem(
            icon: Icons.eco_outlined,
            activeIcon: Icons.eco_outlined,
            label: 'Environmental',
          ),
          _buildNavigationBarItem(
            icon: Icons.developer_board_outlined,
            activeIcon: Icons.developer_board_outlined,
            label: 'Prediction',
          ),
          _buildNavigationBarItem(
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment_outlined,
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        size: 24,
      ),
      activeIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          activeIcon,
          size: 24,
          color: Colors.white,
        ),
      ),
      label: label,
    );
  }
}