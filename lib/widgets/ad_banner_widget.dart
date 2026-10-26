import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AdBannerWidget extends StatefulWidget {
  final String? adCode;
  final String placement;
  final double? height;
  final EdgeInsetsGeometry margin;

  const AdBannerWidget({
    super.key,
    this.adCode,
    this.placement = 'above_content',
    this.height,
    this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  String? _imageUrl;
  String? _clickUrl;
  bool _isLoading = true;
  bool _isDismissed = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void didUpdateWidget(AdBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adCode != oldWidget.adCode) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final rawCode = widget.adCode ?? '';
    if (rawCode.trim().isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Check if direct image & link are present in the HTML
      final directLinkMatch = RegExp(r"<a[^>]+href=['\x22]([^'\x22]+)['\x22]").firstMatch(rawCode);
      final directImgMatch = RegExp(r"<img[^>]+src=['\x22]([^'\x22]+)['\x22]").firstMatch(rawCode);

      if (directImgMatch != null) {
        if (mounted) {
          setState(() {
            _imageUrl = directImgMatch.group(1);
            _clickUrl = directLinkMatch?.group(1);
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Check if it's the AdsMarketsBD / Adsterra publisher script format
      final pubMatch = RegExp(r'data-publisher=["\x27]([^"\x27]+)["\x27]').firstMatch(rawCode);
      final sizeMatch = RegExp(r'data-adsize=["\x27]([^"\x27]+)["\x27]').firstMatch(rawCode);

      if (pubMatch != null && sizeMatch != null) {
        final publisher = pubMatch.group(1)!;
        final size = sizeMatch.group(1)!;
        final endpoint = 'https://adsmarketsbd.com/ads/$publisher/$size/thedailyfacepost.com';

        final res = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final linkMatch = RegExp(r"<a[^>]+href=['\x22]([^'\x22]+)['\x22]").firstMatch(res.body);
          final imgMatch = RegExp(r"<img[^>]+src=['\x22]([^'\x22]+)['\x22]").firstMatch(res.body);

          if (imgMatch != null) {
            if (mounted) {
              setState(() {
                _imageUrl = imgMatch.group(1);
                _clickUrl = linkMatch?.group(1);
                _isLoading = false;
              });
            }
            return;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _handleClick() async {
    if (_clickUrl == null || _clickUrl!.isEmpty) return;
    try {
      final uri = Uri.parse(_clickUrl!);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || _hasError || (_imageUrl == null && !_isLoading)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        margin: widget.margin,
        height: widget.height ?? 80,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ad label bar with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'বিজ্ঞাপন',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sponsored',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => setState(() => _isDismissed = true),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          // Ad banner image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
            child: InkWell(
              onTap: _handleClick,
              child: Image.network(
                _imageUrl!,
                fit: BoxFit.fitWidth,
                width: double.infinity,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: widget.height ?? 80,
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                    child: const Center(
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}