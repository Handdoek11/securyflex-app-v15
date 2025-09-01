import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/company_dashboard/screens/application_review_screen.dart';
import 'package:securyflex_app/beveiliger_dashboard/screens/my_applications_screen.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';

/// Demo screen to showcase the new application management features
/// This screen allows testing both company and guard application management flows
class ApplicationManagementDemo extends StatelessWidget {
  const ApplicationManagementDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserType = AuthService.currentUserType;
    final colors = currentUserType == 'company' 
        ? SecuryFlexTheme.getColorScheme(UserRole.company)
        : SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Container(
      color: colors.surface,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: UnifiedHeader.simple(
            title: 'Sollicitatie Beheer Demo',
            userRole: currentUserType == 'company' ? UserRole.company : UserRole.guard,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase Backend Implementatie',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'De volgende Firebase-backed services zijn geïmplementeerd:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 24),
              
              _buildFeatureCard(
                context,
                'Firebase Authentication',
                'Echte gebruikersregistratie en -authenticatie met Firestore gebruikersprofielen',
                Icons.security,
                DesignTokens.statusAccepted,
              ),
              SizedBox(height: 16),
              
              _buildFeatureCard(
                context,
                'Job Posting Service',
                'Firebase-backed opdrachtbeheer met real-time updates en Firestore opslag',
                Icons.work,
                DesignTokens.statusConfirmed,
              ),
              SizedBox(height: 16),
              
              _buildFeatureCard(
                context,
                'Application Service',
                'Sollicitatiebeheer met Firebase backend en real-time statusupdates',
                Icons.assignment,
                DesignTokens.statusPending,
              ),
              SizedBox(height: 32),
              
              Text(
                'Test de nieuwe functionaliteit:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              SizedBox(height: 16),
              
              if (currentUserType == 'company') ...[
                UnifiedButton.primary(
                  text: 'Sollicitaties Bekijken (Bedrijf)',
                  onPressed: () => _showCompanyApplications(context),
                ),
                SizedBox(height: 12),
                Text(
                  'Als bedrijf kun je sollicitaties voor je opdrachten bekijken en beheren.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.colorGray600,
                  ),
                ),
              ] else ...[
                UnifiedButton.primary(
                  text: 'Mijn Sollicitaties (Beveiliger)',
                  onPressed: () => _showGuardApplications(context),
                ),
                SizedBox(height: 12),
                Text(
                  'Als beveiliger kun je de status van je sollicitaties volgen.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.colorGray600,
                  ),
                ),
              ],
              
              SizedBox(height: 24),
              UnifiedButton.secondary(
                text: 'Gebruikersregistratie Testen',
                onPressed: () => _showRegistrationInfo(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, IconData icon, Color color) {
    return UnifiedCard.standard(
      userRole: AuthService.currentUserType == 'company' ? UserRole.company : UserRole.guard,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.colorGray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompanyApplications(BuildContext context) {
    // Create a demo job for testing
    final demoJob = JobPostingData(
      jobId: 'demo-job-1',
      companyId: 'demo-company',
      title: 'Demo Beveiligingsopdracht',
      description: 'Dit is een demo opdracht voor het testen van de sollicitatiefunctionaliteit.',
      location: 'Amsterdam',
      postalCode: '1012AB',
      hourlyRate: 18.50,
      startDate: DateTime.now().add(Duration(days: 7)),
      endDate: DateTime.now().add(Duration(days: 14)),
      createdDate: DateTime.now().subtract(Duration(days: 3)),
      status: JobPostingStatus.active,
      requiredCertificates: ['Beveiligingsdiploma A'],
      requiredSkills: ['Toegangscontrole'],
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ApplicationReviewScreen(jobData: demoJob),
      ),
    );
  }

  void _showGuardApplications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyApplicationsScreen(),
      ),
    );
  }

  void _showRegistrationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Firebase Authenticatie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De app ondersteunt nu echte gebruikersregistratie met Firebase:'),
            SizedBox(height: 12),
            Text('• Nieuwe gebruikers kunnen accounts aanmaken'),
            Text('• Gebruikersgegevens worden opgeslagen in Firestore'),
            Text('• Rol-gebaseerde toegangscontrole (Guard/Company/Admin)'),
            Text('• Fallback naar demo-accounts voor ontwikkeling'),
            SizedBox(height: 12),
            Text('Ga naar het inlogscherm en klik op "Registreer hier" om te testen.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Begrepen'),
          ),
        ],
      ),
    );
  }
}
