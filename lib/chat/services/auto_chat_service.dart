import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../use_cases/create_conversation_use_case.dart';
import '../use_cases/send_message_use_case.dart';

/// Auto-chat service for SecuryFlex
/// Automatically creates conversations and sends welcome messages when assignments are accepted
class AutoChatService {
  static final AutoChatService _instance = AutoChatService._internal();
  factory AutoChatService() => _instance;
  AutoChatService._internal();

  static AutoChatService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CreateConversationUseCase _createConversationUseCase = CreateConversationUseCase();
  final SendMessageUseCase _sendMessageUseCase = SendMessageUseCase();

  /// Create automatic conversation when assignment is accepted
  Future<String?> createAssignmentConversation({
    required String assignmentId,
    required String assignmentTitle,
    required String guardId,
    required String guardName,
    required String companyId,
    required String companyName,
    required DateTime assignmentDate,
    required String assignmentLocation,
  }) async {
    try {
      debugPrint('Creating auto-chat for assignment: $assignmentId');

      // Create conversation
      final result = await _createConversationUseCase.createAssignmentConversation(
        assignmentId: assignmentId,
        assignmentTitle: assignmentTitle,
        companyId: companyId,
        companyName: companyName,
        guardId: guardId,
        guardName: guardName,
      );

      if (result.isSuccess && result.conversationId != null) {
        final conversationId = result.conversationId!;
        
        // Send welcome messages
        await _sendWelcomeMessages(
          conversationId: conversationId,
          assignmentTitle: assignmentTitle,
          guardName: guardName,
          companyName: companyName,
          assignmentDate: assignmentDate,
          assignmentLocation: assignmentLocation,
        );

        debugPrint('Auto-chat created successfully: $conversationId');
        return conversationId;
      } else {
        debugPrint('Failed to create auto-chat: ${result.message}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating assignment conversation: $e');
      return null;
    }
  }

  /// Send welcome messages to new conversation
  Future<void> _sendWelcomeMessages({
    required String conversationId,
    required String assignmentTitle,
    required String guardName,
    required String companyName,
    required DateTime assignmentDate,
    required String assignmentLocation,
  }) async {
    try {
      // System welcome message
      await _sendSystemMessage(
        conversationId: conversationId,
        content: _generateWelcomeMessage(
          assignmentTitle: assignmentTitle,
          guardName: guardName,
          companyName: companyName,
          assignmentDate: assignmentDate,
          assignmentLocation: assignmentLocation,
        ),
      );

      // Wait a bit before sending the next message
      await Future.delayed(const Duration(seconds: 1));

      // Assignment details message
      await _sendSystemMessage(
        conversationId: conversationId,
        content: _generateAssignmentDetailsMessage(
          assignmentTitle: assignmentTitle,
          assignmentDate: assignmentDate,
          assignmentLocation: assignmentLocation,
        ),
      );

      // Wait a bit before sending the next message
      await Future.delayed(const Duration(seconds: 1));

      // Communication guidelines message
      await _sendSystemMessage(
        conversationId: conversationId,
        content: _generateCommunicationGuidelinesMessage(),
      );

    } catch (e) {
      debugPrint('Error sending welcome messages: $e');
    }
  }

  /// Send system message
  Future<void> _sendSystemMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      await _sendMessageUseCase.sendTextMessage(
        conversationId: conversationId,
        senderId: 'system',
        senderName: 'SecuryFlex Systeem',
        content: content,
      );
    } catch (e) {
      debugPrint('Error sending system message: $e');
    }
  }

  /// Generate welcome message in Dutch
  String _generateWelcomeMessage({
    required String assignmentTitle,
    required String guardName,
    required String companyName,
    required DateTime assignmentDate,
    required String assignmentLocation,
  }) {
    final dateStr = _formatDutchDate(assignmentDate);
    
    return '''🎉 Welkom in de chat voor "$assignmentTitle"!

👋 Hallo $guardName en $companyName,

Deze chat is automatisch aangemaakt omdat de opdracht is geaccepteerd. Hier kunnen jullie direct communiceren over:

• Opdracht details en vragen
• Aankomst- en vertrektijden  
• Bijzondere instructies
• Contact tijdens de opdracht

📅 Opdracht datum: $dateStr
📍 Locatie: $assignmentLocation

Veel succes met de samenwerking! 🤝''';
  }

  /// Generate assignment details message
  String _generateAssignmentDetailsMessage({
    required String assignmentTitle,
    required DateTime assignmentDate,
    required String assignmentLocation,
  }) {
    final dateStr = _formatDutchDate(assignmentDate);
    final timeStr = _formatDutchTime(assignmentDate);
    
    return '''📋 Opdracht Details

🏢 Opdracht: $assignmentTitle
📅 Datum: $dateStr
🕐 Tijd: $timeStr
📍 Locatie: $assignmentLocation

ℹ️ Voor vragen over de opdracht kunt u direct contact opnemen via deze chat.''';
  }

  /// Generate communication guidelines message
  String _generateCommunicationGuidelinesMessage() {
    return '''📱 Communicatie Richtlijnen

✅ Gebruik deze chat voor:
• Vragen over de opdracht
• Aankomst- en vertrektijden doorgeven
• Bijzondere situaties melden
• Contact tijdens de opdracht

⚠️ Belangrijk:
• Wees professioneel en respectvol
• Reageer tijdig op berichten
• Bij noodgevallen: bel direct 112
• Voor urgente zaken: gebruik ook telefoon

📞 Voor directe hulp kunt u altijd contact opnemen met SecuryFlex support.''';
  }

  /// Create automatic conversation when job application is accepted
  /// Supports both 1-on-1 and group chats based on number of guards
  Future<String?> createApplicationAcceptedChat({
    required String jobId,
    required String jobTitle,
    required List<String> guardIds,
    required List<String> guardNames,
    required String companyId,
    required String companyName,
    required DateTime jobStartDate,
    required String jobLocation,
  }) async {
    try {
      debugPrint('Creating auto-chat for accepted application: Job $jobId with ${guardIds.length} guard(s)');
      
      // Determine if it's a group chat or 1-on-1
      final isGroupChat = guardIds.length > 1;
      
      if (isGroupChat) {
        // Create group chat for multiple guards
        final conversationId = 'job_${jobId}_${DateTime.now().millisecondsSinceEpoch}';
        
        // Create group conversation in Firestore
        await _firestore.collection('conversations').doc(conversationId).set({
          'id': conversationId,
          'type': 'group',
          'title': '$jobTitle - Groepschat',
          'participants': [companyId, ...guardIds],
          'participantNames': {
            companyId: companyName,
            for (int i = 0; i < guardIds.length; i++)
              guardIds[i]: guardNames[i],
          },
          'metadata': {
            'jobId': jobId,
            'jobTitle': jobTitle,
            'jobLocation': jobLocation,
            'jobStartDate': Timestamp.fromDate(jobStartDate),
            'companyId': companyId,
            'companyName': companyName,
            'isJobChat': true,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
          'unreadCount': {
            for (String id in [companyId, ...guardIds])
              id: 1, // Start with 1 unread for the welcome message
          },
        });
        
        // Send welcome message to group
        await _sendSystemMessage(
          conversationId: conversationId,
          content: '''🎉 Groepschat Aangemaakt

Welkom bij de groepschat voor "$jobTitle"!

👥 Deelnemers:
• $companyName (Opdrachtgever)
${guardNames.map((name) => '• $name (Beveiliger)').join('\n')}

📍 Locatie: $jobLocation
📅 Startdatum: ${_formatDutchDate(jobStartDate)}

Deze chat is aangemaakt om de communicatie voor deze opdracht te vergemakkelijken.''',
        );
        
        debugPrint('Group chat created successfully: $conversationId');
        return conversationId;
        
      } else {
        // Create 1-on-1 chat for single guard
        final guardId = guardIds.first;
        final guardName = guardNames.first;
        
        // Use existing method for assignment conversation (1-on-1)
        return await createAssignmentConversation(
          assignmentId: jobId,
          assignmentTitle: jobTitle,
          guardId: guardId,
          guardName: guardName,
          companyId: companyId,
          companyName: companyName,
          assignmentDate: jobStartDate,
          assignmentLocation: jobLocation,
        );
      }
    } catch (e) {
      debugPrint('Error creating application accepted chat: $e');
      return null;
    }
  }

  /// Send assignment status update message
  Future<void> sendAssignmentStatusUpdate({
    required String conversationId,
    required String status,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      String content;
      
      switch (status.toLowerCase()) {
        case 'started':
          content = '''🟢 Opdracht Gestart

De beveiliger is aangekomen en de opdracht is gestart.

⏰ Starttijd: ${_formatDutchTime(DateTime.now())}
👤 Gestart door: $updatedBy''';
          break;
        case 'completed':
          content = '''✅ Opdracht Voltooid

De opdracht is succesvol afgerond.

⏰ Eindtijd: ${_formatDutchTime(DateTime.now())}
👤 Voltooid door: $updatedBy''';
          break;
        case 'cancelled':
          content = '''❌ Opdracht Geannuleerd

De opdracht is geannuleerd.

⏰ Geannuleerd op: ${_formatDutchTime(DateTime.now())}
👤 Geannuleerd door: $updatedBy${reason != null ? '\n📝 Reden: $reason' : ''}''';
          break;
        case 'delayed':
          content = '''⏰ Opdracht Vertraagd

Er is een vertraging gemeld voor deze opdracht.

⏰ Gemeld op: ${_formatDutchTime(DateTime.now())}
👤 Gemeld door: $updatedBy${reason != null ? '\n📝 Reden: $reason' : ''}''';
          break;
        default:
          content = '''📢 Status Update

Status gewijzigd naar: $status

⏰ Gewijzigd op: ${_formatDutchTime(DateTime.now())}
👤 Gewijzigd door: $updatedBy${reason != null ? '\n📝 Opmerking: $reason' : ''}''';
      }

      await _sendSystemMessage(
        conversationId: conversationId,
        content: content,
      );
    } catch (e) {
      debugPrint('Error sending assignment status update: $e');
    }
  }

  /// Send assignment reminder message
  Future<void> sendAssignmentReminder({
    required String conversationId,
    required String assignmentTitle,
    required DateTime assignmentDate,
    required String assignmentLocation,
    required int hoursUntilStart,
  }) async {
    try {
      String content;
      
      if (hoursUntilStart <= 1) {
        content = '''🔔 Opdracht Start Binnenkort!

⚠️ De opdracht "$assignmentTitle" start over ${hoursUntilStart == 0 ? 'minder dan een uur' : '$hoursUntilStart uur'}.

📅 Starttijd: ${_formatDutchTime(assignmentDate)}
📍 Locatie: $assignmentLocation

🚗 Zorg ervoor dat u op tijd vertrekt en bij vragen direct contact opneemt!''';
      } else if (hoursUntilStart <= 24) {
        content = '''📅 Opdracht Herinnering

De opdracht "$assignmentTitle" start morgen.

📅 Starttijd: ${_formatDutchTime(assignmentDate)}
📍 Locatie: $assignmentLocation

✅ Controleer uw planning en bereid u voor op de opdracht.''';
      } else {
        content = '''📋 Opdracht Bevestiging

Herinnering voor de opdracht "$assignmentTitle".

📅 Datum: ${_formatDutchDate(assignmentDate)}
🕐 Tijd: ${_formatDutchTime(assignmentDate)}
📍 Locatie: $assignmentLocation

📝 Noteer deze opdracht in uw agenda.''';
      }

      await _sendSystemMessage(
        conversationId: conversationId,
        content: content,
      );
    } catch (e) {
      debugPrint('Error sending assignment reminder: $e');
    }
  }

  /// Format Dutch date
  String _formatDutchDate(DateTime date) {
    final weekdays = ['maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'];
    final months = ['januari', 'februari', 'maart', 'april', 'mei', 'juni',
                   'juli', 'augustus', 'september', 'oktober', 'november', 'december'];
    
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    
    return '$weekday $day $month $year';
  }

  /// Format Dutch time
  String _formatDutchTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Check if conversation exists for assignment
  Future<String?> getConversationForAssignment(String assignmentId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('assignmentId', isEqualTo: assignmentId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error checking conversation for assignment: $e');
      return null;
    }
  }

  /// Archive conversation when assignment is completed
  Future<void> archiveAssignmentConversation(String conversationId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Send archive notification
      await _sendSystemMessage(
        conversationId: conversationId,
        content: '''📁 Chat Gearchiveerd

Deze chat is gearchiveerd omdat de opdracht is voltooid.

✅ U kunt nog steeds berichten bekijken, maar nieuwe berichten zijn niet meer mogelijk.
📞 Voor nieuwe vragen kunt u contact opnemen met SecuryFlex support.

Bedankt voor het gebruik van SecuryFlex! 🙏''',
      );
      
      debugPrint('Conversation archived: $conversationId');
    } catch (e) {
      debugPrint('Error archiving conversation: $e');
    }
  }

  /// Create workflow conversation when application is accepted
  Future<String> createWorkflowConversation({
    required String guardId,
    required String guardName,
    required String companyId,
    required String companyName,
    required String jobTitle,
    required String workflowId,
    required String initialMessage,
  }) async {
    try {
      debugPrint('Creating workflow conversation for: $workflowId');

      // Create conversation using existing use case
      final result = await _createConversationUseCase.createWorkflowConversation(
        workflowId: workflowId,
        jobTitle: jobTitle,
        companyId: companyId,
        companyName: companyName,
        guardId: guardId,
        guardName: guardName,
      );

      if (result.isSuccess && result.conversationId != null) {
        final conversationId = result.conversationId!;
        
        // Send welcome message from company
        await _sendSystemMessage(
          conversationId: conversationId,
          content: _generateWorkflowWelcomeMessage(
            jobTitle: jobTitle,
            guardName: guardName,
            companyName: companyName,
            initialMessage: initialMessage,
          ),
        );

        // Send workflow guidelines
        await Future.delayed(const Duration(seconds: 1));
        await _sendSystemMessage(
          conversationId: conversationId,
          content: _generateWorkflowGuidelinesMessage(),
        );

        debugPrint('Workflow conversation created successfully: $conversationId');
        return conversationId;
      } else {
        throw Exception('Failed to create workflow conversation: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error creating workflow conversation: $e');
      throw Exception('Fout bij aanmaken communicatie: $e');
    }
  }

  /// Generate workflow welcome message
  String _generateWorkflowWelcomeMessage({
    required String jobTitle,
    required String guardName,
    required String companyName,
    required String initialMessage,
  }) {
    return '''🎉 Welkom in de chat voor "$jobTitle"!

👋 Hallo $guardName,

$companyName heeft je sollicitatie geaccepteerd! Deze chat is automatisch aangemaakt zodat jullie direct kunnen communiceren.

💬 Bericht van $companyName:
"$initialMessage"

📋 Via deze chat kunnen jullie:
• Afspraken maken over start- en eindtijden
• Belangrijke details bespreken
• Contact houden tijdens de opdracht
• Vragen stellen over de werkzaamheden

Veel succes met de opdracht! 🤝''';
  }

  /// Generate workflow communication guidelines
  String _generateWorkflowGuidelinesMessage() {
    return '''📱 Werkflow Communicatie

✅ Gebruik deze chat voor:
• Planning en tijden afstemmen
• Vragen over de opdracht
• Status updates tijdens werkzaamheden
• Professionele communicatie

⚠️ Belangrijk:
• Houd communicatie zakelijk en respectvol
• Reageer binnen redelijke tijd
• Bij noodsituaties: direct bellen naar 112
• Voor dringende zaken: ook telefonisch contact

📞 Voor ondersteuning: SecuryFlex helpdesk
🔒 Alle communicatie wordt veilig opgeslagen conform GDPR''';
  }

  /// Send workflow status update
  Future<void> sendWorkflowStatusUpdate({
    required String conversationId,
    required String status,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      String content;
      
      switch (status.toLowerCase()) {
        case 'in_progress':
          content = '''🟢 Opdracht Gestart

De beveiliger heeft de opdracht gestart.

⏰ Starttijd: ${_formatDutchTime(DateTime.now())}
👤 Gestart door: $updatedBy

📞 Voor contact tijdens de opdracht kunt u deze chat gebruiken.''';
          break;
        case 'completed':
          content = '''✅ Opdracht Voltooid

De opdracht is succesvol afgerond.

⏰ Eindtijd: ${_formatDutchTime(DateTime.now())}
👤 Voltooid door: $updatedBy

📝 Binnenkort ontvangen beide partijen een verzoek voor beoordeling.''';
          break;
        case 'rated':
          content = '''⭐ Beoordelingen Compleet

Beide partijen hebben een beoordeling gegeven.

⏰ Voltooid op: ${_formatDutchTime(DateTime.now())}
💰 Betaling wordt nu verwerkt volgens de afgesproken voorwaarden.''';
          break;
        case 'paid':
          content = '''💰 Betaling Verwerkt

De betaling voor deze opdracht is succesvol verwerkt.

⏰ Verwerkt op: ${_formatDutchTime(DateTime.now())}
✅ De workflow is nu volledig afgerond.

Bedankt voor het gebruik van SecuryFlex!''';
          break;
        case 'cancelled':
          content = '''❌ Opdracht Geannuleerd

De opdracht is geannuleerd.

⏰ Geannuleerd op: ${_formatDutchTime(DateTime.now())}
👤 Geannuleerd door: $updatedBy${reason != null ? '\n📝 Reden: $reason' : ''}

📞 Voor vragen kunt u contact opnemen met SecuryFlex support.''';
          break;
        default:
          content = '''📢 Status Update

Status gewijzigd naar: $status

⏰ Gewijzigd op: ${_formatDutchTime(DateTime.now())}
👤 Gewijzigd door: $updatedBy${reason != null ? '\n📝 Opmerking: $reason' : ''}''';
      }

      await _sendSystemMessage(
        conversationId: conversationId,
        content: content,
      );
    } catch (e) {
      debugPrint('Error sending workflow status update: $e');
    }
  }

  /// Check if conversation exists for workflow
  Future<String?> getConversationForWorkflow(String workflowId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('workflowId', isEqualTo: workflowId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error checking conversation for workflow: $e');
      return null;
    }
  }
}
