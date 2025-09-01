import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';

/// ShiftManagementScreen - Company shift management interface
/// 
/// Allows companies to create, edit, and manage shifts.
/// Features role-based access, bulk operations, and analytics.
class ShiftManagementScreen extends StatelessWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.companyBackground, // ✅ Company achtergrond (consistent met AppBar)
      appBar: AppBar(
        title: const Text('Diensten Beheer'),
        backgroundColor: DesignTokens.companyPrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Shift Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Feature wordt binnenkort geïmplementeerd',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}