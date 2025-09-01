import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../../core/services/audit_service.dart';

/// Advanced message search service with Dutch language support
/// Implements intelligent search with stemming, fuzzy matching, and context awareness
class MessageSearchService {
  static MessageSearchService? _instance;
  static MessageSearchService get instance => _instance ??= MessageSearchService._();
  
  MessageSearchService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Dutch language specific stop words
  static const Set<String> _dutchStopWords = {
    'de', 'het', 'een', 'en', 'van', 'in', 'op', 'voor', 'met', 'aan',
    'bij', 'door', 'over', 'onder', 'tussen', 'na', 'naar', 'uit',
    'om', 'tot', 'tegen', 'zonder', 'binnen', 'buiten', 'achter',
    'is', 'zijn', 'was', 'waren', 'heeft', 'hebben', 'had', 'hadden',
    'kan', 'kunnen', 'mag', 'mogen', 'moet', 'moeten', 'zal', 'zullen',
    'zou', 'zouden', 'als', 'dan', 'maar', 'dus', 'want', 'omdat',
    'dat', 'wat', 'wie', 'waar', 'wanneer', 'hoe', 'waarom',
    'ja', 'nee', 'niet', 'wel', 'ook', 'nog', 'al', 'meer',
  };
  
  // Dutch word mappings for better search
  static const Map<String, List<String>> _dutchSynonyms = {
    'werk': ['job', 'baan', 'klus', 'opdracht'],
    'beveiliger': ['security', 'bewaker', 'guard'],
    'bedrijf': ['company', 'firma', 'organisatie'],
    'klant': ['client', 'customer', 'opdrachtgever'],
    'geld': ['salaris', 'loon', 'betaling', 'vergoeding'],
    'tijd': ['uur', 'uren', 'tijdstip', 'moment'],
    'locatie': ['plaats', 'adres', 'plek', 'location'],
  };
  
  /// Search messages with intelligent Dutch language processing
  Future<MessageSearchResult> searchMessages({
    required String query,
    required String userId,
    String? conversationId,
    MessageType? messageType,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    bool useIntelligentSearch = true,
  }) async {
    try {
      // Log search for analytics
      await AuditService.instance.logEvent(
        'message_search_performed',
        {
          'userId': userId,
          'query': query,
          'conversationId': conversationId,
          'messageType': messageType?.name,
          'useIntelligentSearch': useIntelligentSearch,
        },
      );
      
      final List<MessageModel> results;
      
      if (useIntelligentSearch) {
        results = await _performIntelligentSearch(
          query: query,
          userId: userId,
          conversationId: conversationId,
          messageType: messageType,
          fromDate: fromDate,
          toDate: toDate,
          limit: limit,
        );
      } else {
        results = await _performBasicSearch(
          query: query,
          userId: userId,
          conversationId: conversationId,
          messageType: messageType,
          fromDate: fromDate,
          toDate: toDate,
          limit: limit,
        );
      }
      
      return MessageSearchResult(
        success: true,
        results: results,
        totalResults: results.length,
        searchQuery: query,
        searchTime: DateTime.now(),
      );
      
    } catch (e) {
      await AuditService.instance.logEvent(
        'message_search_failed',
        {
          'userId': userId,
          'query': query,
          'error': e.toString(),
        },
      );
      
      return MessageSearchResult(
        success: false,
        results: [],
        totalResults: 0,
        searchQuery: query,
        searchTime: DateTime.now(),
        error: e.toString(),
      );
    }
  }
  
  /// Advanced search with Dutch language intelligence
  Future<List<MessageModel>> _performIntelligentSearch({
    required String query,
    required String userId,
    String? conversationId,
    MessageType? messageType,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    // Step 1: Process query with Dutch language intelligence
    final processedQuery = _processSearchQuery(query);
    
    // Step 2: Generate search terms including synonyms
    final searchTerms = _generateSearchTerms(processedQuery.terms);
    
    // Step 3: Build Firestore query
    Query messagesQuery = _firestore.collectionGroup('messages');
    
    // Add user access filter (only search in conversations user has access to)
    // Note: This would need proper implementation with conversation participant filtering
    
    // Add conversation filter
    if (conversationId != null) {
      messagesQuery = messagesQuery.where('conversationId', isEqualTo: conversationId);
    }
    
    // Add message type filter
    if (messageType != null) {
      messagesQuery = messagesQuery.where('messageType', isEqualTo: messageType.name);
    }
    
    // Add date filters
    if (fromDate != null) {
      messagesQuery = messagesQuery.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }
    if (toDate != null) {
      messagesQuery = messagesQuery.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }
    
    // Exclude deleted messages
    messagesQuery = messagesQuery.where('isDeleted', isEqualTo: false);
    
    // Order by relevance (timestamp as fallback)
    messagesQuery = messagesQuery.orderBy('timestamp', descending: true);
    messagesQuery = messagesQuery.limit(limit * 2); // Get more for filtering
    
    final snapshot = await messagesQuery.get();
    
    // Step 4: Score and rank results
    final List<ScoredMessage> scoredResults = [];
    
    for (final doc in snapshot.docs) {
      final message = MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      final score = _calculateRelevanceScore(message, processedQuery, searchTerms);
      
      if (score > 0) {
        scoredResults.add(ScoredMessage(message, score));
      }
    }
    
    // Step 5: Sort by relevance score
    scoredResults.sort((a, b) => b.score.compareTo(a.score));
    
    // Step 6: Return top results
    return scoredResults
        .take(limit)
        .map((scored) => scored.message)
        .toList();
  }
  
  /// Basic text-based search
  Future<List<MessageModel>> _performBasicSearch({
    required String query,
    required String userId,
    String? conversationId,
    MessageType? messageType,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
  }) async {
    // For basic search, we'll use a simple text contains approach
    // In production, this would use Firestore's text search capabilities
    
    Query messagesQuery = _firestore.collectionGroup('messages');
    
    if (conversationId != null) {
      messagesQuery = messagesQuery.where('conversationId', isEqualTo: conversationId);
    }
    
    if (messageType != null) {
      messagesQuery = messagesQuery.where('messageType', isEqualTo: messageType.name);
    }
    
    if (fromDate != null) {
      messagesQuery = messagesQuery.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }
    if (toDate != null) {
      messagesQuery = messagesQuery.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }
    
    messagesQuery = messagesQuery.where('isDeleted', isEqualTo: false);
    messagesQuery = messagesQuery.orderBy('timestamp', descending: true);
    messagesQuery = messagesQuery.limit(limit * 5);
    
    final snapshot = await messagesQuery.get();
    final queryLower = query.toLowerCase();
    
    return snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((message) => message.content.toLowerCase().contains(queryLower))
        .take(limit)
        .toList();
  }
  
  /// Process search query with Dutch language intelligence
  ProcessedQuery _processSearchQuery(String query) {
    // Step 1: Clean and normalize
    String normalized = query.toLowerCase().trim();
    
    // Step 2: Remove Dutch diacritics
    normalized = _removeDiacritics(normalized);
    
    // Step 3: Tokenize
    final words = normalized
        .split(RegExp(r'[^\w]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    
    // Step 4: Remove stop words
    final filteredWords = words
        .where((word) => !_dutchStopWords.contains(word))
        .toList();
    
    // Step 5: Stem words (basic Dutch stemming)
    final stemmedWords = filteredWords
        .map(_stemDutchWord)
        .toList();
    
    return ProcessedQuery(
      originalQuery: query,
      normalizedQuery: normalized,
      terms: stemmedWords,
      isPhrase: query.contains('"'),
    );
  }
  
  /// Generate search terms including synonyms
  List<String> _generateSearchTerms(List<String> baseTerms) {
    final Set<String> allTerms = Set.from(baseTerms);
    
    // Add synonyms for each term
    for (final term in baseTerms) {
      final synonyms = _dutchSynonyms[term];
      if (synonyms != null) {
        allTerms.addAll(synonyms);
      }
    }
    
    return allTerms.toList();
  }
  
  /// Calculate relevance score for a message
  double _calculateRelevanceScore(
    MessageModel message,
    ProcessedQuery processedQuery,
    List<String> searchTerms,
  ) {
    final content = message.content.toLowerCase();
    double score = 0.0;
    
    // Exact phrase match (highest score)
    if (processedQuery.isPhrase && content.contains(processedQuery.normalizedQuery)) {
      score += 100.0;
    }
    
    // Individual term matches
    for (final term in processedQuery.terms) {
      if (content.contains(term)) {
        score += 10.0;
        
        // Boost for word boundaries
        if (RegExp(r'\b' + RegExp.escape(term) + r'\b').hasMatch(content)) {
          score += 5.0;
        }
      }
    }
    
    // Synonym matches (lower score)
    for (final term in searchTerms) {
      if (!processedQuery.terms.contains(term) && content.contains(term)) {
        score += 3.0;
      }
    }
    
    // Boost recent messages
    final hoursSinceMessage = DateTime.now().difference(message.timestamp).inHours;
    if (hoursSinceMessage < 24) {
      score += 5.0;
    } else if (hoursSinceMessage < 168) { // 1 week
      score += 2.0;
    }
    
    // Boost messages from sender
    if (message.senderId != processedQuery.originalQuery) {
      score += 1.0;
    }
    
    return score;
  }
  
  /// Remove Dutch diacritics for normalization
  String _removeDiacritics(String input) {
    const diacritics = {
      'à': 'a', 'á': 'a', 'ä': 'a', 'â': 'a',
      'è': 'e', 'é': 'e', 'ë': 'e', 'ê': 'e',
      'ì': 'i', 'í': 'i', 'ï': 'i', 'î': 'i',
      'ò': 'o', 'ó': 'o', 'ö': 'o', 'ô': 'o',
      'ù': 'u', 'ú': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n', 'ç': 'c',
    };
    
    String result = input;
    diacritics.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    
    return result;
  }
  
  /// Basic Dutch word stemming
  String _stemDutchWord(String word) {
    // Very basic Dutch stemming rules
    if (word.length < 4) return word;
    
    // Remove common Dutch suffixes
    const suffixes = ['en', 'er', 'ing', 'heid', 'lijk', 'tie', 'atie'];
    
    for (final suffix in suffixes) {
      if (word.endsWith(suffix) && word.length > suffix.length + 2) {
        return word.substring(0, word.length - suffix.length);
      }
    }
    
    return word;
  }
  
  /// Search for messages by sender name
  Future<List<MessageModel>> searchBySender({
    required String senderName,
    required String userId,
    String? conversationId,
    int limit = 50,
  }) async {
    try {
      Query messagesQuery = _firestore.collectionGroup('messages');
      
      if (conversationId != null) {
        messagesQuery = messagesQuery.where('conversationId', isEqualTo: conversationId);
      }
      
      messagesQuery = messagesQuery
          .where('senderName', isGreaterThanOrEqualTo: senderName)
          .where('senderName', isLessThan: '$senderName\uf8ff')
          .where('isDeleted', isEqualTo: false)
          .orderBy('senderName')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      final snapshot = await messagesQuery.get();
      
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Get search suggestions based on user's chat history
  Future<List<String>> getSearchSuggestions(String userId, {int limit = 10}) async {
    try {
      // This would analyze user's frequent words and topics
      // For now, return common Dutch work-related terms
      return [
        'werk',
        'opdracht',
        'beveiliging',
        'planning',
        'tijd',
        'locatie',
        'klant',
        'contract',
        'betaling',
        'shift',
      ].take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Processed search query with Dutch language intelligence
class ProcessedQuery {
  final String originalQuery;
  final String normalizedQuery;
  final List<String> terms;
  final bool isPhrase;
  
  const ProcessedQuery({
    required this.originalQuery,
    required this.normalizedQuery,
    required this.terms,
    required this.isPhrase,
  });
}

/// Message with relevance score
class ScoredMessage {
  final MessageModel message;
  final double score;
  
  const ScoredMessage(this.message, this.score);
}

/// Result of message search operation
class MessageSearchResult {
  final bool success;
  final List<MessageModel> results;
  final int totalResults;
  final String searchQuery;
  final DateTime searchTime;
  final String? error;
  
  const MessageSearchResult({
    required this.success,
    required this.results,
    required this.totalResults,
    required this.searchQuery,
    required this.searchTime,
    this.error,
  });
  
  /// Get search result highlights for UI display
  List<SearchHighlight> getHighlights() {
    return results.map((message) => SearchHighlight(
      messageId: message.messageId,
      conversationId: message.conversationId,
      senderName: message.senderName,
      timestamp: message.timestamp,
      snippet: _createSnippet(message.content),
    )).toList();
  }
  
  String _createSnippet(String content, {int maxLength = 100}) {
    if (content.length <= maxLength) return content;
    
    // Try to find search term in content for better snippet
    final queryLower = searchQuery.toLowerCase();
    final contentLower = content.toLowerCase();
    final index = contentLower.indexOf(queryLower);
    
    if (index != -1) {
      final start = (index - 30).clamp(0, content.length);
      final end = (index + queryLower.length + 30).clamp(0, content.length);
      
      String snippet = content.substring(start, end);
      if (start > 0) snippet = '...$snippet';
      if (end < content.length) snippet = '$snippet...';
      
      return snippet;
    }
    
    // Fallback to simple truncation
    return '${content.substring(0, maxLength)}...';
  }
}

/// Search result highlight for UI display
class SearchHighlight {
  final String messageId;
  final String conversationId;
  final String senderName;
  final DateTime timestamp;
  final String snippet;
  
  const SearchHighlight({
    required this.messageId,
    required this.conversationId,
    required this.senderName,
    required this.timestamp,
    required this.snippet,
  });
}