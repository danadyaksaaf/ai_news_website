import 'package:shared_preferences/shared_preferences.dart';
import '../home_page.dart';

/// Service to track and persist user's reading history per category.
/// This enables personalization by prioritizing categories the user reads most.
class ReadingHistoryService {
  static const String _codingKey = 'reading_count_coding';
  static const String _designingKey = 'reading_count_designing';
  static const String _writingKey = 'reading_count_writing';
  
  static SharedPreferences? _prefs;
  
  /// Initialize SharedPreferences - call this at app startup
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Get reading count for a specific topic
  static int getReadingCount(AITopic topic) {
    if (_prefs == null) return 0;
    
    switch (topic) {
      case AITopic.coding:
        return _prefs!.getInt(_codingKey) ?? 0;
      case AITopic.designing:
        return _prefs!.getInt(_designingKey) ?? 0;
      case AITopic.writing:
        return _prefs!.getInt(_writingKey) ?? 0;
    }
  }
  
  /// Increment reading count for a specific topic (call when user reads an article)
  static Future<void> incrementReadingCount(AITopic topic) async {
    if (_prefs == null) return;
    
    switch (topic) {
      case AITopic.coding:
        final currentCount = _prefs!.getInt(_codingKey) ?? 0;
        await _prefs!.setInt(_codingKey, currentCount + 1);
        break;
      case AITopic.designing:
        final currentCount = _prefs!.getInt(_designingKey) ?? 0;
        await _prefs!.setInt(_designingKey, currentCount + 1);
        break;
      case AITopic.writing:
        final currentCount = _prefs!.getInt(_writingKey) ?? 0;
        await _prefs!.setInt(_writingKey, currentCount + 1);
        break;
    }
  }
  
  /// Get all topic counts as a map
  static Map<AITopic, int> getAllTopicCounts() {
    return {
      AITopic.coding: getReadingCount(AITopic.coding),
      AITopic.designing: getReadingCount(AITopic.designing),
      AITopic.writing: getReadingCount(AITopic.writing),
    };
  }
  
  /// Get sorted list of topics by reading count (highest first - for personalization)
  static List<AITopic> getPrioritizedTopics() {
    final counts = getAllTopicCounts();
    final topics = AITopic.values.toList();
    
    // Sort by reading count (descending), keeping original order for ties
    topics.sort((a, b) {
      final countA = counts[a] ?? 0;
      final countB = counts[b] ?? 0;
      return countB.compareTo(countA);
    });
    
    return topics;
  }
  
  /// Get total reading count across all topics
  static int getTotalReadingCount() {
    return getReadingCount(AITopic.coding) +
           getReadingCount(AITopic.designing) +
           getReadingCount(AITopic.writing);
  }
  
  /// Get reading percentage for a specific topic
  static double getReadingPercentage(AITopic topic) {
    final total = getTotalReadingCount();
    if (total == 0) return 0;
    return (getReadingCount(topic) / total) * 100;
  }
  
  /// Reset all reading history
  static Future<void> resetHistory() async {
    if (_prefs == null) return;
    await _prefs!.remove(_codingKey);
    await _prefs!.remove(_designingKey);
    await _prefs!.remove(_writingKey);
  }
}

