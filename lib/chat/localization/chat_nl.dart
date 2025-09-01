/// Dutch localization strings for Chat features
/// Provides comprehensive Dutch translations following SecuryFlex standards
class ChatNL {
  
  // Screen titles and navigation
  static const String chat = 'Chat';
  static const String messages = 'Berichten';
  static const String workConversations = 'Werkgesprekken';
  static const String jobConversations = 'Opdracht gesprekken';
  static const String activeConversations = 'Actieve gesprekken';
  static const String archivedConversations = 'Archief';
  static const String communicationOverview = 'Communicatie overzicht';
  static const String professionalMessaging = 'Zakelijke communicatie';
  
  // Search and filtering
  static const String searchConversations = 'Zoek gesprekken...';
  static const String searchMessages = 'Zoek berichten...';
  static const String noConversationsFound = 'Geen gesprekken gevonden';
  static const String noMessagesFound = 'Geen berichten gevonden';
  static const String tryDifferentSearch = 'Probeer een andere zoekterm';
  
  // Conversation states and context
  static const String noConversationsYet = 'Nog geen gesprekken';
  static const String conversationsAutoCreated = 'Gesprekken worden automatisch aangemaakt bij aangenomen opdrachten';
  static const String jobConversationContext = 'Directe communicatie met opdrachtgevers over werkzaamheden';
  static const String professionalCommunication = 'Professionele werkgerelateerde communicatie';
  static const String noMessagesYet = 'Nog geen berichten';
  static const String sendFirstMessage = 'Stuur het eerste bericht om het gesprek te beginnen';
  
  // Job-related messaging context
  static const String jobAcceptedMessage = 'Gesprek geopend - opdracht aangenomen';
  static const String contactEmployer = 'Contact opdrachtgever';
  static const String workUpdates = 'Werk updates';
  static const String shiftCommunication = 'Dienst communicatie';
  
  // Message types and actions
  static const String typeMessage = 'Typ een bericht...';
  static const String reply = 'Beantwoorden';
  static const String copy = 'Kopiëren';
  static const String delete = 'Verwijderen';
  static const String forward = 'Doorsturen';
  static const String edit = 'Bewerken';
  
  // Message status
  static const String sent = 'Verzonden';
  static const String delivered = 'Bezorgd';
  static const String read = 'Gelezen';
  static const String failed = 'Mislukt';
  static const String sending = 'Verzenden...';
  
  // Time formatting
  static const String now = 'Nu';
  static const String today = 'Vandaag';
  static const String yesterday = 'Gisteren';
  static const String minutesAgo = 'm';
  static const String hoursAgo = 'u';
  static const String daysAgo = 'd';
  static const String weeksAgo = 'w';
  
  // Loading states
  static const String loadingConversations = 'Gesprekken laden...';
  static const String loadingPleaseWait = 'Even geduld alstublieft';
  
  // Statistics and counts
  static const String unread = 'Ongelezen';
  static const String last = 'Laatste';
  static const String total = 'Totaal';
  static const String active = 'Actief';
  static const String loadingMessages = 'Berichten laden...';
  static const String refreshing = 'Vernieuwen...';
  
  // Error states
  static const String errorLoadingConversations = 'Fout bij laden gesprekken';
  static const String errorLoadingMessages = 'Fout bij laden berichten';
  static const String errorSendingMessage = 'Fout bij verzenden bericht';
  static const String tryAgain = 'Opnieuw proberen';
  static const String somethingWentWrong = 'Er is iets misgegaan';
  
  // Actions and buttons
  static const String send = 'Verzenden';
  static const String cancel = 'Annuleren';
  static const String save = 'Opslaan';
  static const String close = 'Sluiten';
  static const String back = 'Terug';
  static const String next = 'Volgende';
  static const String done = 'Klaar';
  
  // File and media
  static const String attachFile = 'Bestand bijvoegen';
  static const String takePhoto = 'Foto maken';
  static const String choosePhoto = 'Foto kiezen';
  static const String recordAudio = 'Audio opnemen';
  static const String chooseFile = 'Bestand kiezen';
  static const String image = 'Afbeelding';
  static const String video = 'Video';
  static const String audio = 'Audio';
  static const String document = 'Document';
  
  // Call features
  static const String call = 'Bellen';
  static const String videoCall = 'Videobellen';
  static const String callFeatureComingSoon = 'Bellen - Binnenkort beschikbaar';
  static const String videoCallFeatureComingSoon = 'Videobellen - Binnenkort beschikbaar';
  static const String chatOptionsComingSoon = 'Chat opties - Binnenkort beschikbaar';
  
  // Assignment context
  static const String assignmentDetails = 'Opdracht details';
  static const String assignmentDetailsComingSoon = 'Opdracht details - Binnenkort beschikbaar';
  static const String relatedToAssignment = 'Gerelateerd aan opdracht';
  
  // Typing indicators
  static const String isTyping = 'is aan het typen...';
  static const String areTyping = 'zijn aan het typen...';
  
  // Group chat
  static const String groupChat = 'Groepschat';
  static const String participants = 'Deelnemers';
  static const String addParticipant = 'Deelnemer toevoegen';
  static const String removeParticipant = 'Deelnemer verwijderen';
  
  // Notifications
  static const String newMessage = 'Nieuw bericht';
  static const String newMessages = 'Nieuwe berichten';
  static const String messageFrom = 'Bericht van';
  
  // Settings and preferences
  static const String chatSettings = 'Chat instellingen';
  static const String notifications = 'Meldingen';
  static const String soundEnabled = 'Geluid aan';
  static const String vibrationEnabled = 'Trillen aan';
  
  // Coming soon features
  static const String newChatFeatureComingSoon = 'Nieuwe chat starten - Functionaliteit komt binnenkort';
  
  // Helper methods for dynamic strings
  static String messageCount(int count) {
    return count == 1 ? '$count bericht' : '$count berichten';
  }
  
  static String conversationCount(int count) {
    return count == 1 ? '$count gesprek' : '$count gesprekken';
  }
  
  static String unreadCount(int count) {
    return count == 1 ? '$count ongelezen' : '$count ongelezen';
  }
  
  static String participantCount(int count) {
    return count == 1 ? '$count deelnemer' : '$count deelnemers';
  }
  
  static String typingUsers(List<String> users) {
    if (users.isEmpty) return '';
    if (users.length == 1) {
      return '${users.first} $isTyping';
    } else if (users.length == 2) {
      return '${users.join(' en ')} $areTyping';
    } else {
      return '${users.take(2).join(', ')} en ${users.length - 2} anderen $areTyping';
    }
  }
  
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return ChatNL.now;
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}$minutesAgo';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}$hoursAgo';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}$daysAgo';
    } else {
      return '${(difference.inDays / 7).floor()}$weeksAgo';
    }
  }
  
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return ChatNL.today;
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return ChatNL.yesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  // Message prefix for current user
  static String currentUserMessagePrefix(String message) {
    return 'Jij: $message';
  }
}
