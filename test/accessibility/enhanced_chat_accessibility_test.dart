import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/accessibility/enhanced_accessibility_helper.dart';
import 'package:securyflex_app/accessibility/chat_accessibility_service.dart';
import 'package:securyflex_app/accessibility/high_contrast_themes.dart';
import 'package:securyflex_app/accessibility/dutch_accessibility_compliance.dart';
import 'package:securyflex_app/accessibility/accessibility_testing_utils.dart';
import 'package:securyflex_app/chat/widgets/unified_message_bubble.dart';
import 'package:securyflex_app/chat/widgets/unified_chat_input.dart';
import 'package:securyflex_app/chat/widgets/unified_conversation_card.dart';
import 'package:securyflex_app/chat/models/message_model.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('Enhanced Chat Accessibility Tests', () {
    
    group('EnhancedAccessibilityHelper Tests', () {
      testWidgets('should create accessible message bubble with comprehensive semantics', 
          (WidgetTester tester) async {
        final testMessage = MessageModel(
          messageId: 'test-message-1',
          conversationId: 'test-conversation',
          senderId: 'user-1',
          senderName: 'Jan Jansen',
          content: 'Hallo, dit is een testbericht voor toegankelijkheid.',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          deliveryStatus: {
            'user-2': UserDeliveryStatus(
              userId: 'user-2',
              status: MessageDeliveryStatus.read,
              timestamp: DateTime.now(),
            ),
          },
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UnifiedMessageBubble(
                message: testMessage,
                isCurrentUser: false,
                userRole: UserRole.guard,
                onLongPress: () {},
              ),
            ),
          ),
        );
        
        await tester.pump();
        
        // Check for comprehensive semantic structure
        expect(find.byType(Semantics), findsAtLeastNWidgets(1));
        
        // Verify message semantics
        final messageSemantics = tester.widgetList<Semantics>(
          find.byWidgetPredicate((widget) {
            if (widget is Semantics) {
              return widget.properties.label?.contains('Jan Jansen') == true;
            }
            return false;
          })
        );
        
        expect(messageSemantics, isNotEmpty);
        
        // Check for proper labeling
        final firstMessageSemantic = messageSemantics.first;
        expect(firstMessageSemantic.properties.label, contains('Hallo, dit is een testbericht'));
        expect(firstMessageSemantic.properties.label, contains('Jan Jansen'));
      });
      
      testWidgets('should provide proper keyboard navigation support',
          (WidgetTester tester) async {
        final testMessage = MessageModel(
          messageId: 'test-message-1',
          conversationId: 'test-conversation',
          senderId: 'user-1',
          senderName: 'Test User',
          content: 'Test message content',
          messageType: MessageType.text,
          timestamp: DateTime.now(),
          deliveryStatus: {},
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  UnifiedMessageBubble(
                    message: testMessage,
                    isCurrentUser: false,
                    userRole: UserRole.guard,
                    onLongPress: () {},
                  ),
                  UnifiedChatInput(
                    userRole: UserRole.guard,
                    onSendMessage: (message) {},
                  ),
                ],
              ),
            ),
          ),
        );
        
        await tester.pump();
        
        // Check for focusable elements
        final focusableElements = tester.widgetList<Focus>(find.byType(Focus));
        expect(focusableElements.length, greaterThan(0));
        
        // Test keyboard navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        // Verify focus indicators are present
        final semanticsWithFocus = tester.widgetList<Semantics>(
          find.byWidgetPredicate((widget) {
            if (widget is Semantics) {
              return widget.properties.focusable == true;
            }
            return false;
          })
        );
        
        expect(semanticsWithFocus.length, greaterThan(0));
      });
    });
    
    group('Chat Accessibility Service Tests', () {
      late ChatAccessibilityService service;
      
      setUp(() {
        service = ChatAccessibilityService.instance;
      });
      
      test('should initialize with proper defaults', () async {
        await service.initialize();
        
        final preferences = service.getPreferences();
        expect(preferences.announceMessagesEnabled, isTrue);
        expect(preferences.announceTypingEnabled, isTrue);
      });
      
      test('should provide appropriate theme based on accessibility needs', () {
        final regularTheme = service.getAccessibleTheme(
          userRole: UserRole.guard,
          forceHighContrast: false,
        );
        
        final highContrastTheme = service.getAccessibleTheme(
          userRole: UserRole.guard,
          forceHighContrast: true,
        );
        
        expect(regularTheme, isNotNull);
        expect(highContrastTheme, isNotNull);
        expect(regularTheme, isNot(equals(highContrastTheme)));
      });
      
      test('should manage focus nodes correctly', () {
        const conversationId = 'test-conversation-1';
        
        final focusNode = service.getFocusNodeForConversation(conversationId);
        expect(focusNode, isNotNull);
        expect(focusNode.debugLabel, contains(conversationId));
        
        // Test cleanup
        service.clearConversationFocus(conversationId);
        
        // Should create new focus node after cleanup
        final newFocusNode = service.getFocusNodeForConversation(conversationId);
        expect(newFocusNode, isNot(equals(focusNode)));
      });
    });
    
    group('High Contrast Themes Tests', () {
      testWidgets('should apply high contrast themes correctly', 
          (WidgetTester tester) async {
        for (final userRole in UserRole.values) {
          final highContrastTheme = HighContrastThemes.getTheme(
            userRole: userRole,
            isHighContrast: true,
            isDarkMode: false,
          );
          
          await tester.pumpWidget(
            MaterialApp(
              theme: highContrastTheme,
              home: Scaffold(
                appBar: AppBar(title: Text('Test')),
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Test Button'),
                    ),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Test Content'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          
          await tester.pump();
          
          // Verify high contrast is applied
          final colorScheme = highContrastTheme.colorScheme;
          
          // Test contrast ratios meet AAA standard (7:1)
          expect(
            _calculateContrastRatio(colorScheme.primary, colorScheme.surface),
            greaterThanOrEqualTo(7.0),
          );
          
          expect(
            _calculateContrastRatio(colorScheme.onSurface, colorScheme.surface),
            greaterThanOrEqualTo(7.0),
          );
        }
      });
      
      test('should provide chat-specific high contrast colors', () {
        for (final userRole in UserRole.values) {
          final chatColors = HighContrastThemes.getChatHighContrastColors(
            userRole,
            isDark: false,
          );
          
          // Verify all required colors are provided
          expect(chatColors.currentUserBubble, isNotNull);
          expect(chatColors.currentUserText, isNotNull);
          expect(chatColors.otherUserBubble, isNotNull);
          expect(chatColors.otherUserText, isNotNull);
          expect(chatColors.systemBubble, isNotNull);
          expect(chatColors.timestampText, isNotNull);
          expect(chatColors.deliveryStatusRead, isNotNull);
          
          // Test contrast ratios
          expect(
            _calculateContrastRatio(chatColors.currentUserText, chatColors.currentUserBubble),
            greaterThanOrEqualTo(4.5),
          );
          
          expect(
            _calculateContrastRatio(chatColors.otherUserText, chatColors.otherUserBubble),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    });
    
    group('Dutch Accessibility Compliance Tests', () {
      test('should provide proper Dutch accessibility labels', () {
        final labels = DutchAccessibilityCompliance.dutchAccessibilityLabels;
        
        // Check for essential chat labels
        expect(labels['message_input'], isNotNull);
        expect(labels['send_button'], isNotNull);
        expect(labels['back_button'], isNotNull);
        
        // Verify they are in Dutch
        expect(labels['message_input'], contains('Bericht'));
        expect(labels['send_button'], contains('Dubbeltik'));
        expect(labels['back_button'], contains('Terug'));
      });
      
      test('should generate proper Toegankelijkheidsverklaring', () {
        final statement = DutchAccessibilityCompliance.generateAccessibilityStatement(
          appName: 'SecuryFlex Test App',
          organizationName: 'Test Organization B.V.',
        );
        
        expect(statement, contains('Toegankelijkheidsverklaring'));
        expect(statement, contains('WCAG 2.1 niveau AA'));
        expect(statement, contains('Nederlandse'));
        expect(statement, contains('screenreaders'));
        expect(statement, contains('toegankelijkheid@'));
      });
    });
    
    group('Accessibility Testing Utils Tests', () {
      testWidgets('should perform comprehensive accessibility scan', 
          (WidgetTester tester) async {
        final testWidget = Column(
          children: [
            Text('Test Title'),
            ElevatedButton(
              onPressed: () {},
              child: Text('Test Button'),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Test Input',
              ),
            ),
          ],
        );
        
        final scanResult = await AccessibilityTestingUtils.scanWidget(
          tester: tester,
          widget: testWidget,
          includePerformanceTests: false, // Skip performance for unit tests
          includeDutchCompliance: true,
          includeHighContrastTests: true,
        );
        
        expect(scanResult.testResults, isNotEmpty);
        expect(scanResult.overallScore, greaterThanOrEqualTo(0.0));
        expect(scanResult.overallScore, lessThanOrEqualTo(100.0));
        expect(scanResult.complianceLevel, isNotNull);
        expect(scanResult.recommendations, isNotEmpty);
      });
      
      test('should generate detailed accessibility report', () {
        final scanResult = AccessibilityScanResult(
          testResults: [
            AccessibilityTestResult(
              testName: 'Test 1',
              violations: [],
              passed: true,
              score: 100.0,
            ),
            AccessibilityTestResult(
              testName: 'Test 2',
              violations: [],
              passed: false,
              score: 75.0,
            ),
          ],
          violations: [],
          recommendations: ['Test recommendation 1', 'Test recommendation 2'],
          overallScore: 87.5,
          complianceLevel: 'Mostly Compliant',
          timestamp: DateTime.now(),
        );
        
        final report = AccessibilityTestingUtils.generateTestReport(scanResult);
        
        expect(report, contains('Accessibility Test Report'));
        expect(report, contains('Overall Score: 87.5%'));
        expect(report, contains('Mostly Compliant'));
        expect(report, contains('Test 1'));
        expect(report, contains('Test 2'));
        expect(report, contains('Test recommendation 1'));
      });
    });
    
    group('Touch Target Validation Tests', () {
      testWidgets('should validate minimum touch target sizes', 
          (WidgetTester tester) async {
        // Test with properly sized button
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('OK'),
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        
        final button = find.byType(ElevatedButton);
        expect(button, findsOneWidget);
        
        final buttonSize = tester.getSize(button);
        expect(buttonSize.width, greaterThanOrEqualTo(44.0));
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
        
        // Test with undersized button (should fail accessibility)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 30,
                height: 30,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('X'),
                ),
              ),
            ),
          ),
        );
        
        await tester.pump();
        
        final smallButton = find.byType(ElevatedButton);
        final smallButtonSize = tester.getSize(smallButton);
        
        // This should fail accessibility standards
        expect(
          smallButtonSize.width < 44.0 || smallButtonSize.height < 44.0,
          isTrue,
        );
      });
    });
    
    group('Screen Reader Compatibility Tests', () {
      testWidgets('should provide proper semantic structure for screen readers',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: Semantics(
                  header: true,
                  child: Text('Chat Screen'),
                ),
              ),
              body: Column(
                children: [
                  Semantics(
                    container: true,
                    label: 'Berichten lijst',
                    child: Expanded(
                      child: ListView(
                        children: [
                          Semantics(
                            label: 'Bericht van Jan: Hallo daar',
                            child: ListTile(
                              title: Text('Jan'),
                              subtitle: Text('Hallo daar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Semantics(
                    textField: true,
                    label: 'Typ je bericht',
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Typ een bericht...',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        
        await tester.pump();
        
        // Check for proper semantic structure
        final headers = tester.widgetList<Semantics>(
          find.byWidgetPredicate((widget) {
            if (widget is Semantics) {
              return widget.properties.header == true;
            }
            return false;
          })
        );
        expect(headers.length, greaterThan(0));
        
        // Verify semantic containers exist (using label check instead of deprecated container property)
        final containers = tester.widgetList<Semantics>(
          find.byWidgetPredicate((widget) {
            if (widget is Semantics) {
              return widget.properties.label?.contains('lijst') == true;
            }
            return false;
          })
        );
        expect(containers.length, greaterThan(0));
        
        final textFields = tester.widgetList<Semantics>(
          find.byWidgetPredicate((widget) {
            if (widget is Semantics) {
              return widget.properties.textField == true;
            }
            return false;
          })
        );
        expect(textFields.length, greaterThan(0));
      });
    });
  });
}

/// Calculate contrast ratio between two colors
double _calculateContrastRatio(Color color1, Color color2) {
  final lum1 = _getLuminance(color1);
  final lum2 = _getLuminance(color2);
  final brightest = lum1 > lum2 ? lum1 : lum2;
  final darkest = lum1 > lum2 ? lum2 : lum1;
  return (brightest + 0.05) / (darkest + 0.05);
}

/// Get relative luminance of a color
double _getLuminance(Color color) {
  final r = _getLinearRGB(color.red / 255.0);
  final g = _getLinearRGB(color.green / 255.0);
  final b = _getLinearRGB(color.blue / 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Convert sRGB to linear RGB
double _getLinearRGB(double value) {
  if (value <= 0.03928) {
    return value / 12.92;
  } else {
    return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }
}