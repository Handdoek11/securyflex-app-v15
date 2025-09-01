import '../models/conversation_model.dart';
import '../repositories/chat_repository.dart';
import '../repositories/chat_repository_impl.dart';
import '../use_cases/send_message_use_case.dart';

/// Use case for creating conversations with SecuryFlex business logic
/// Handles assignment-based and direct conversations with Dutch localization
class CreateConversationUseCase {
  final ChatRepository _repository = ChatRepositoryImpl.instance;
  final SendMessageUseCase _sendMessageUseCase = SendMessageUseCase();

  /// Create conversation for assignment (automatic when job is accepted)
  Future<CreateConversationResult> createAssignmentConversation({
    required String assignmentId,
    required String assignmentTitle,
    required String companyId,
    required String companyName,
    required String guardId,
    required String guardName,
  }) async {
    try {
      // Check if conversation already exists for this assignment
      // TODO: Implement check for existing assignment conversation

      // Create participants
      final participants = <String, ParticipantDetails>{
        companyId: ParticipantDetails(
          userId: companyId,
          userName: companyName,
          userRole: 'company',
          joinedAt: DateTime.now(),
          isActive: true,
          isOnline: false,
        ),
        guardId: ParticipantDetails(
          userId: guardId,
          userName: guardName,
          userRole: 'guard',
          joinedAt: DateTime.now(),
          isActive: true,
          isOnline: false,
        ),
      };

      // Create conversation
      final conversation = ConversationModel(
        conversationId: '', // Will be set by repository
        title: assignmentTitle,
        conversationType: ConversationType.assignment,
        participants: participants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignmentId: assignmentId,
        assignmentTitle: assignmentTitle,
        metadata: {
          'createdBy': 'system',
          'assignmentId': assignmentId,
          'companyId': companyId,
          'guardId': guardId,
        },
      );

      // Create conversation
      final conversationId = await _repository.createConversation(conversation);

      // Send welcome message
      await _sendWelcomeMessage(conversationId, assignmentTitle, companyName, guardName);

      return CreateConversationResult.success(
        conversationId: conversationId,
        message: 'Chat aangemaakt voor opdracht: $assignmentTitle',
      );
    } catch (e) {
      return CreateConversationResult.failure('Fout bij aanmaken chat: ${e.toString()}');
    }
  }

  /// Create direct conversation between users
  Future<CreateConversationResult> createDirectConversation({
    required String initiatorId,
    required String initiatorName,
    required String initiatorRole,
    required String recipientId,
    required String recipientName,
    required String recipientRole,
    String? initialMessage,
  }) async {
    try {
      // Create participants
      final participants = <String, ParticipantDetails>{
        initiatorId: ParticipantDetails(
          userId: initiatorId,
          userName: initiatorName,
          userRole: initiatorRole,
          joinedAt: DateTime.now(),
          isActive: true,
          isOnline: false,
        ),
        recipientId: ParticipantDetails(
          userId: recipientId,
          userName: recipientName,
          userRole: recipientRole,
          joinedAt: DateTime.now(),
          isActive: true,
          isOnline: false,
        ),
      };

      // Create conversation
      final conversation = ConversationModel(
        conversationId: '',
        title: '', // Will be auto-generated from participant names
        conversationType: ConversationType.direct,
        participants: participants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'createdBy': initiatorId,
          'initiatorId': initiatorId,
          'recipientId': recipientId,
        },
      );

      // Create conversation
      final conversationId = await _repository.createConversation(conversation);

      // Send initial message if provided
      if (initialMessage != null && initialMessage.trim().isNotEmpty) {
        await _sendMessageUseCase.sendTextMessage(
          conversationId: conversationId,
          senderId: initiatorId,
          senderName: initiatorName,
          content: initialMessage,
        );
      }

      return CreateConversationResult.success(
        conversationId: conversationId,
        message: 'Direct gesprek aangemaakt met $recipientName',
      );
    } catch (e) {
      return CreateConversationResult.failure('Fout bij aanmaken gesprek: ${e.toString()}');
    }
  }

  /// Create conversation for workflow (when application is accepted)
  Future<CreateConversationResult> createWorkflowConversation({
    required String workflowId,
    required String jobTitle,
    required String companyId,
    required String companyName,
    required String guardId,
    required String guardName,
  }) async {
    try {
      // Check if conversation already exists for this workflow
      // TODO: Implement check for existing workflow conversation

      // Create participants
      final participants = <String, ParticipantDetails>{
        companyId: ParticipantDetails(
          userId: companyId,
          userName: companyName,
          userRole: 'company',
          joinedAt: DateTime.now(),
          isActive: true,
          isOnline: false,
        ),
        guardId: ParticipantDetails(
          userId: guardId,
          userName: guardName,
          userRole: 'guard',
          joinedAt: DateTime.now(),
          isActive: true,
          isOnline: false,
        ),
      };

      // Create conversation
      final conversation = ConversationModel(
        conversationId: '', // Will be set by repository
        title: jobTitle,
        conversationType: ConversationType.assignment,
        participants: participants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignmentId: workflowId, // Using workflow ID as assignment ID
        assignmentTitle: jobTitle,
        metadata: {
          'createdBy': 'system',
          'workflowId': workflowId,
          'jobTitle': jobTitle,
          'companyId': companyId,
          'guardId': guardId,
          'type': 'workflow',
        },
      );

      // Create conversation
      final conversationId = await _repository.createConversation(conversation);

      return CreateConversationResult.success(
        conversationId: conversationId,
        message: 'Chat aangemaakt voor workflow: $jobTitle',
      );
    } catch (e) {
      return CreateConversationResult.failure('Fout bij aanmaken workflow chat: ${e.toString()}');
    }
  }

  /// Create group conversation (future feature)
  Future<CreateConversationResult> createGroupConversation({
    required String creatorId,
    required String creatorName,
    required String creatorRole,
    required String groupTitle,
    required List<ParticipantDetails> participants,
    String? description,
  }) async {
    try {
      // Add creator to participants
      final allParticipants = <String, ParticipantDetails>{
        creatorId: ParticipantDetails(
          userId: creatorId,
          userName: creatorName,
          userRole: creatorRole,
          joinedAt: DateTime.now(),
          isActive: true,
          isOnline: false,
        ),
      };

      // Add other participants
      for (final participant in participants) {
        allParticipants[participant.userId] = participant.copyWith(
          joinedAt: DateTime.now(),
          isActive: true,
        );
      }

      // Create conversation
      final conversation = ConversationModel(
        conversationId: '',
        title: groupTitle,
        conversationType: ConversationType.group,
        participants: allParticipants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'createdBy': creatorId,
          'description': description ?? '',
          'participantCount': allParticipants.length,
        },
      );

      // Create conversation
      final conversationId = await _repository.createConversation(conversation);

      // Send group creation message
      await _sendGroupCreationMessage(conversationId, groupTitle, creatorName, participants);

      return CreateConversationResult.success(
        conversationId: conversationId,
        message: 'Groepsgesprek "$groupTitle" aangemaakt',
      );
    } catch (e) {
      return CreateConversationResult.failure('Fout bij aanmaken groep: ${e.toString()}');
    }
  }

  /// Send welcome message for assignment conversation
  Future<void> _sendWelcomeMessage(
    String conversationId,
    String assignmentTitle,
    String companyName,
    String guardName,
  ) async {
    final welcomeMessage = '''
🎯 Welkom bij de chat voor opdracht: $assignmentTitle

👥 Deelnemers:
• $companyName (Bedrijf)
• $guardName (Beveiliger)

📋 Gebruik deze chat voor:
• Opdracht details bespreken
• Tijden en locatie afstemmen
• Updates en vragen delen
• Documenten uitwisselen

Veel succes met de opdracht! 🛡️
''';

    await _sendMessageUseCase.sendSystemMessage(
      conversationId: conversationId,
      content: welcomeMessage,
      metadata: {
        'messageType': 'welcome',
        'assignmentTitle': assignmentTitle,
      },
    );
  }

  /// Send group creation message
  Future<void> _sendGroupCreationMessage(
    String conversationId,
    String groupTitle,
    String creatorName,
    List<ParticipantDetails> participants,
  ) async {
    final participantNames = participants.map((p) => p.userName).join(', ');
    
    final creationMessage = '''
👥 Groep "$groupTitle" aangemaakt door $creatorName

Deelnemers: $participantNames

Welkom allemaal! 🎉
''';

    await _sendMessageUseCase.sendSystemMessage(
      conversationId: conversationId,
      content: creationMessage,
      metadata: {
        'messageType': 'groupCreation',
        'groupTitle': groupTitle,
        'creatorName': creatorName,
      },
    );
  }
}

/// Result of creating a conversation
class CreateConversationResult {
  final bool isSuccess;
  final String? conversationId;
  final String message;

  const CreateConversationResult._({
    required this.isSuccess,
    this.conversationId,
    required this.message,
  });

  factory CreateConversationResult.success({
    required String conversationId,
    required String message,
  }) {
    return CreateConversationResult._(
      isSuccess: true,
      conversationId: conversationId,
      message: message,
    );
  }

  factory CreateConversationResult.failure(String message) {
    return CreateConversationResult._(
      isSuccess: false,
      message: message,
    );
  }
}

/// Conversation validation result
class ConversationValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ConversationValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  factory ConversationValidationResult.valid() {
    return const ConversationValidationResult._(isValid: true);
  }

  factory ConversationValidationResult.invalid(String errorMessage) {
    return ConversationValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}
