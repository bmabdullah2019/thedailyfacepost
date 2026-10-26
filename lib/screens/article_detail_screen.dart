import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_post_model.dart';
import '../widgets/html_article_renderer.dart';
import '../widgets/ad_banner_widget.dart';

class ArticleDetailScreen extends StatefulWidget {
  final NewsPostModel post;
  final double fontScale;

  const ArticleDetailScreen({super.key, required this.post, required this.fontScale});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  String _fullContent = '';
  Map<String, String> _ads = {};
  bool _isLoading = true;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.content != null && widget.post.content!.trim().isNotEmpty) {
      _fullContent = widget.post.content!;
      _isLoading = false;
    }
    _checkBookmark();
    _fetchFullArticle();
  }

  Future<void> _checkBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_ids') ?? [];
    setState(() {
      _isBookmarked = list.contains(widget.post.id.toString());
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_ids') ?? [];
    final idStr = widget.post.id.toString();

    if (list.contains(idStr)) {
      list.remove(idStr);
      await prefs.remove('saved_post_$idStr');
    } else {
      list.add(idStr);
      await prefs.setString('saved_post_$idStr', json.encode(widget.post.toJson()));
    }
    await prefs.setStringList('saved_ids', list);

    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBookmarked ? 'বুকমার্কে যোগ করা হয়েছে' : 'বুকমার্ক থেকে সরানো হয়েছে'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _fetchFullArticle() async {
    try {
      final res = await http.get(Uri.parse('https://thedailyfacepost.com/api/v1/posts/${widget.post.id}'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        final content = data is Map ? (data['content'] ?? '') : '';
        
        final ads = data is Map ? data['ads'] : null;
        final adsMap = <String, String>{};
        if (ads is Map) {
          adsMap['above_content'] = ads['above_content']?.toString() ?? '';
          adsMap['in_content'] = ads['in_content']?.toString() ?? '';
          adsMap['below_content'] = ads['below_content']?.toString() ?? '';
        }

        setState(() {
          _fullContent = content.toString().trim().isNotEmpty
              ? content.toString()
              : (_fullContent.isNotEmpty ? _fullContent : widget.post.excerpt);
          _ads = adsMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          if (_fullContent.isEmpty) _fullContent = widget.post.excerpt;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        if (_fullContent.isEmpty) _fullContent = widget.post.excerpt;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.categoryName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? const Color(0xFF0284C7) : null,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share('${widget.post.title}\n\nপড়ুন: ${widget.post.shareUrl}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final uri = Uri.parse(widget.post.shareUrl);
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image: Full width responsive, not cut off by fixed height, plus tap to zoom!
            if (widget.post.thumbnail.isNotEmpty)
              GestureDetector(
                onTap: () => openFullScreenImageViewer(context, widget.post.thumbnail, title: widget.post.title),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Image.network(
                      widget.post.thumbnail,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, _, _) => Container(
                        height: 200,
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'সম্পূর্ণ ছবি দেখুন',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Ad: Above Content Banner
            if (_ads['above_content'] != null && _ads['above_content']!.isNotEmpty)
              AdBannerWidget(adCode: _ads['above_content']!, placement: 'above_content'),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag & Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.post.categoryName,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(widget.post.banglaDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    widget.post.title,
                    style: TextStyle(
                      fontSize: 20 * widget.fontScale,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Author
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.post.author, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),

                  // Ad: In-Content Native Banner
                  if (_ads['in_content'] != null && _ads['in_content']!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: AdBannerWidget(
                        adCode: _ads['in_content']!,
                        placement: 'in_content',
                        margin: EdgeInsets.zero,
                      ),
                    ),

                  const Divider(height: 24),

                  // Full Article Body
                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
                      : HtmlArticleRenderer(
                          html: _fullContent,
                          fontScale: widget.fontScale,
                          isDark: isDark,
                        ),

                  // Ad: Below Content Banner
                  if (_ads['below_content'] != null && _ads['below_content']!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: AdBannerWidget(
                        adCode: _ads['below_content']!,
                        placement: 'below_content',
                        margin: EdgeInsets.zero,
                      ),
                    ),

                  const SizedBox(height: 24),
                  // Share Action Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('সংবাদটি শেয়ার করুন:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Share.share('${widget.post.title}\n\nপড়ুন: ${widget.post.shareUrl}');
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('শেয়ার করুন'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}