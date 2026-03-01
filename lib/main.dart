import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';
import 'news_api_service.dart';
import 'reading_history_service.dart';
import 'category_page.dart';

void main() async {
  // TODO: Replace with your actual News API key
  // Get your free API key at: https://newsapi.org/register
  const String newsApiKey = 'e51febd685bd45a4925a96e7f4084af5';
  
  // Initialize the API key
  if (newsApiKey != 'YOUR_API_KEY_HERE') {
    NewsApiService.setApiKey(newsApiKey);
  }
  
  // Initialize reading history service
  await ReadingHistoryService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI News Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: const HomePage(),
    );
  }
}

