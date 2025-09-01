import 'package:flutter/material.dart';

class BeveiligerTabData {
  BeveiligerTabData({
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

  static List<BeveiligerTabData> tabIconsList = <BeveiligerTabData>[
    BeveiligerTabData(
      imagePath: 'assets/beveiliger/dashboard.png',
      selectedImagePath: 'assets/beveiliger/dashboard_s.png',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      index: 0,
      isSelected: true,
      animationController: null,
    ),
    BeveiligerTabData(
      imagePath: 'assets/beveiliger/jobs.png',
      selectedImagePath: 'assets/beveiliger/jobs_s.png',
      icon: Icons.work_outline,
      selectedIcon: Icons.work,
      index: 1,
      isSelected: false,
      animationController: null,
    ),
    BeveiligerTabData(
      imagePath: 'assets/beveiliger/chat.png',
      selectedImagePath: 'assets/beveiliger/chat_s.png',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      index: 2,
      isSelected: false,
      animationController: null,
    ),
    BeveiligerTabData(
      imagePath: 'assets/beveiliger/calendar.png',
      selectedImagePath: 'assets/beveiliger/calendar_s.png',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      index: 3,
      isSelected: false,
      animationController: null,
    ),
    BeveiligerTabData(
      imagePath: 'assets/beveiliger/profile.png',
      selectedImagePath: 'assets/beveiliger/profile_s.png',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      index: 4,
      isSelected: false,
      animationController: null,
    ),
  ];
}
