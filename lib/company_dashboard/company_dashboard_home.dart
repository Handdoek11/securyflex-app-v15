import 'package:securyflex_app/company_dashboard/widgets/responsive_dashboard_wrapper.dart';
import 'package:securyflex_app/company_dashboard/screens/company_jobs_applications_tab_screen.dart';
import 'package:securyflex_app/company_dashboard/screens/company_profile_screen.dart';
import 'package:securyflex_app/company_dashboard/screens/team_management_screen.dart';
import 'package:securyflex_app/company_dashboard/screens/job_posting_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import '../chat/screens/conversations_screen.dart';
import '../core/responsive/responsive_provider.dart';
import '../core/responsive/responsive_extensions.dart';

/// Main container for Company dashboard following BeveiligerDashboardHome pattern
/// with Company theming and navigation structure
class CompanyDashboardHome extends StatefulWidget {
  const CompanyDashboardHome({super.key});

  @override
  State<CompanyDashboardHome> createState() => _CompanyDashboardHomeState();
}

class _CompanyDashboardHomeState extends State<CompanyDashboardHome>
    with TickerProviderStateMixin {
  AnimationController? animationController;

  // Quick actions state
  bool _isQuickActionMenuOpen = false;
  AnimationController? _fabAnimationController;
  Animation<double>? _fabAnimation;

  @override
  void initState() {
    // Initialize animation controller
    animationController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);

    // Initialize FAB animation controller
    _fabAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fabAnimationController!, curve: Curves.easeInOut));

    super.initState();
  }

  // Navigation is now handled by CompanyShellScreen with GoRouter 2.0

  @override
  void dispose() {
    animationController?.dispose();
    _fabAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SecuryFlexTheme.getColorScheme(UserRole.company).surface,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: SecuryFlexTheme.getColorScheme(UserRole.company).primary,
          child: FutureBuilder<bool>(
            future: getData(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              } else {
                // CompanyDashboardHome now only shows dashboard content
                return ResponsiveDashboardWrapper(animationController: animationController);
              }
            },
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // Navigation is handled by CompanyShellScreen - no bottom navigation here
      ),
    );
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    return true;
  }

  // Bottom navigation removed - handled by CompanyShellScreen

  // ============================================================================
  // MOBILE-FIRST QUICK ACTIONS
  // ============================================================================

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    // Refresh current tab data
    await Future.delayed(const Duration(milliseconds: 1000));

    // Dashboard data will be refreshed through ResponsiveDashboardWrapper

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard bijgewerkt'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Build floating action button with quick actions menu
  Widget _buildFloatingActionButton() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return AnimatedBuilder(
      animation: _fabAnimation!,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick action buttons (shown when menu is open)
            if (_isQuickActionMenuOpen) ...[
              _buildQuickActionItem(
                icon: Icons.emergency,
                label: 'Noodgeval',
                color: DesignTokens.colorError,
                onPressed: _handleEmergencyAction,
              ),
              const SizedBox(height: 12),
              _buildQuickActionItem(
                icon: Icons.add_business,
                label: 'Nieuwe Job',
                color: companyColors.primary,
                onPressed: _handleQuickJobPosting,
              ),
              const SizedBox(height: 12),
              _buildQuickActionItem(
                icon: Icons.phone,
                label: 'Bel Guard',
                color: DesignTokens.colorInfo,
                onPressed: _handleCallGuard,
              ),
              const SizedBox(height: 12),
              _buildQuickActionItem(
                icon: Icons.message,
                label: 'Bericht',
                color: DesignTokens.colorSuccess,
                onPressed: _handleQuickMessage,
              ),
              const SizedBox(height: 16),
            ],

            // Main FAB
            FloatingActionButton(
              onPressed: _toggleQuickActionMenu,
              backgroundColor: companyColors.primary,
              elevation: 6.0,
              focusElevation: 8.0,
              hoverElevation: 8.0,
              highlightElevation: 12.0,
              shape: const CircleBorder(),
              child: AnimatedRotation(
                turns: _isQuickActionMenuOpen ? 0.125 : 0.0, // 45 degree rotation
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isQuickActionMenuOpen ? Icons.close : Icons.add,
                  color: DesignTokens.colorWhite,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build individual quick action item
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Transform.scale(
      scale: _fabAnimation!.value,
      child: Opacity(
        opacity: _fabAnimation!.value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DesignTokens.colorBlack.withValues(alpha: 0.87),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: DesignTokens.colorWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Action button
            FloatingActionButton.small(
              onPressed: onPressed,
              backgroundColor: color,
              heroTag: label, // Unique hero tag for each button
              child: Icon(
                icon,
                color: DesignTokens.colorWhite,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle quick action menu
  void _toggleQuickActionMenu() {
    setState(() {
      _isQuickActionMenuOpen = !_isQuickActionMenuOpen;
    });

    if (_isQuickActionMenuOpen) {
      _fabAnimationController!.forward();
    } else {
      _fabAnimationController!.reverse();
    }
  }

  // ============================================================================
  // QUICK ACTION HANDLERS
  // ============================================================================

  /// Handle emergency action
  void _handleEmergencyAction() {
    _toggleQuickActionMenu();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: DesignTokens.colorError),
            const SizedBox(width: 8),
            const Text('Noodgeval'),
          ],
        ),
        content: const Text('Wilt u de noodprocedure activeren?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Noodprocedure geactiveerd - Alle guards zijn geïnformeerd'),
                  backgroundColor: DesignTokens.statusCancelled,
                ),
              );
            },
            child: const Text('Activeren'),
          ),
        ],
      ),
    );
  }

  /// Handle quick job posting
  void _handleQuickJobPosting() {
    _toggleQuickActionMenu();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _buildQuickJobBottomSheet(),
    );
  }

  /// Handle call guard action
  void _handleCallGuard() {
    _toggleQuickActionMenu();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecteer Guard om te bellen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(child: Text('JD')),
              title: const Text('Jan de Vries'),
              subtitle: const Text('Actief - Centrum Amsterdam'),
              trailing: IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bellen naar Jan de Vries...')),
                  );
                },
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('MB')),
              title: const Text('Maria Bakker'),
              subtitle: const Text('Actief - Schiphol'),
              trailing: IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bellen naar Maria Bakker...')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle quick message action
  void _handleQuickMessage() {
    _toggleQuickActionMenu();

    // Navigation to chat is now handled by GoRouter - no direct tab switching needed

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat geopend voor snelle berichten')),
    );
  }

  /// Build quick job posting bottom sheet
  Widget _buildQuickJobBottomSheet() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      height: context.screenHeight * 0.7,
      decoration: BoxDecoration(
        color: companyColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: companyColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.add_business,
                  color: companyColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Snelle Job Plaatsing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Quick job form
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Job title
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Job Titel',
                      hintText: 'Bijv. Avondbeveiliging Kantoor',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Locatie',
                      hintText: 'Bijv. Amsterdam Centrum',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date and time row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Datum',
                            hintText: 'dd-mm-yyyy',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Tijd',
                            hintText: '18:00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.access_time),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Hourly rate
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Uurtarief',
                      hintText: '€15,00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixText: '€ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Annuleren'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const JobPostingFormScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: companyColors.primary,
                            foregroundColor: DesignTokens.colorWhite,
                          ),
                          child: const Text('Volledige Form'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Quick post button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Snelle job geplaatst! Guards worden geïnformeerd.'),
                            backgroundColor: DesignTokens.statusConfirmed,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.colorSuccess,
                        foregroundColor: DesignTokens.colorWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Plaats Job Nu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
