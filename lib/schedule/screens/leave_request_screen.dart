import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';

/// LeaveRequestScreen - Leave request management
/// 
/// Allows guards to submit leave requests and companies to approve them.
/// Features Nederlandse arbeidsrecht compliance.
class LeaveRequestScreen extends StatelessWidget {
  const LeaveRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.guardBackground, // ✅ Guard achtergrond (consistent met AppBar)
      appBar: AppBar(
        title: const Text('Verlof Aanvragen'),
        backgroundColor: DesignTokens.guardPrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Verlof Aanvragen',
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