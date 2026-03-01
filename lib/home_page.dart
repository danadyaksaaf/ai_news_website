import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'news_api_service.dart';
import 'about_page.dart';
import 'category_page.dart';
import 'reading_history_service.dart';

// AI Topic Categories
enum AITopic { coding, designing, writing }

// News Article Model
class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String source;
  final DateTime publishedAt;
  final AITopic topic;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
    required this.topic,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AITopic? _selectedTopic;
  bool _isLoading = true;
  String? _errorMessage;
  List<NewsArticle> _newsArticles = [];
  
  // Search state
  bool _isSearchActive = false;
  String _searchQuery = '';
  List<NewsArticle> _searchResults = [];
  List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();
  
  // Search debouncer
  Timer? _debounceTimer;
  bool _isSearching = false;
  
  // Popular search suggestions
  final List<String> _popularSearches = [
    'ChatGPT',
    'GPT-4',
    'Midjourney',
    'Claude',
    'GitHub Copilot',
    'AI coding',
    'AI art',
    'Machine learning',
  ];

  // Responsive helpers
  bool get _isMobile => MediaQuery.of(context).size.width < 600;
  bool get _isTablet => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 900;
  double get _horizontalPadding => _isMobile ? 16.0 : (_isTablet ? 24.0 : 32.0);

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<NewsArticle> articles;
      
      if (NewsApiService.isConfigured) {
        if (_selectedTopic != null) {
          articles = await NewsApiService.fetchNewsByTopic(_selectedTopic!);
        } else {
          articles = await NewsApiService.fetchAllAiNews();
        }
      } else {
        // Use sample data if API is not configured
        articles = sampleNews;
      }

      setState(() {
        _newsArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        // Fall back to sample data on error
        _newsArticles = _selectedTopic != null
            ? sampleNews.where((a) => a.topic == _selectedTopic).toList()
            : sampleNews;
      });
    }
  }

  void _onTopicSelected(AITopic? topic) {
    setState(() {
      _selectedTopic = topic;
    });
    _loadNews();
  }

  String getTopicTitle(AITopic topic) {
    switch (topic) {
      case AITopic.coding:
        return 'AI for Coding';
      case AITopic.designing:
        return 'AI for Designing';
      case AITopic.writing:
        return 'AI for Writing & Researching';
    }
  }

  IconData getTopicIcon(AITopic topic) {
    switch (topic) {
      case AITopic.coding:
        return Icons.code;
      case AITopic.designing:
        return Icons.design_services;
      case AITopic.writing:
        return Icons.edit_note;
    }
  }

  Color getTopicColor(AITopic topic) {
    switch (topic) {
      case AITopic.coding:
        return const Color(0xFF6366F1);
      case AITopic.designing:
        return const Color(0xFFEC4899);
      case AITopic.writing:
        return const Color(0xFF10B981);
    }
  }

  // Build inline search bar for search mode
  Widget _buildInlineSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: _onSearchChanged,
        onSubmitted: (_) => _submitSearch(),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          hintText: 'Search AI news...',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF9CA3AF),
          ),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          // Search bar (shown when search is active)
          if (_isSearchActive)
            SliverToBoxAdapter(
              child: _buildInlineSearchBar(),
            ),
          // Recently Booming Tagline (hide when searching)
          if (!_isSearchActive)
            SliverToBoxAdapter(
              child: _buildRecentlyBoomingSection(),
            ),
          // Topic Filter Chips (hide when searching)
          if (!_isSearchActive)
            SliverToBoxAdapter(
              child: _buildTopicFilters(),
            ),
          // News List or Search Results
          SliverPadding(
            padding: EdgeInsets.all(_isMobile ? 12 : 20),
            sliver: _isSearchActive && _searchQuery.isNotEmpty 
                ? _buildSearchResultsList() 
                : _buildNewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF5F5F5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo/Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isMobile ? 'Dana AI News' : 'Dana AI News Hub',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              // Navigation - hide on mobile
              if (!_isMobile)
                Row(
                  children: [
                    _buildNavItem('Home', isSelected: true),
                    const SizedBox(width: 24),
                    _buildNavItem('Categories', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CategoryPage()),
                      );
                    }),
                    const SizedBox(width: 24),
                    _buildNavItem('About', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutPage()),
                      );
                    }),
                    const SizedBox(width: 24),
                    if (_isSearchActive)
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                        onPressed: _closeSearch,
                        tooltip: 'Close search',
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                        onPressed: _openSearch,
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    _buildNavItem('Categories', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CategoryPage()),
                      );
                    }),
                    if (_isSearchActive)
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                        onPressed: _closeSearch,
                        tooltip: 'Close search',
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                        onPressed: _openSearch,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, {bool isSelected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyBoomingSection() {
    return Container(
      margin: EdgeInsets.all(_isMobile ? 12 : 20),
      padding: EdgeInsets.all(_isMobile ? 20 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🔥 Trending Now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(height: _isMobile ? 10 : 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Recently Booming',
              style: TextStyle(
                fontSize: _isMobile ? 28 : 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(height: _isMobile ? 6 : 8),
          Text(
            'Stay updated with the latest breakthroughs in Artificial Intelligence',
            style: TextStyle(
              fontSize: _isMobile ? 13 : 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _isMobile ? 12 : 20),
          if (!_isMobile)
            Row(
              children: [
                _buildStatCard('50+', 'New Tools'),
                const SizedBox(width: 16),
                _buildStatCard('1000+', 'Articles'),
                const SizedBox(width: 16),
                _buildStatCard('50K+', 'Readers'),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatCard('50+', 'New Tools'),
                _buildStatCard('1000+', 'Articles'),
                _buildStatCard('50K+', 'Readers'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', null),
            const SizedBox(width: 12),
            _buildFilterChip('AI for Coding', AITopic.coding),
            const SizedBox(width: 12),
            _buildFilterChip('AI for Designing', AITopic.designing),
            const SizedBox(width: 12),
            _buildFilterChip('AI for Writing', AITopic.writing),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, AITopic? topic) {
    final isSelected = _selectedTopic == topic;
    final color = topic != null ? getTopicColor(topic) : const Color(0xFF6366F1);

    return GestureDetector(
      onTap: () => _onTopicSelected(topic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (topic != null) ...[
              Icon(
                getTopicIcon(topic),
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Responsive grid columns
  int get _gridCrossAxisCount {
    if (_isMobile) return 1;
    return 3;
  }

  Widget _buildNewsList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null && !NewsApiService.isConfigured) {
      // Show error only if API was configured but failed
    }

    if (_newsArticles.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No news found'),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        mainAxisSpacing: _isMobile ? 16 : 20,
        crossAxisSpacing: _isMobile ? 0 : 20,
        childAspectRatio: _isMobile ? 0.85 : 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final article = _newsArticles[index];
          return _buildNewsCard(article);
        },
        childCount: _newsArticles.length,
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    final topicColor = getTopicColor(article.topic);

    return GestureDetector(
      onTap: () {
        // Track reading history when user opens an article
        ReadingHistoryService.incrementReadingCount(article.topic);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(article: article),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: _isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with AspectRatio to prevent stretching
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: article.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Topic badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: topicColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getTopicIcon(article.topic),
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              getTopicTitle(article.topic),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(_isMobile ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.source,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(article.publishedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: _isMobile ? 15 : 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.description,
                    style: TextStyle(
                      fontSize: _isMobile ? 12 : 14,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Read more',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: topicColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: topicColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Search methods
  void _openSearch() {
    setState(() {
      _isSearchActive = true;
    });
  }

  void _closeSearch() {
    _debounceTimer?.cancel();
    setState(() {
      _isSearchActive = false;
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    // Set searching state
    setState(() {
      _isSearching = true;
    });
    
    // Debounce the API call (wait 500ms after user stops typing)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      List<NewsArticle> results;
      
      if (NewsApiService.isConfigured) {
        // Use API for search
        results = await NewsApiService.searchNews(query);
      } else {
        // Fallback to local search
        final lowerQuery = query.toLowerCase();
        results = _newsArticles.where((article) {
          return article.title.toLowerCase().contains(lowerQuery) ||
              article.description.toLowerCase().contains(lowerQuery) ||
              article.source.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      if (mounted && _searchQuery == query) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && _searchQuery == query) {
        // On error, try local search as fallback
        final lowerQuery = query.toLowerCase();
        final localResults = _newsArticles.where((article) {
          return article.title.toLowerCase().contains(lowerQuery) ||
              article.description.toLowerCase().contains(lowerQuery) ||
              article.source.toLowerCase().contains(lowerQuery);
        }).toList();
        
        setState(() {
          _searchResults = localResults;
          _isSearching = false;
        });
      }
    }
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _searchQuery = suggestion;
      _isSearching = true;
    });
    _performSearch(suggestion);
  }

  void _addToRecentSearches(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  void _submitSearch() {
    if (_searchQuery.isNotEmpty) {
      _addToRecentSearches(_searchQuery);
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
    });
  }

  // Build search results list
  Widget _buildSearchResultsList() {
    // Show loading indicator while searching
    if (_isSearching) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Searching...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 60, color: Color(0xFF9CA3AF)),
                SizedBox(height: 16),
                Text(
                  'No results found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try different keywords',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        mainAxisSpacing: _isMobile ? 16 : 20,
        crossAxisSpacing: _isMobile ? 0 : 20,
        childAspectRatio: _isMobile ? 0.85 : 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final article = _searchResults[index];
          return _buildNewsCard(article);
        },
        childCount: _searchResults.length,
      ),
    );
  }

  // Build search overlay
  Widget _buildSearchOverlay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
                    onPressed: _closeSearch,
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) => _submitSearch(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search AI news...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF9CA3AF),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.backspace_outlined,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search content
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildSearchSuggestions()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  // Build search suggestions
  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            _buildSuggestionSection(
              'Recent Searches',
              Icons.history,
              _recentSearches,
            ),
            const SizedBox(height: 24),
          ],
          // Popular searches
          _buildSuggestionSection(
            'Popular Searches',
            Icons.trending_up,
            _popularSearches,
          ),
          const SizedBox(height: 24),
          // Topic suggestions
          _buildTopicSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSuggestionSection(
    String title,
    IconData icon,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => _buildSuggestionChip(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _onSuggestionTap(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.category, size: 20, color: Color(0xFF6B7280)),
            SizedBox(width: 8),
            Text(
              'Browse by Topic',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTopicChip(AITopic.coding),
            const SizedBox(width: 8),
            _buildTopicChip(AITopic.designing),
            const SizedBox(width: 8),
            _buildTopicChip(AITopic.writing),
          ],
        ),
      ],
    );
  }

  Widget _buildTopicChip(AITopic topic) {
    final color = getTopicColor(topic);
    return GestureDetector(
      onTap: () {
        _closeSearch();
        _onTopicSelected(topic);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(getTopicIcon(topic), size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              getTopicTitle(topic),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build search results in overlay
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        return _buildSearchResultItem(article);
      },
    );
  }

  Widget _buildSearchResultItem(NewsArticle article) {
    final topicColor = getTopicColor(article.topic);
    
    return GestureDetector(
      onTap: () {
        // Track reading history when user opens an article
        ReadingHistoryService.incrementReadingCount(article.topic);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(article: article),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFF3F4F6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: topicColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getTopicTitle(article.topic),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: topicColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(article.publishedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

// Sample News Data (Fallback when API is not configured)
final List<NewsArticle> sampleNews = [
  // AI for Coding
  NewsArticle(
    id: '1',
    title: 'GitHub Copilot Gets Major Update with Advanced Code Completion',
    description: 'GitHub has announced a major update to Copilot, featuring improved code completion, better context understanding, and support for more programming languages.',
    imageUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800',
    source: 'TechCrunch',
    publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
    topic: AITopic.coding,
  ),
  NewsArticle(
    id: '2',
    title: 'Amazon CodeWhisperer Now Free for Individual Developers',
    description: 'Amazon makes CodeWhisperer available for free to individual developers, intensifying the competition in the AI coding assistant market.',
    imageUrl: 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800',
    source: 'The Verge',
    publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
    topic: AITopic.coding,
  ),
  NewsArticle(
    id: '3',
    title: 'New AI Model Can Write Production-Ready Code from Natural Language',
    description: 'A breakthrough in AI coding: a new model can generate production-ready code from plain English descriptions.',
    imageUrl: 'https://images.unsplash.com/photo-1516116216624-53e697fedbea?w=800',
    source: 'Wired',
    publishedAt: DateTime.now().subtract(const Duration(days: 1)),
    topic: AITopic.coding,
  ),
  // AI for Designing
  NewsArticle(
    id: '4',
    title: 'Midjourney v6 Released with Photorealistic Image Generation',
    description: 'Midjourney unveils version 6 with unprecedented photorealism, improved text rendering, and new creative tools.',
    imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800',
    source: 'Design Weekly',
    publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
    topic: AITopic.designing,
  ),
  NewsArticle(
    id: '5',
    title: 'Canva Integrates AI Design Tools for Everyone',
    description: 'Canva launches AI-powered design features including magic resize, background remover, and text-to-image generation.',
    imageUrl: 'https://images.unsplash.com/photo-1561070791-36c11767b26a?w=800',
    source: 'Creative Boom',
    publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
    topic: AITopic.designing,
  ),
  NewsArticle(
    id: '6',
    title: 'Adobe Firefly Reaches 1 Million Users in First Month',
    description: 'Adobe\'s AI generative tool Firefly surpasses 1 million users, demonstrating massive demand for AI design tools.',
    imageUrl: 'https://images.unsplash.com/photo-1542744094-3a31f272c490?w=800',
    source: 'Adobe Blog',
    publishedAt: DateTime.now().subtract(const Duration(days: 2)),
    topic: AITopic.designing,
  ),
  // AI for Writing & Researching
  NewsArticle(
    id: '7',
    title: 'GPT-4o Transforms Academic Research Writing',
    description: 'Researchers are embracing GPT-4o for academic writing, with new studies showing 40% improvement in paper quality.',
    imageUrl: 'https://images.unsplash.com/photo-1456324504439-367cee3b3c32?w=800',
    source: 'Nature',
    publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
    topic: AITopic.writing,
  ),
  NewsArticle(
    id: '8',
    title: 'Perplexity AI Challenges Google with New Search Engine',
    description: 'Perplexity AI launches next-gen search engine with AI-powered answers, threatening Google\'s dominance.',
    imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
    source: 'Bloomberg',
    publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
    topic: AITopic.writing,
  ),
  NewsArticle(
    id: '9',
    title: 'Claude 3.5 Sonnet Sets New Standard for AI Writing',
    description: 'Anthropic\'s Claude 3.5 Sonnet outperforms all other AI models in writing quality, reasoning, and safety benchmarks.',
    imageUrl: 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=800',
    source: 'Anthropic News',
    publishedAt: DateTime.now().subtract(const Duration(days: 1)),
    topic: AITopic.writing,
  ),
];

// News Detail Page
class NewsDetailPage extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailPage({super.key, required this.article});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  // Get related news (same topic, excluding current article)
  List<NewsArticle> get relatedNews {
    return sampleNews
        .where((a) => a.topic == widget.article.topic && a.id != widget.article.id)
        .take(4)
        .toList();
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 900;

  String getTopicTitle(AITopic topic) {
    switch (topic) {
      case AITopic.coding:
        return 'AI for Coding';
      case AITopic.designing:
        return 'AI for Designing';
      case AITopic.writing:
        return 'AI for Writing & Researching';
    }
  }

  IconData getTopicIcon(AITopic topic) {
    switch (topic) {
      case AITopic.coding:
        return Icons.code;
      case AITopic.designing:
        return Icons.design_services;
      case AITopic.writing:
        return Icons.edit_note;
    }
  }

  Color getTopicColor(AITopic topic) {
    switch (topic) {
      case AITopic.coding:
        return const Color(0xFF6366F1);
      case AITopic.designing:
        return const Color(0xFFEC4899);
      case AITopic.writing:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicColor = getTopicColor(widget.article.topic);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: _isMobile
                      ? _buildMobileContent(topicColor)
                      : _buildDesktopContent(topicColor),
                ),
              ),
            ],
          ),
          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1F2937),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile layout (stacked)
  Widget _buildMobileContent(Color topicColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroImage(),
          const SizedBox(height: 24),
          _buildArticleContent(topicColor),
          const SizedBox(height: 40),
          _buildRelatedNewsSection(topicColor),
        ],
      ),
    );
  }

  // Desktop layout (side-by-side)
  Widget _buildDesktopContent(Color topicColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main article with hero image (left side - 60%)
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(),
                const SizedBox(height: 24),
                _buildArticleContent(topicColor),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Related news (right side - 40%)
          Expanded(
            flex: 4,
            child: _buildRelatedNewsSection(topicColor),
          ),
        ],
      ),
    );
  }

  // Hero Image Widget
  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.article.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent(Color topicColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: topicColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                getTopicIcon(widget.article.topic),
                size: 16,
                color: topicColor,
              ),
              const SizedBox(width: 8),
              Text(
                getTopicTitle(widget.article.topic),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: topicColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Title
        Text(
          widget.article.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        // Meta info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.article.source,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.access_time,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Text(
              _formatDate(widget.article.publishedAt),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Description
        Text(
          widget.article.description,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4B5563),
            height: 1.7,
          ),
        ),
        const SizedBox(height: 24),
        // Additional content placeholder
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF8FAFC),
                const Color(0xFFEFF6FF),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: topicColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Full Article',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'This is the full content of the article. In a production environment, this would be fetched from the original source or through the News API content endpoint.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Share and Save buttons
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [topicColor, topicColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, color: Color(0xFF6B7280), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelatedNewsSection(Color topicColor) {
    if (relatedNews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article, size: 24, color: topicColor),
            const SizedBox(width: 8),
            Text(
              'Related News',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: topicColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Related news grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _isMobile ? 2 : 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: _isMobile ? 0.85 : 1.2,
          ),
          itemCount: relatedNews.length,
          itemBuilder: (context, index) {
            return _buildRelatedNewsCard(relatedNews[index], topicColor);
          },
        ),
      ],
    );
  }

  Widget _buildRelatedNewsCard(NewsArticle article, Color topicColor) {
    return GestureDetector(
      onTap: () {
        // Track reading history when user opens an article
        ReadingHistoryService.incrementReadingCount(article.topic);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(article: article),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.image_not_supported, size: 30),
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          article.source,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: topicColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

