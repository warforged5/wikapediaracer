import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/wikipedia_page.dart';

class WikipediaService {
  static const String _baseUrl = 'https://en.wikipedia.org/api/rest_v1';
  static const String _apiUrl = 'https://en.wikipedia.org/w/api.php';
  
  static WikipediaService? _instance;
  static WikipediaService get instance => _instance ??= WikipediaService._();
  WikipediaService._();

  final http.Client _client = http.Client();
  final Random _random = Random();

  Future<List<WikipediaPage>> getRandomPages(int count) async {
    final List<WikipediaPage> pages = [];
    
    try {
      // Use the proper Wikipedia API with namespace filtering for main articles only
      // and proper CORS origin parameter
      final uri = Uri.parse('$_apiUrl').replace(queryParameters: {
        'action': 'query',
        'format': 'json',
        'list': 'random',
        'rnnamespace': '0', // Main namespace only (articles)
        'rnminsize': '25000', // Minimum Page Size (Bytes)
        'rnfilterredir': 'nonredirects', // No redirects
        'rnlimit': count.toString(),
        'origin': '*', // For CORS support
      });
      
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'WikipediaRacer/1.0 (https://github.com/warforged5/wikapediaracer)',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['error'] != null) {
          print('Wikipedia API error: ${data['error']['info']}');
          return _getFallbackPages(count);
        }
        
        final randomPages = data['query']?['random'] as List?;
        if (randomPages == null) {
          return _getFallbackPages(count);
        }
        
        // Get page details in batches for efficiency
        final pageIds = randomPages.map((page) => page['id'].toString()).join('|');
        final pageDetails = await _getMultiplePageDetails(pageIds);
        
        for (final pageData in randomPages) {
          final pageId = pageData['id'] as int;
          final title = pageData['title'] as String;
          
          // Use batch-fetched details if available, otherwise create basic page
          final details = pageDetails[pageId.toString()];
          if (details != null) {
            pages.add(details);
          } else {
            pages.add(WikipediaPage(
              pageId: pageId,
              title: title,
            ));
          }
        }
      }
    } catch (e) {
      print('Error fetching random pages: $e');
      return _getFallbackPages(count);
    }

    return pages.take(count).toList();
  }

  /// Get details for multiple pages in a single API call for efficiency
  Future<Map<String, WikipediaPage>> _getMultiplePageDetails(String pageIds) async {
    final Map<String, WikipediaPage> pagesMap = {};
    
    try {
      final uri = Uri.parse('$_apiUrl').replace(queryParameters: {
        'action': 'query',
        'format': 'json',
        'prop': 'extracts|pageimages',
        'pageids': pageIds,
        'exintro': 'true', // Only intro paragraph
        'explaintext': 'true', // Plain text, no markup
        'exsectionformat': 'plain',
        'piprop': 'thumbnail',
        'pithumbsize': '300',
        'origin': '*', // For CORS support
      });
      
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'WikipediaRacer/1.0 (https://github.com/warforged5/wikapediaracer)',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        
        if (pages != null) {
          for (final entry in pages.entries) {
            final pageId = entry.key;
            final pageData = entry.value as Map<String, dynamic>;
            
            // Skip missing pages (pageId will be negative)
            if (int.tryParse(pageId)?.isNegative == true) continue;
            
            pagesMap[pageId] = WikipediaPage(
              pageId: int.tryParse(pageId) ?? 0,
              title: pageData['title'] ?? '',
              extract: pageData['extract'],
              thumbnail: pageData['thumbnail']?['source'],
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching page details: $e');
    }
    
    return pagesMap;
  }
  
  /// Get details for a single page (kept for backward compatibility)
  Future<WikipediaPage?> _getPageDetails(String title) async {
    try {
      final encodedTitle = Uri.encodeComponent(title);
      final response = await _client.get(
        Uri.parse('$_baseUrl/page/summary/$encodedTitle'),
        headers: {
          'User-Agent': 'WikipediaRacer/1.0 (https://github.com/warforged5/wikapediaracer)',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WikipediaPage(
          pageId: data['pageid'] ?? 0,
          title: data['title'] ?? title,
          extract: data['extract'],
          thumbnail: data['thumbnail']?['source'],
        );
      }
    } catch (e) {
      print('Error fetching page details for $title: $e');
    }
    return null;
  }

  List<WikipediaPage> _getFallbackPages(int count) {
    final fallbackTitles = [
      'Albert Einstein',
      'World War II',
      'Solar System',
      'Renaissance',
      'Computer Science',
      'Ancient Egypt',
      'Leonardo da Vinci',
      'Quantum Physics',
      'Pacific Ocean',
      'Shakespeare',
      'Democracy',
      'Evolution',
      'Mathematics',
      'Music',
      'Photography',
      'Astronomy',
      'Chemistry',
      'Biology',
      'History',
      'Geography',
      'Literature',
      'Philosophy',
      'Art',
      'Technology',
      'Medicine',
    ];

    final shuffled = List<String>.from(fallbackTitles)..shuffle(_random);
    return shuffled.take(count).map((title) => WikipediaPage(
      pageId: _random.nextInt(1000000),
      title: title,
    )).toList();
  }

  Future<String> getWikipediaUrl(String title) async {
    final encodedTitle = Uri.encodeComponent(title.replaceAll(' ', '_'));
    return 'https://en.wikipedia.org/wiki/$encodedTitle';
  }

  Future<bool> pageExists(String title) async {
    try {
      // Use the main MediaWiki API for existence check
      final uri = Uri.parse('$_apiUrl').replace(queryParameters: {
        'action': 'query',
        'format': 'json',
        'titles': title,
        'origin': '*',
      });
      
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'WikipediaRacer/1.0 (https://github.com/warforged5/wikapediaracer)',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        
        if (pages != null) {
          // Check if any page exists (negative page ID means missing)
          for (final pageData in pages.values) {
            final pageId = pageData['pageid'];
            if (pageId != null && pageId is int && pageId > 0) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      print('Error checking page existence for $title: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}