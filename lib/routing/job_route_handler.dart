// lib/routing/job_route_handler.dart

import 'package:flutter/material.dart';
import '../marketplace/job_details_screen.dart';
import '../marketplace/model/security_job_data.dart';
import '../marketplace/repository/static_job_repository.dart';

/// Handler for job-related route data loading
class JobRouteHandler {
  /// Load job data by ID and return the appropriate screen
  static Widget loadJobDetailsScreen(String jobId) {
    // In a real app, this would be async and load from repository
    // For now, we'll create a mock job or use the static repository
    
    return FutureBuilder<SecurityJobData?>(
      future: _loadJobData(jobId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Opdracht niet gevonden'),
            ),
            body: const Center(
              child: Text('Deze opdracht kon niet worden geladen'),
            ),
          );
        }
        
        return JobDetailsScreen(jobData: snapshot.data);
      },
    );
  }
  
  static Future<SecurityJobData?> _loadJobData(String jobId) async {
    try {
      // Try to load from static repository
      final repository = StaticJobRepository();
      final jobs = await repository.getJobs();
      return jobs.firstWhere(
        (job) => job.jobId == jobId,
        orElse: () => _createMockJob(jobId),
      );
    } catch (e) {
      // Return mock data if repository fails
      return _createMockJob(jobId);
    }
  }
  
  static SecurityJobData _createMockJob(String jobId) {
    return SecurityJobData(
      jobId: jobId,
      jobTitle: 'Beveiligingsopdracht',
      companyName: 'SecuryFlex',
      location: 'Amsterdam',
      hourlyRate: 22.50,
      distance: 5.0,
      companyRating: 4.5,
      applicantCount: 12,
      duration: 8,
      jobType: 'Objectbeveiliging',
      description: 'Tijdelijke beveiligingsopdracht voor evenement',
      companyLogo: 'assets/hotel/hotel_1.png',
      startDate: DateTime.now().add(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 8)),
      requiredCertificates: ['Beveiligingspas', 'BHV'],
    );
  }
}