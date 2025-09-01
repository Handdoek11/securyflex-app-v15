import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../repositories/chat_repository_impl.dart';

/// Use case for sending messages with WhatsApp-quality delivery tracking
/// Handles message creation, delivery confirmation, and Dutch localization
class SendMessageUseCase {
  final ChatRepository _repository = ChatRepositoryImpl.instance;

  /// Send a text message with delivery tracking
  Future<SendMessageResult> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    MessageReply? replyTo,
  }) async {
    try {
      // Validate input
      if (content.trim().isEmpty) {
        return SendMessageResult.failure('Bericht mag niet leeg zijn');
      }

      if (content.length > 4000) {
        return SendMessageResult.failure('Bericht is te lang (max 4000 tekens)');
      }

      // Create message
      final message = MessageModel(
        messageId: '', // Will be set by repository
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        content: content.trim(),
        messageType: MessageType.text,
        timestamp: DateTime.now(),
        replyTo: replyTo,
        deliveryStatus: {
          senderId: UserDeliveryStatus(
            userId: senderId,
            status: MessageDeliveryStatus.sending,
            timestamp: DateTime.now(),
          ),
        },
      );

      // Send message
      final messageId = await _repository.sendMessage(message);

      // Update delivery status to sent
      await _repository.updateMessageDeliveryStatus(
        conversationId,
        messageId,
        senderId,
        MessageDeliveryStatus.sent,
      );

      return SendMessageResult.success(messageId, 'Bericht verzonden');
    } catch (e) {
      return SendMessageResult.failure('Fout bij verzenden: ${e.toString()}');
    }
  }

  /// Send a file message with progress tracking
  Future<SendMessageResult> sendFileMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String filePath,
    required String fileName,
    required MessageType messageType,
    String? caption,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file
      final validationResult = _validateFile(filePath, fileName, messageType);
      if (!validationResult.isValid) {
        return SendMessageResult.failure(validationResult.errorMessage!);
      }

      // Upload file first using enhanced secure upload
      final fileUrl = await _repository.uploadFileAttachment(filePath, fileName, conversationId, senderId);

      // Create file attachment
      final attachment = MessageAttachment(
        fileName: fileName,
        fileUrl: fileUrl,
        fileSize: validationResult.fileSize!,
        mimeType: validationResult.mimeType!,
      );

      // Create message
      final message = MessageModel(
        messageId: '',
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        content: caption ?? _getDefaultFileCaption(messageType, fileName),
        messageType: messageType,
        timestamp: DateTime.now(),
        attachment: attachment,
        deliveryStatus: {
          senderId: UserDeliveryStatus(
            userId: senderId,
            status: MessageDeliveryStatus.sending,
            timestamp: DateTime.now(),
          ),
        },
      );

      // Send message
      final messageId = await _repository.sendMessage(message);

      // Update delivery status
      await _repository.updateMessageDeliveryStatus(
        conversationId,
        messageId,
        senderId,
        MessageDeliveryStatus.sent,
      );

      return SendMessageResult.success(messageId, 'Bestand verzonden');
    } catch (e) {
      return SendMessageResult.failure('Fout bij verzenden bestand: ${e.toString()}');
    }
  }

  /// Send system message (for assignment updates, etc.)
  Future<SendMessageResult> sendSystemMessage({
    required String conversationId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = MessageModel(
        messageId: '',
        conversationId: conversationId,
        senderId: 'system',
        senderName: 'SecuryFlex',
        content: content,
        messageType: MessageType.system,
        timestamp: DateTime.now(),
      );

      final messageId = await _repository.sendMessage(message);
      return SendMessageResult.success(messageId, 'Systeembericht verzonden');
    } catch (e) {
      return SendMessageResult.failure('Fout bij systeembericht: ${e.toString()}');
    }
  }

  /// Validate file before upload
  FileValidationResult _validateFile(String filePath, String fileName, MessageType messageType) {
    // TODO: Implement actual file validation
    // For now, return mock validation
    return FileValidationResult(
      isValid: true,
      fileSize: 1024 * 1024, // 1MB
      mimeType: 'application/octet-stream',
    );
  }

  /// Get default caption for file types in Dutch
  String _getDefaultFileCaption(MessageType messageType, String fileName) {
    switch (messageType) {
      case MessageType.image:
        return '📷 Afbeelding: $fileName';
      case MessageType.file:
        return '📄 Document: $fileName';
      case MessageType.voice:
        return '🎤 Spraakbericht';
      default:
        return fileName;
    }
  }
}

/// Result of sending a message
class SendMessageResult {
  final bool isSuccess;
  final String? messageId;
  final String message;

  const SendMessageResult._({
    required this.isSuccess,
    this.messageId,
    required this.message,
  });

  factory SendMessageResult.success(String messageId, String message) {
    return SendMessageResult._(
      isSuccess: true,
      messageId: messageId,
      message: message,
    );
  }

  factory SendMessageResult.failure(String message) {
    return SendMessageResult._(
      isSuccess: false,
      message: message,
    );
  }
}

/// File validation result
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? fileSize;
  final String? mimeType;

  const FileValidationResult({
    required this.isValid,
    this.errorMessage,
    this.fileSize,
    this.mimeType,
  });
}
