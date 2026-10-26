import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/category_model.dart';
import 'models/news_post_model.dart';
import 'widgets/news_card_widget.dart';
// html_article_renderer
import 'screens/article_detail_screen.dart';
import 'screens/category_news_screen.dart';
import 'widgets/ad_banner_widget.dart';

// Re-export for any existing references
export 'models/category_model.dart';
export 'models/news_post_model.dart';
export 'widgets/news_card_widget.dart';
export 'widgets/html_article_renderer.dart';
export 'screens/article_detail_screen.dart';
export 'screens/category_news_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const DailyFaceApp());
}

Future<void> _safeLaunchUrl(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

Future<void> _makePhoneCall(String phoneNumber) async {
  final uri = Uri.parse('tel:$phoneNumber');
  try {
    await launchUrl(uri);
  } catch (_) {}
}

Future<void> _sendEmail(String email) async {
  final uri = Uri.parse('mailto:$email');
  try {
    await launchUrl(uri);
  } catch (_) {}
}

// ---------------- APP ROOT ----------------
class DailyFaceApp extends StatefulWidget {
  const DailyFaceApp({super.key});

  @override
  State<DailyFaceApp> createState() => _DailyFaceAppState();
}

class _DailyFaceAppState extends State<DailyFaceApp> {
  bool _isDarkMode = false;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _fontScale = prefs.getDouble('fontScale') ?? 1.0;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _setFontScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontScale', value);
    setState(() {
      _fontScale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Daily Face Post',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0F172A),
          secondary: Color(0xFF0284C7),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0.5,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1120),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF0284C7),
          surface: Color(0xFF131D31),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131D31),
          foregroundColor: Colors.white,
          elevation: 0.5,
        ),
      ),
      home: MainNavigationScreen(
        isDarkMode: _isDarkMode,
        fontScale: _fontScale,
        onThemeChanged: _toggleTheme,
        onFontScaleChanged: _setFontScale,
      ),
    );
  }
}

// ---------------- MAIN NAVIGATION ----------------
class MainNavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final double fontScale;
  final Function(bool) onThemeChanged;
  final Function(double) onFontScaleChanged;

  const MainNavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.fontScale,
    required this.onThemeChanged,
    required this.onFontScaleChanged,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _selectedCategorySlug = '';
  List<CategoryModel> _sharedCategories = [];

  void _onCategorySelectedFromDrawer(String slug) {
    setState(() {
      _selectedCategorySlug = slug;
      _currentIndex = 0;
    });
  }

  void _onCategoriesLoaded(List<CategoryModel> cats) {
    if (_sharedCategories.isEmpty && cats.isNotEmpty) {
      setState(() {
        _sharedCategories = cats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        isDarkMode: widget.isDarkMode,
        fontScale: widget.fontScale,
        onCategorySelect: _onCategorySelectedFromDrawer,
        initialCategorySlug: _selectedCategorySlug,
        onCategoriesFetched: _onCategoriesLoaded,
      ),
      CategoriesScreen(
        fontScale: widget.fontScale,
        categories: _sharedCategories,
      ),
      BookmarksScreen(fontScale: widget.fontScale),
      SettingsScreen(
        isDarkMode: widget.isDarkMode,
        fontScale: widget.fontScale,
        onThemeChanged: widget.onThemeChanged,
        onFontScaleChanged: widget.onFontScaleChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0284C7),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper),
            label: 'হোম',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'ক্যাটাগরি',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'বুকমার্কস',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'সেটিংস',
          ),
        ],
      ),
    );
  }
}

// ---------------- HOME SCREEN ----------------
// Solves:
// 1. Pagination past 10 news (automatic infinite scroll & "আরও খবর দেখুন" button)
// 2. Category selection bug (fixed JSON parsing & state updates)
class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final double fontScale;
  final Function(String) onCategorySelect;
  final String initialCategorySlug;
  final Function(List<CategoryModel>)? onCategoriesFetched;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.fontScale,
    required this.onCategorySelect,
    this.initialCategorySlug = '',
    this.onCategoriesFetched,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  List<NewsPostModel> _breakingNews = [];
  List<NewsPostModel> _sliderNews = [];
  List<NewsPostModel> _latestNews = [];
  List<CategoryModel> _categories = [];
  String _selectedCategory = 'সব খবর';
  String _selectedCategorySlug = '';
  Map<String, String> _feedAds = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  int _currentCarouselIndex = 0;
  final PageController _pageController = PageController();
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialCategorySlug.isNotEmpty) {
      _filterCategoryBySlug(widget.initialCategorySlug);
    } else {
      _fetchFeed();
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategorySlug.isNotEmpty &&
        widget.initialCategorySlug != oldWidget.initialCategorySlug &&
        widget.initialCategorySlug != _selectedCategorySlug) {
      _filterCategoryBySlug(widget.initialCategorySlug);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreNews();
      }
    }
  }

  Future<void> _fetchFeed() async {
    setState(() {
      _isLoading = true;
      _selectedCategory = 'সব খবর';
      _selectedCategorySlug = '';
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final res = await http.get(Uri.parse('https://thedailyfacepost.com/api/v1/feed'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        final cats = (data['categories'] as List?)
                ?.map((e) => CategoryModel.fromJson(e))
                .toList() ??
            [];

        final adsList = data['ads'] as List?;
        final adsMap = <String, String>{};
        if (adsList != null) {
          for (final a in adsList) {
            if (a is Map) {
              final placement = a['placement']?.toString() ?? '';
              final code = a['ad_code']?.toString() ?? '';
              if (placement.isNotEmpty && code.isNotEmpty) {
                adsMap[placement] = code;
              }
            }
          }
        }

        setState(() {
          _breakingNews = (data['breaking_news'] as List?)
                  ?.map((e) => NewsPostModel.fromJson(e))
                  .toList() ??
              [];
          _sliderNews = (data['slider_news'] as List?)
                  ?.map((e) => NewsPostModel.fromJson(e))
                  .toList() ??
              [];
          _latestNews = (data['latest_news'] as List?)
                  ?.map((e) => NewsPostModel.fromJson(e))
                  .toList() ??
              [];
          _categories = cats;
          _feedAds = adsMap;
          _isLoading = false;
          _hasMore = true;
        });

        if (widget.onCategoriesFetched != null) {
          widget.onCategoriesFetched!(cats);
        }

        if (_sliderNews.length > 1) {
          _startCarouselTimer();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _sliderNews.isNotEmpty) {
        final nextPage = (_currentCarouselIndex + 1) % _sliderNews.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _filterCategoryBySlug(String slug) {
    String name = slug;
    for (final c in _categories) {
      if (c.slug == slug) {
        name = c.name;
        break;
      }
    }
    _filterCategory(name, slug);
  }

  Future<void> _filterCategory(String name, String slug) async {
    setState(() {
      _selectedCategory = name;
      _selectedCategorySlug = slug;
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    if (name == 'সব খবর' || slug.isEmpty) {
      _fetchFeed();
      return;
    }

    try {
      final url = 'https://thedailyfacepost.com/api/v1/posts?category_slug=${Uri.encodeComponent(slug)}&page=1';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = extractPostList(body);
        final meta = body is Map ? (body['meta'] ?? {}) : {};
        final lastPage = meta is Map ? (meta['last_page'] ?? 1) : 1;

        setState(() {
          _latestNews = list;
          _isLoading = false;
          _hasMore = list.isNotEmpty && lastPage > 1;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final String url;
      if (_selectedCategorySlug.isEmpty || _selectedCategory == 'সব খবর') {
        url = 'https://thedailyfacepost.com/api/v1/posts?page=$nextPage';
      } else {
        url = 'https://thedailyfacepost.com/api/v1/posts?category_slug=${Uri.encodeComponent(_selectedCategorySlug)}&page=$nextPage';
      }

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = extractPostList(body);
        final meta = body is Map ? (body['meta'] ?? {}) : {};
        final lastPage = meta is Map ? (meta['last_page'] ?? nextPage) : nextPage;

        setState(() {
          _latestNews.addAll(list);
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

  String _getBengaliCurrentDate() {
    final now = DateTime.now();
    const days = ['রবিবার', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার'];
    const months = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
    const nums = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

    String convertNum(int n) {
      return n.toString().split('').map((c) {
        int idx = int.tryParse(c) ?? 0;
        return nums[idx];
      }).join('');
    }

    String day = days[now.weekday % 7];
    String date = convertNum(now.day);
    String month = months[now.month - 1];
    String year = convertNum(now.year);

    return '$day, $date $month $year';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: AppDrawer(
        categories: _categories,
        isDarkMode: widget.isDarkMode,
        onCategorySelect: (name, slug) {
          Navigator.pop(context);
          _filterCategory(name, slug);
        },
      ),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            ),
            child: const Text(
              'THE DAILY FACE POST',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.6,
                color: Color(0xFF0284C7),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchScreen(categories: _categories)),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (_selectedCategory == 'সব খবর') {
                  await _fetchFeed();
                } else {
                  await _filterCategory(_selectedCategory, _selectedCategorySlug);
                }
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bengali Date Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Text(
                            _getBengaliCurrentDate(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Breaking News Ticker Bar
                    if (_breakingNews.isNotEmpty && _selectedCategory == 'সব খবর')
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2D1515) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, color: Colors.white, size: 14),
                                  SizedBox(width: 2),
                                  Text(
                                    'ব্রেকিং',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ArticleDetailScreen(post: _breakingNews.first, fontScale: widget.fontScale),
                                    ),
                                  );
                                },
                                child: Text(
                                  _breakingNews.first.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey.shade300 : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Ad: Above Content Banner
                    if (_feedAds['above_content'] != null && _feedAds['above_content']!.isNotEmpty)
                      AdBannerWidget(adCode: _feedAds['above_content']!, placement: 'above_content'),

                    const SizedBox(height: 10),

                    // Featured Slider Carousel (only on 'সব খবর')
                    if (_sliderNews.isNotEmpty && _selectedCategory == 'সব খবর') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'প্রধান খবর',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _sliderNews.length,
                          onPageChanged: (idx) {
                            setState(() => _currentCarouselIndex = idx);
                          },
                          itemBuilder: (context, index) {
                            final post = _sliderNews[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArticleDetailScreen(post: post, fontScale: widget.fontScale),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        post.thumbnail,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(color: Colors.grey.shade300),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.85),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        left: 14,
                                        right: 14,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0284C7),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    post.categoryName,
                                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.access_time, size: 12, color: Colors.white70),
                                                const SizedBox(width: 4),
                                                Text(
                                                  post.banglaDate,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              post.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16 * widget.fontScale,
                                                fontWeight: FontWeight.bold,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _sliderNews.length,
                          (idx) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                            width: _currentCarouselIndex == idx ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentCarouselIndex == idx
                                  ? const Color(0xFF0284C7)
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Category Filter Pills (Horizontal Scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _buildCategoryPill('সব খবর', ''),
                          ..._categories.map((c) => _buildCategoryPill(c.name, c.slug)),
                        ],
                      ),
                    ),

                    // Active Category Filter Indicator
                    if (_selectedCategory != 'সব খবর')
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.filter_alt, size: 16, color: Color(0xFF0284C7)),
                                const SizedBox(width: 6),
                                Text(
                                  'ক্যাটাগরি: $_selectedCategory',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _filterCategory('সব খবর', ''),
                              child: const Row(
                                children: [
                                  Icon(Icons.close, size: 16, color: Colors.grey),
                                  SizedBox(width: 2),
                                  Text('সব খবর', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Section: Latest News Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedCategory == 'সব খবর' ? 'সর্বশেষ সংবাদ' : '$_selectedCategory বিভাগের সংবাদ',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '${_latestNews.length} টি সংবাদ লোড হয়েছে',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // News List View
                    if (_latestNews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'কোনো সংবাদ পাওয়া যায়নি',
                            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _latestNews.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemBuilder: (context, index) {
                          final post = _latestNews[index];
                          final inContentAd = _feedAds['in_content'] ?? _feedAds['sidebar'];
                          final showAd = inContentAd != null && inContentAd.isNotEmpty && (index == 2 || index == 7);

                          return Column(
                            children: [
                              NewsCardWidget(
                                post: post,
                                fontScale: widget.fontScale,
                              ),
                              if (showAd)
                                AdBannerWidget(
                                  adCode: inContentAd,
                                  placement: 'in_content',
                                  margin: const EdgeInsets.only(bottom: 12),
                                ),
                            ],
                          );
                        },
                      ),

                    // Ad: Below Content Banner
                    if (_feedAds['below_content'] != null && _feedAds['below_content']!.isNotEmpty)
                      AdBannerWidget(adCode: _feedAds['below_content']!, placement: 'below_content'),

                    // Load More Controls (Infinite scroll trigger / Button)
                    if (_hasMore && _latestNews.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Center(
                          child: _isLoadingMore
                              ? const CircularProgressIndicator()
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  ),
                                  onPressed: _loadMoreNews,
                                  icon: const Icon(Icons.arrow_downward, size: 16),
                                  label: const Text('আরও খবর দেখুন (পরবর্তী পৃষ্ঠা)', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                        ),
                      )
                    else if (_latestNews.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            '— সব সংবাদ লোড করা হয়েছে —',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryPill(String name, String slug) {
    final isSelected = _selectedCategory == name;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (_) => _filterCategory(name, slug),
        showCheckmark: false,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedColor: const Color(0xFF0F172A),
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.grey.shade300 : const Color(0xFF334155)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF0F172A)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}

// ---------------- DRAWER ----------------
class AppDrawer extends StatelessWidget {
  final List<CategoryModel> categories;
  final bool isDarkMode;
  final Function(String, String) onCategorySelect;

  const AppDrawer({
    super.key,
    required this.categories,
    required this.isDarkMode,
    required this.onCategorySelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header with Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A192F), Color(0xFF1E3A8A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'THE DAILY FACE POST',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'সত্যের সন্ধানে নির্ভীক অনলাইন দৈনিক',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Quick Navigation: Contact & Policy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.contact_support_outlined, size: 20, color: Color(0xFF0284C7)),
                    title: const Text('যোগাযোগ (Contact Us)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Categories Subheader
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ক্যাটাগরিসমূহ',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Category List
            Expanded(
              child: categories.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.label_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                          title: Text(cat.name, style: const TextStyle(fontSize: 14)),
                          trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          onTap: () => onCategorySelect(cat.name, cat.slug),
                        );
                      },
                    ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    'The Daily Face Post v1.0.4',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '© 2026 All Rights Reserved',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- CATEGORIES SCREEN (Tab 2) ----------------
// Solves:
// When clicking any category, opens CategoryNewsScreen dedicated view
class CategoriesScreen extends StatefulWidget {
  final double fontScale;
  final List<CategoryModel> categories;

  const CategoriesScreen({
    super.key,
    required this.fontScale,
    this.categories = const [],
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> _cats = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _cats = widget.categories;
    } else {
      _loadCategories();
    }
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories.isNotEmpty && _cats.isEmpty) {
      setState(() {
        _cats = widget.categories;
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('https://thedailyfacepost.com/api/v1/feed'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        final list = (data['categories'] as List?)
                ?.map((e) => CategoryModel.fromJson(e))
                .toList() ??
            [];
        setState(() {
          _cats = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(String name) {
    if (name.contains('জাতীয়') || name.contains('জাতীয়')) return Icons.flag_outlined;
    if (name.contains('রাজনীতি')) return Icons.account_balance_outlined;
    if (name.contains('খেলা')) return Icons.sports_soccer_outlined;
    if (name.contains('আন্তর্জাতিক')) return Icons.public_outlined;
    if (name.contains('অর্থনীতি')) return Icons.trending_up;
    if (name.contains('বিনোদন')) return Icons.movie_outlined;
    if (name.contains('সারাদেশ')) return Icons.map_outlined;
    if (name.contains('অপরাধ')) return Icons.gavel_outlined;
    if (name.contains('শিক্ষা')) return Icons.school_outlined;
    if (name.contains('চাকরি')) return Icons.work_outline;
    if (name.contains('প্রযুক্তি')) return Icons.devices_other;
    if (name.contains('স্বাস্থ্য')) return Icons.health_and_safety_outlined;
    if (name.contains('লাইফস্টাইল')) return Icons.style_outlined;
    if (name.contains('ধর্ম')) return Icons.mosque_outlined;
    return Icons.newspaper_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayList = _cats.isNotEmpty
        ? _cats
        : [
            CategoryModel(id: 1, name: 'জাতীয়', slug: 'জাতীয়'),
            CategoryModel(id: 2, name: 'খেলাধুলা', slug: 'খেলাধুলা'),
            CategoryModel(id: 3, name: 'আন্তর্জাতিক', slug: 'আন্তর্জাতিক'),
            CategoryModel(id: 4, name: 'অর্থনীতি', slug: 'অর্থনীতি'),
            CategoryModel(id: 5, name: 'রাজনীতি', slug: 'রাজনীতি'),
            CategoryModel(id: 6, name: 'বিনোদন', slug: 'বিনোদন'),
            CategoryModel(id: 7, name: 'সারাদেশ', slug: 'সারাদেশ'),
            CategoryModel(id: 8, name: 'অপরাধ', slug: 'অপরাধ'),
            CategoryModel(id: 9, name: 'শিক্ষাঅঙ্গন', slug: 'শিক্ষাঅঙ্গন'),
            CategoryModel(id: 10, name: 'চাকরি', slug: 'চাকরি'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ক্যাটাগরিসমূহ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: displayList.length,
              itemBuilder: (context, idx) {
                final cat = displayList[idx];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryNewsScreen(category: cat, fontScale: widget.fontScale),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D31) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getCategoryIcon(cat.name), size: 32, color: const Color(0xFF0284C7)),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- BOOKMARKS SCREEN ----------------
class BookmarksScreen extends StatefulWidget {
  final double fontScale;
  const BookmarksScreen({super.key, required this.fontScale});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<NewsPostModel> _savedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('saved_ids') ?? [];
    List<NewsPostModel> loaded = [];

    for (final id in ids) {
      final jsonStr = prefs.getString('saved_post_$id');
      if (jsonStr != null) {
        try {
          loaded.add(NewsPostModel.fromJson(json.decode(jsonStr)));
        } catch (_) {}
      }
    }

    setState(() {
      _savedPosts = loaded;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বুকমার্কস', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSaved,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 50, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('কোনো সংরক্ষিত সংবাদ নেই', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSaved,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _savedPosts.length,
                    itemBuilder: (context, idx) {
                      return NewsCardWidget(
                        post: _savedPosts[idx],
                        fontScale: widget.fontScale,
                      );
                    },
                  ),
                ),
    );
  }
}

// ---------------- SETTINGS SCREEN ----------------
class SettingsScreen extends StatelessWidget {
  final bool isDarkMode;
  final double fontScale;
  final Function(bool) onThemeChanged;
  final Function(double) onFontScaleChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.fontScale,
    required this.onThemeChanged,
    required this.onFontScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1 Header
            Text(
              'ডিসপ্লে ও থিম',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Display Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D31) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dark Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny_outlined, color: Color(0xFF0284C7), size: 22),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ডার্ক মোড', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                'অন্ধকারে সহজে পড়ার জন্য ডার্ক থিম',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: isDarkMode,
                        activeThumbColor: const Color(0xFF0284C7),
                        onChanged: onThemeChanged,
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Font Size Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.text_fields, color: Color(0xFF0284C7), size: 22),
                          SizedBox(width: 12),
                          Text('খবরের লেখার আকার (Font Size)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      Text('${(fontScale * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: fontScale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    activeColor: const Color(0xFF0284C7),
                    onChanged: onFontScaleChanged,
                  ),

                  // Sample Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'নমুনা: সত্য ও বস্তুনিষ্ঠ সংবাদ সবার আগে পৌঁছে দিতে দ্য ডেইলি ফেস পোস্ট অঙ্গীকারবদ্ধ।',
                      style: TextStyle(
                        fontSize: 13 * fontScale,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2 Header
            Text(
              'যোগাযোগ ও অ্যাপ তথ্য',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // About & Contact Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D31) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.headset_mic_outlined, color: Color(0xFF0284C7)),
                    title: const Text('যোগাযোগ করুন (Contact Us)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('+880 1626-076979 • info@thedailyfacepost.com', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.contact_mail_outlined, color: Color(0xFF0284C7)),
                    title: const Text('ওয়েবসাইটে যোগাযোগ পেজ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('https://thedailyfacepost.com/contact-us', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _safeLaunchUrl('https://thedailyfacepost.com/contact-us'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.policy_outlined, color: Color(0xFF0284C7)),
                    title: const Text('গোপনীয়তা নীতি (Privacy Policy)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('https://thedailyfacepost.com/privacy-policy', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _safeLaunchUrl('https://thedailyfacepost.com/privacy-policy'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language, color: Color(0xFF0284C7)),
                    title: const Text('ওয়েবসাইট ভিজিট করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('https://www.thedailyfacepost.com/', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _safeLaunchUrl('https://www.thedailyfacepost.com/'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.share_outlined, color: Color(0xFF0284C7)),
                    title: const Text('বন্ধুদের সাথে শেয়ার করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('অ্যাপের লিংক শেয়ার করুন', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Share.share('The Daily Face Post অফিসিয়াল অ্যাপ ডাউনলোড করুন: https://thedailyfacepost.com/app');
                    },
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFF0284C7)),
                    title: Text('অ্যাপ ভার্সন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('v1.0.4 (Build 6)', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // Footer Logo & Copyright
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                    ),
                    child: const Text(
                      'THE DAILY FACE POST',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The Daily Face Post • Online News Portal',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '© 2026 All Rights Reserved',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------- SEARCH SCREEN ----------------
// Solves: Fixed extractPostList JSON parsing bug
class SearchScreen extends StatefulWidget {
  final List<CategoryModel> categories;
  const SearchScreen({super.key, required this.categories});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<NewsPostModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  Future<void> _performSearch(String q) async {
    if (q.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final res = await http.get(Uri.parse('https://thedailyfacepost.com/api/v1/posts?search=${Uri.encodeComponent(q)}'));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = extractPostList(body);
        setState(() {
          _results = list;
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const popularTopics = ['জাতীয়', 'খেলাধুলা', 'আন্তর্জাতিক', 'বিনোদন', 'অপরাধ', 'সারাদেশ', 'রাজনীতি', 'অর্থনীতি', 'চাকরি'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'সংবাদ খুঁজুন...',
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_controller.text),
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _results.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _results.length,
                  itemBuilder: (context, idx) => NewsCardWidget(post: _results[idx], fontScale: 1.0),
                )
              : _hasSearched
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('কোনো ফলাফল পাওয়া যায়নি', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'জনপ্রিয় বিষয়সমূহ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: popularTopics.map((topic) {
                              return ActionChip(
                                label: Text(topic),
                                backgroundColor: Theme.of(context).cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                onPressed: () {
                                  _controller.text = topic;
                                  _performSearch(topic);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

// ---------------- CONTACT US SCREEN ----------------
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF131D31) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    const primaryBlue = Color(0xFF0284C7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('যোগাযোগ (Contact Us)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Branding Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A192F), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'THE DAILY FACE POST',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'সত্যের সন্ধানে নির্ভীক অনলাইন জাতীয় দৈনিক',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Official Contact & Editorial Information',
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Management & Editorial info
            Text(
              'সম্পাদকীয় ও প্রকাশনা তথ্য',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_pin, color: primaryBlue),
                    title: Text('সম্পাদক ও প্রকাশক', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('মো. শাহরিয়ার ইসলাম (Md. Shahriar Islam)', style: TextStyle(fontSize: 13)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.newspaper, color: primaryBlue),
                    title: Text('সংবাদ পোর্টাল', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('The Daily Face Post (দৈনিক ফেসপোস্ট)', style: TextStyle(fontSize: 13)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.location_on, color: primaryBlue),
                    title: Text('বার্তা ও বাণিজ্যিক কার্যালয়', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('ঢাকা, বাংলাদেশ (Dhaka, Bangladesh)', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Direct Contact channels
            Text(
              'সরাসরি যোগাযোগের মাধ্যম',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone_in_talk, color: Colors.green),
                    title: const Text('হটলাইন / ফোন নম্বর', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('+880 1626-076979', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('কল করুন', style: TextStyle(fontSize: 12)),
                      onPressed: () => _makePhoneCall('+8801626076979'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email, color: primaryBlue),
                    title: const Text('অফিসিয়াল ইমেইল (News & Editorial)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('info@thedailyfacepost.com', style: TextStyle(fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.send, color: primaryBlue, size: 20),
                      onPressed: () => _sendEmail('info@thedailyfacepost.com'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.alternate_email, color: primaryBlue),
                    title: const Text('বিকল্প ইমেইল (Developer / Management)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('thefacepostltd@gmail.com', style: TextStyle(fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.send, color: primaryBlue, size: 20),
                      onPressed: () => _sendEmail('thefacepostltd@gmail.com'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Official Web links
            Text(
              'অফিসিয়াল ওয়েব লিংক ও নীতিমালা',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.public, color: primaryBlue),
                    title: const Text('ওয়েবসাইটে যোগাযোগ পৃষ্ঠা (Web Contact Page)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('https://thedailyfacepost.com/contact-us', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _safeLaunchUrl('https://thedailyfacepost.com/contact-us'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: primaryBlue),
                    title: const Text('আমাদের সম্পর্কে (About Us)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('https://thedailyfacepost.com/about-us', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _safeLaunchUrl('https://thedailyfacepost.com/about-us'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: primaryBlue),
                    title: const Text('গোপনীয়তা নীতি (Privacy Policy)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('https://thedailyfacepost.com/privacy-policy', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _safeLaunchUrl('https://thedailyfacepost.com/privacy-policy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // App Version Compliant Note
            Center(
              child: Text(
                'The Daily Face Post • v1.0.4 (Build 6)\nGoogle Play Compliant News Application',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
