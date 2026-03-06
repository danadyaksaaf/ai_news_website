import 'dart:convert';
import 'package:http/http.dart' as http;
import '../home_page.dart';

class NewsApiService {
  static String? _apiKey;
  
  static const String _baseUrl = 'https://newsapi.org/v2';
  
  // Set the API key
  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }
  
  // Check if API key is configured
  static bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;
  
  // Fetch news by topic
  static Future<List<NewsArticle>> fetchNewsByTopic(AITopic topic, {int page = 1}) async {
    if (!isConfigured) {
      throw Exception('News API key not configured. Please set your API key.');
    }
    
    String query;
    switch (topic) {
      case AITopic.coding:
        query = 'AI coding OR artificial intelligence programming OR GitHub Copilot';
      case AITopic.designing:
        query = 'AI design OR artificial intelligence design OR AI art OR Midjourney OR DALL-E';
      case AITopic.writing:
        query = 'AI writing OR ChatGPT OR artificial intelligence research OR Claude AI';
    }
    
    final url = Uri.parse(
      '$_baseUrl/everything?q=$query&sortBy=publishedAt&language=en&pageSize=10&page=$page&apiKey=$_apiKey'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        
        return articles.map((article) => NewsArticle(
          id: article['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: article['title'] ?? 'No Title',
          description: article['description'] ?? '',
          imageUrl: article['urlToImage'] ?? 'https://via.placeholder.com/800x400',
          source: article['source']?['name'] ?? 'Unknown',
          publishedAt: DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now(),
          topic: topic,
        )).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your News API key.');
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
  
  // Fetch all AI news
  static Future<List<NewsArticle>> fetchAllAiNews({int page = 1}) async {
    if (!isConfigured) {
      throw Exception('News API key not configured. Please set your API key.');
    }
    
    const query = 'artificial intelligence OR AI OR machine learning';
    
    final url = Uri.parse(
      '$_baseUrl/everything?q=$query&sortBy=publishedAt&language=en&pageSize=20&page=$page&apiKey=$_apiKey'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        
        return articles.map((article) => NewsArticle(
          id: article['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: article['title'] ?? 'No Title',
          description: article['description'] ?? '',
          imageUrl: article['urlToImage'] ?? 'https://via.placeholder.com/800x400',
          source: article['source']?['name'] ?? 'Unknown',
          publishedAt: DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now(),
          topic: _categorizeArticle(article['title'] ?? ''),
        )).toList();
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
  
  // Categorize article based on title
  static AITopic _categorizeArticle(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('code') || 
        lowerTitle.contains('program') || 
        lowerTitle.contains('copilot') ||
        lowerTitle.contains('developer')) {
      return AITopic.coding;
    } else if (lowerTitle.contains('design') || 
               lowerTitle.contains('art') || 
               lowerTitle.contains('image') ||
               lowerTitle.contains('midjourney') ||
               lowerTitle.contains('dall-e')) {
      return AITopic.designing;
    } else {
      return AITopic.writing;
    }
  }
  
  // Search news by query
  static Future<List<NewsArticle>> searchNews(String query, {int page = 1}) async {
    if (!isConfigured) {
      throw Exception('News API key not configured. Please set your API key.');
    }
    
    // Encode the query for URL
    final encodedQuery = Uri.encodeComponent(query);
    
    final url = Uri.parse(
      '$_baseUrl/everything?q=$encodedQuery&sortBy=relevancy&language=en&pageSize=20&page=$page&apiKey=$_apiKey'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        
        return articles.map((article) => NewsArticle(
          id: article['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: article['title'] ?? 'No Title',
          description: article['description'] ?? '',
          imageUrl: article['urlToImage'] ?? 'https://via.placeholder.com/800x400',
          source: article['source']?['name'] ?? 'Unknown',
          publishedAt: DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now(),
          topic: _categorizeArticle(article['title'] ?? ''),
        )).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your News API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching news: $e');
    }
  }
}

