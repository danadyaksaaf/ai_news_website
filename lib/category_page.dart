import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'home_page.dart';
import 'news_api_service.dart';
import 'reading_history_service.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool _isLoading = true;
  String? _selectedCategoryTitle;
  List<NewsArticle> _categoryArticles = [];
  String? _errorMessage;

  // Get prioritized topics based on reading history
  List<AITopic> get _prioritizedTopics => ReadingHistoryService.getPrioritizedTopics();

  bool get _isMobile => MediaQuery.of(context).size.width < 600;
  bool get _isTablet => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 900;
  double get _horizontalPadding => _isMobile ? 16.0 : (_isTablet ? 24.0 : 32.0);

  @override
  void initState() {
    super.initState();
    // By default, select the most read category
    final prioritizedTopics = _prioritizedTopics;
    if (prioritizedTopics.isNotEmpty) {
      _loadCategory(prioritizedTopics.first);
    } else {
      _loadCategory(AITopic.coding);
    }
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

  String getTopicDescription(AITopic topic) {
    switch (topic) {
      case AITopic.coding:
        return 'AI-powered coding tools, code assistants, and programming innovations';
      case AITopic.designing:
        return 'AI design tools, image generators, and creative AI innovations';
      case AITopic.writing:
        return 'AI writing assistants, research tools, and content generation';
    }
  }

  Future<void> _loadCategory(AITopic topic) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedCategoryTitle = getTopicTitle(topic);
    });

    try {
      List<NewsArticle> articles;

      if (NewsApiService.isConfigured) {
        articles = await NewsApiService.fetchNewsByTopic(topic);
      } else {
        // Use sample data if API is not configured
        articles = sampleNews.where((a) => a.topic == topic).toList();
      }

      setState(() {
        _categoryArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        // Fall back to sample data on error
        _categoryArticles = sampleNews
            .where((a) => a.topic == topic)
            .toList();
      });
    }
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
          // Personalized Categories List
          SliverToBoxAdapter(
            child: _buildPersonalizedCategories(),
          ),
          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
                vertical: 16,
              ),
              child: Row(
                children: [
                  if (_selectedCategoryTitle != null) ...[
                    Icon(
                      getTopicIcon(_prioritizedTopics.firstWhere(
                        (t) => getTopicTitle(t) == _selectedCategoryTitle,
                        orElse: () => AITopic.coding,
                      )),
                      size: 24,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedCategoryTitle!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Articles Grid
          SliverPadding(
            padding: EdgeInsets.all(_isMobile ? 12 : 20),
            sliver: _buildArticlesList(),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF6B7280),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Subtitle
              const Text(
                'Browse news by category',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizedCategories() {
    return Padding(
      padding: EdgeInsets.all(_horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personalization indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  ReadingHistoryService.getTotalReadingCount() > 0
                      ? 'Personalized for you'
                      : 'All categories',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Categories Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _isMobile ? 1 : 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: _isMobile ? 1.8 : 1.2,
            ),
            itemCount: _prioritizedTopics.length,
            itemBuilder: (context, index) {
              final topic = _prioritizedTopics[index];
              final isSelected = getTopicTitle(topic) == _selectedCategoryTitle;
              return _buildCategoryCard(topic, isSelected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(AITopic topic, bool isSelected) {
    final color = getTopicColor(topic);
    final readingCount = ReadingHistoryService.getReadingCount(topic);
    final percentage = ReadingHistoryService.getReadingPercentage(topic);
    final isPersonalized = ReadingHistoryService.getTotalReadingCount() > 0;

    return GestureDetector(
      onTap: () => _loadCategory(topic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and Topic Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    getTopicIcon(topic),
                    color: isSelected ? Colors.white : color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTopicTitle(topic),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_categoryArticles.length} articles',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Reading Stats (only show if personalized and has reads)
            if (isPersonalized && readingCount > 0) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 14,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$readingCount reads (${percentage.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Priority Badge for top category
            if (isPersonalized && _prioritizedTopics.indexOf(topic) == 0 && readingCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 12,
                      color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Top Pick',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Responsive grid columns
  int get _gridCrossAxisCount {
    if (_isMobile) return 1;
    return 2;
  }

  Widget _buildArticlesList() {
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

    if (_categoryArticles.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 60,
                  color: const Color(0xFF9CA3AF),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No articles found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
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
        childAspectRatio: _isMobile ? 0.85 : 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final article = _categoryArticles[index];
          return _buildNewsCard(article);
        },
        childCount: _categoryArticles.length,
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
            // Image
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
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
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
                      color: const Color(0xFF1F2937),
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
}

