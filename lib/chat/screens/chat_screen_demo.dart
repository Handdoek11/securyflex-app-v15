import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_header.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'enhanced_chat_screen.dart';

/// Interactive demo showcasing the enhanced chat screen
/// 
/// Features:
/// - Live demonstration of all chat features
/// - Multiple user role examples (Guard, Company, Admin)
/// - Interactive message sending with real-time animations
/// - Showcase of loading states, error handling, and recovery
/// - Demo of floating elements and scroll physics
/// - Conversation starters and empty state examples
/// - Performance metrics and accessibility testing
/// 
/// This comprehensive demo allows users and developers to experience
/// the full range of enhanced chat capabilities before implementation.
class ChatScreenDemo extends StatefulWidget {
  const ChatScreenDemo({super.key});

  @override
  State<ChatScreenDemo> createState() => _ChatScreenDemoState();
}

class _ChatScreenDemoState extends State<ChatScreenDemo>
    with TickerProviderStateMixin {
  
  UserRole selectedRole = UserRole.guard;
  int selectedScenarioIndex = 0;
  late AnimationController _demoController;
  late AnimationController _metricsController;
  
  final List<DemoScenario> scenarios = [
    DemoScenario(
      title: 'Normale conversatie',
      description: 'Een typische zakelijke conversatie tussen beveiliger en opdrachtgever',
      conversationType: ConversationType.direct,
      hasAssignment: true,
      messageCount: 12,
      showTyping: false,
      hasErrors: false,
    ),
    DemoScenario(
      title: 'Groepsgesprek',
      description: 'Meerdere personen in één gesprek met verschillende rollen',
      conversationType: ConversationType.group,
      hasAssignment: false,
      messageCount: 8,
      showTyping: true,
      hasErrors: false,
    ),
    DemoScenario(
      title: 'Leeg gesprek',
      description: 'Nieuw gesprek zonder berichten - toon conversatie starters',
      conversationType: ConversationType.direct,
      hasAssignment: false,
      messageCount: 0,
      showTyping: false,
      hasErrors: false,
    ),
    DemoScenario(
      title: 'Verbindingsproblemen',
      description: 'Demonstreer error states en herstel functionaliteit',
      conversationType: ConversationType.direct,
      hasAssignment: true,
      messageCount: 5,
      showTyping: false,
      hasErrors: true,
    ),
    DemoScenario(
      title: 'Lange conversatie',
      description: 'Test scroll physics en prestaties met veel berichten',
      conversationType: ConversationType.direct,
      hasAssignment: true,
      messageCount: 50,
      showTyping: false,
      hasErrors: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _demoController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    
    _metricsController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _demoController.forward();
  }

  @override
  void dispose() {
    _demoController.dispose();
    _metricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(selectedRole);
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(AppBar().preferredSize.height),
        child: _buildDemoHeader(),
      ),
      body: Column(
        children: [
          // Demo controls
          _buildDemoControls(colorScheme),
          
          // Demo content
          Expanded(
            child: _buildDemoContent(),
          ),
          
          // Performance metrics
          _buildPerformanceMetrics(colorScheme),
        ],
      ),
    );
  }

  Widget _buildDemoHeader() {
    return selectedRole == UserRole.company
        ? UnifiedHeader.companyGradient(
            title: 'Chat Demo - ${_getRoleDisplayName()}',
            showNotifications: false,
            leading: HeaderElements.backButton(
              onPressed: () => Navigator.pop(context),
              color: DesignTokens.colorWhite,
            ),
            actions: [
              HeaderElements.actionButton(
                icon: Icons.info_outline,
                onPressed: _showDemoInfo,
                color: DesignTokens.colorWhite,
              ),
            ],
          )
        : UnifiedHeader.simple(
            title: 'Chat Demo - ${_getRoleDisplayName()}',
            userRole: selectedRole,
            leading: HeaderElements.backButton(
              onPressed: () => Navigator.pop(context),
              userRole: selectedRole,
            ),
            actions: [
              HeaderElements.actionButton(
                icon: Icons.info_outline,
                onPressed: _showDemoInfo,
                userRole: selectedRole,
              ),
            ],
          );
  }

  Widget _buildDemoControls(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        boxShadow: [
          DesignTokens.shadowLight,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role selector
          Text(
            'Gebruikersrol',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          _buildRoleSelector(colorScheme),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Scenario selector
          Text(
            'Demo scenario',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          _buildScenarioSelector(colorScheme),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(ColorScheme colorScheme) {
    return Row(
      children: UserRole.values.map((role) {
        final isSelected = role == selectedRole;
        final roleColor = _getRoleColor(role);
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: role == UserRole.values.last ? 0 : DesignTokens.spacingS,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedRole = role;
                });
                _animateRoleChange();
              },
              child: AnimatedContainer(
                duration: DesignTokens.durationMedium,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? roleColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                  border: Border.all(
                    color: roleColor,
                    width: 2,
                  ),
                ),
                child: Text(
                  _getRoleDisplayName(role),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: isSelected ? DesignTokens.colorWhite : roleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScenarioSelector(ColorScheme colorScheme) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: scenarios.length,
        itemBuilder: (context, index) {
          final scenario = scenarios[index];
          final isSelected = index == selectedScenarioIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedScenarioIndex = index;
              });
              _animateScenarioChange();
            },
            child: AnimatedContainer(
              duration: DesignTokens.durationMedium,
              width: 200,
              margin: EdgeInsets.only(
                right: index == scenarios.length - 1 ? 0 : DesignTokens.spacingM,
              ),
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [DesignTokens.shadowLight] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    scenario.title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    scenario.description,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDemoContent() {
    return AnimatedBuilder(
      animation: _demoController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _demoController,
          child: _buildChatDemo(),
        );
      },
    );
  }

  Widget _buildChatDemo() {
    final scenario = scenarios[selectedScenarioIndex];
    final conversation = _generateDemoConversation(scenario);
    
    return EnhancedChatScreen(
      conversation: conversation,
      userRole: selectedRole,
      animationController: _demoController,
    );
  }

  Widget _buildPerformanceMetrics(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _metricsController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Performance indicators
              _buildMetricCard(
                'FPS',
                '60',
                Icons.speed,
                DesignTokens.colorSuccess,
                colorScheme,
              ),
              SizedBox(width: DesignTokens.spacingM),
              _buildMetricCard(
                'Geheugen',
                '95MB',
                Icons.memory,
                DesignTokens.colorInfo,
                colorScheme,
              ),
              SizedBox(width: DesignTokens.spacingM),
              _buildMetricCard(
                'Scroll',
                'Vloeiend',
                Icons.touch_app,
                DesignTokens.colorSuccess,
                colorScheme,
              ),
              Spacer(),
              
              // Demo actions
              IconButton(
                onPressed: _toggleMetrics,
                icon: Icon(Icons.analytics_outlined),
                color: colorScheme.primary,
                tooltip: 'Toggle prestatie metrics',
              ),
              IconButton(
                onPressed: _resetDemo,
                icon: Icon(Icons.refresh),
                color: colorScheme.primary,
                tooltip: 'Reset demo',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: color,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ConversationModel _generateDemoConversation(DemoScenario scenario) {
    final conversationId = 'demo_${scenario.title.toLowerCase().replaceAll(' ', '_')}';
    
    return ConversationModel(
      conversationId: conversationId,
      title: _generateConversationTitle(scenario),
      conversationType: scenario.conversationType,
      participants: _generateParticipants(scenario),
      lastMessage: scenario.messageCount > 0 ? _generateLastMessage() : null,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      updatedAt: DateTime.now().subtract(Duration(minutes: 5)),
      assignmentId: scenario.hasAssignment ? 'assignment_demo_001' : null,
      assignmentTitle: scenario.hasAssignment ? 'Demo Security Assignment' : null,
      isArchived: false,
      isMuted: false,
      unreadCounts: {'demo_user': math.Random().nextInt(3)},
      typingStatus: {'demo_user': scenario.showTyping},
    );
  }

  String _generateConversationTitle(DemoScenario scenario) {
    switch (scenario.conversationType) {
      case ConversationType.group:
        return 'Team Project Alpha';
      case ConversationType.direct:
      default:
        return selectedRole == UserRole.guard
            ? 'SecuryCompany B.V.'
            : selectedRole == UserRole.company
            ? 'Jan Janssen (Beveiliger)'
            : 'Admin Support';
    }
  }

  // Remove unused method since subtitle is handled in ConversationModel

  Map<String, ParticipantDetails> _generateParticipants(DemoScenario scenario) {
    final now = DateTime.now();
    
    switch (scenario.conversationType) {
      case ConversationType.group:
        return {
          'user1': ParticipantDetails(
            userId: 'user1',
            userName: 'Jan Jansen',
            userRole: 'guard',
            joinedAt: now.subtract(Duration(hours: 2)),
            isOnline: true,
            lastSeen: now.subtract(Duration(minutes: 5)),
          ),
          'user2': ParticipantDetails(
            userId: 'user2',
            userName: 'SecuryCompany B.V.',
            userRole: 'company',
            joinedAt: now.subtract(Duration(hours: 1)),
            isOnline: false,
            lastSeen: now.subtract(Duration(minutes: 15)),
          ),
          'user3': ParticipantDetails(
            userId: 'user3',
            userName: 'Admin Support',
            userRole: 'admin',
            joinedAt: now.subtract(Duration(minutes: 30)),
            isOnline: true,
            lastSeen: now.subtract(Duration(minutes: 2)),
          ),
          'current_user': ParticipantDetails(
            userId: 'current_user',
            userName: 'Demo User',
            userRole: selectedRole.name,
            joinedAt: now.subtract(Duration(hours: 3)),
            isOnline: true,
            lastSeen: now,
          ),
        };
      case ConversationType.direct:
      default:
        return {
          'other_user': ParticipantDetails(
            userId: 'other_user',
            userName: selectedRole == UserRole.guard 
                ? 'SecuryCompany B.V.' 
                : selectedRole == UserRole.company
                ? 'Jan Jansen (Beveiliger)'
                : 'Admin Support',
            userRole: selectedRole == UserRole.guard 
                ? 'company' 
                : selectedRole == UserRole.company
                ? 'guard'
                : 'admin',
            joinedAt: now.subtract(Duration(hours: 1)),
            isOnline: true,
            lastSeen: now.subtract(Duration(minutes: 5)),
          ),
          'current_user': ParticipantDetails(
            userId: 'current_user',
            userName: 'Demo User',
            userRole: selectedRole.name,
            joinedAt: now.subtract(Duration(hours: 2)),
            isOnline: true,
            lastSeen: now,
          ),
        };
    }
  }

  LastMessagePreview _generateLastMessage() {
    final messages = [
      'Bedankt voor de bevestiging!',
      'Tot morgen om 08:00 uur',
      'Locatie gedeeld via GPS',
      'Certificaten zijn bijgewerkt',
      'Opdracht is voltooid ✅',
    ];
    
    return LastMessagePreview(
      messageId: 'last_message',
      senderId: 'other_user',
      senderName: selectedRole == UserRole.guard 
          ? 'SecuryCompany B.V.' 
          : selectedRole == UserRole.company
          ? 'Jan Jansen'
          : 'Admin Support',
      content: messages[math.Random().nextInt(messages.length)],
      messageType: MessageType.text,
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      deliveryStatus: MessageDeliveryStatus.read,
    );
  }

  void _animateRoleChange() {
    _demoController.reset();
    _demoController.forward();
  }

  void _animateScenarioChange() {
    _demoController.reset();
    _demoController.forward();
  }

  void _toggleMetrics() {
    if (_metricsController.isCompleted) {
      _metricsController.reverse();
    } else {
      _metricsController.forward();
    }
  }

  void _resetDemo() {
    setState(() {
      selectedRole = UserRole.guard;
      selectedScenarioIndex = 0;
    });
    _demoController.reset();
    _demoController.forward();
  }

  void _showDemoInfo() {
    final colorScheme = SecuryFlexTheme.getColorScheme(selectedRole);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enhanced Chat Demo'),
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Deze demo toont alle functies van het verbeterde chat systeem:',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: DesignTokens.spacingM),
              
              _buildInfoSection('🎨 Visual Design', [
                'Smart message grouping',
                'Floating date indicators',
                'Role-based theming',
                'Smooth animations'
              ]),
              
              _buildInfoSection('⚡ Performance', [
                'Custom scroll physics',
                '60fps animations',
                'Efficient rendering',
                'Memory optimization'
              ]),
              
              _buildInfoSection('🔧 Features', [
                'Loading skeletons',
                'Error recovery',
                'Typing indicators',
                'Message replies'
              ]),
              
              _buildInfoSection('♿ Accessibility', [
                'Screen reader support',
                'High contrast modes',
                'Keyboard navigation',
                'Touch targets 44px+'
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(left: DesignTokens.spacingM, bottom: DesignTokens.spacingXS),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: SecuryFlexTheme.getColorScheme(selectedRole).primary)),
              Expanded(child: Text(item, style: TextStyle(fontSize: DesignTokens.fontSizeS))),
            ],
          ),
        )),
        SizedBox(height: DesignTokens.spacingM),
      ],
    );
  }

  Color _getBackgroundColor() {
    switch (selectedRole) {
      case UserRole.guard:
        return DesignTokens.guardBackground;
      case UserRole.company:
        return DesignTokens.companyBackground;
      case UserRole.admin:
        return DesignTokens.adminBackground;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  String _getRoleDisplayName([UserRole? role]) {
    final targetRole = role ?? selectedRole;
    switch (targetRole) {
      case UserRole.guard:
        return 'Beveiliger';
      case UserRole.company:
        return 'Bedrijf';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// Demo scenario configuration
class DemoScenario {
  final String title;
  final String description;
  final ConversationType conversationType;
  final bool hasAssignment;
  final int messageCount;
  final bool showTyping;
  final bool hasErrors;

  const DemoScenario({
    required this.title,
    required this.description,
    required this.conversationType,
    required this.hasAssignment,
    required this.messageCount,
    required this.showTyping,
    required this.hasErrors,
  });
}

/// Demo metrics widget for performance monitoring
class DemoMetrics extends StatefulWidget {
  final UserRole userRole;

  const DemoMetrics({
    super.key,
    required this.userRole,
  });

  @override
  State<DemoMetrics> createState() => _DemoMetricsState();
}

class _DemoMetricsState extends State<DemoMetrics>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: DesignTokens.colorSuccess.withValues(alpha: _animation.value),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          SizedBox(width: DesignTokens.spacingS),
          Text(
            'Live Demo',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}