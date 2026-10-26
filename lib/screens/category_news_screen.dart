import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/news_post_model.dart';
import '../widgets/news_card_widget.dart';
import '../widgets/ad_banner_widget.dart';

class CategoryNewsScreen extends StatefulWidget {
  final CategoryModel category;
  final double fontScale;

  const CategoryNewsScreen({super.key, required this.category, required this.fontScale});

  @override
  State<CategoryNewsScreen> createState() => _CategoryNewsScreenState();
}

class _CategoryNewsScreenState extends State<CategoryNewsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<NewsPostModel> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchCategoryPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _fetchCategoryPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final url = 'https://thedailyfacepost.com/api/v1/posts?category_slug=${Uri.encodeComponent(widget.category.slug)}&page=1';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = extractPostList(body);
        final meta = body is Map ? (body['meta'] ?? {}) : {};
        final lastPage = meta is Map ? (meta['last_page'] ?? 1) : 1;

        setState(() {
          _posts = list;
          _isLoading = false;
          _hasMore = list.isNotEmpty && lastPage > 1;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'সংবাদ লোড করতে সমস্যা হয়েছে (${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ইন্টারনেট সংযোগ চেক করুন';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final url = 'https://thedailyfacepost.com/api/v1/posts?category_slug=${Uri.encodeComponent(widget.category.slug)}&page=$nextPage';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = extractPostList(body);
        final meta = body is Map ? (body['meta'] ?? {}) : {};
        final lastPage = meta is Map ? (meta['last_page'] ?? nextPage) : nextPage;

        setState(() {
          _posts.addAll(list);
          _currentPage = nextPage;
          _isLoadingMore = false;
          if (list.isEmpty || nextPage >= lastPage) {
            _hasMore = false;
          }
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_errorMessage, style: const TextStyle(fontSize: 15, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchCategoryPosts,
                        child: const Text('পুনরায় চেষ্টা করুন'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.newspaper_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            '${widget.category.name} বিভাগে কোনো সংবাদ পাওয়া যায়নি',
                            style: const TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchCategoryPosts,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: _posts.length + 1,
                        itemBuilder: (context, index) {
                          if (index < _posts.length) {
                            final showAd = (index == 2 || index == 6);
                            const categoryBannerAd = "<div class='MainAdverTiseMentDiv' data-publisher=\"eyJpdiI6IlpJQWRLbUlWSWJEbmJlcDAvUUNHeUE9PSIsInZhbHVlIjoiM0hoM2pabS9hNUdsZHZDS3UyQTNsZz09IiwibWFjIjoiZmM3ZDUzODU4MmUwNTBjYTJjODBkNDhkMmEwOGFjODkxNTdhMzBkZDFkOGFkZWViZTcwOTk2NWNhN2I2N2IxOSIsInRhZyI6IiJ9\" data-adsize=\"728x90\"></div><script class=\"adScriptClass\" src=\"https://adsmarketsbd.com/assets/ads/ad.js\"></script>";

                            return Column(
                              children: [
                                NewsCardWidget(
                                  post: _posts[index],
                                  fontScale: widget.fontScale,
                                ),
                                if (showAd)
                                  const AdBannerWidget(
                                    adCode: categoryBannerAd,
                                    placement: 'in_content',
                                    margin: EdgeInsets.only(bottom: 12),
                                  ),
                              ],
                            );
                          }
                          if (_hasMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : TextButton.icon(
                                        onPressed: _loadMore,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('আরও সংবাদ লোড করুন'),
                                      ),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  '— ${widget.category.name} বিভাগের সব সংবাদ দেখানো হয়েছে —',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
    );
  }
}
