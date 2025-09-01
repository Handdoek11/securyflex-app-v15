import 'package:flutter/material.dart';

/// Tab data model for Company dashboard navigation
/// Following BeveiligerTabData pattern with Company-specific icons and structure
class CompanyTabData {
  CompanyTabData({
    this.imagePath = '',
    this.selectedImagePath = '',
    this.icon = Icons.home,
    this.selectedIcon = Icons.home,
    this.index = 0,
    this.isSelected = false,
    this.animationController,
  });

  String imagePath;
  String selectedImagePath;
  IconData icon;
  IconData selectedIcon;
  bool isSelected;
  int index;

  AnimationController? animationController;

  /// Company-specific tab configuration - Optimized 4-tab structure
  /// Dashboard, Jobs (integrated with Applications), Chat, Settings
  static List<CompanyTabData> tabIconsList = <CompanyTabData>[
    CompanyTabData(
      imagePath: 'assets/company/dashboard.png',
      selectedImagePath: 'assets/company/dashboard_s.png',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      index: 0,
      isSelected: true,
      animationController: null,
    ),
    CompanyTabData(
      imagePath: 'assets/company/jobs.png',
      selectedImagePath: 'assets/company/jobs_s.png',
      icon: Icons.work_outline,
      selectedIcon: Icons.work,
      index: 1,
      isSelected: false,
      animationController: null,
    ),
    CompanyTabData(
      imagePath: 'assets/company/chat.png',
      selectedImagePath: 'assets/company/chat_s.png',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      index: 2,
      isSelected: false,
      animationController: null,
    ),
    CompanyTabData(
      imagePath: 'assets/company/settings.png',
      selectedImagePath: 'assets/company/settings_s.png',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      index: 3,
      isSelected: false,
      animationController: null,
    ),
  ];
}
