import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _safeLaunch(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

void openFullScreenImageViewer(BuildContext context, String imageUrl, {String title = ''}) {
  if (imageUrl.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            title.isNotEmpty ? title : 'ছবি',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => Share.share(imageUrl),
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 5.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child: Text('ছবি লোড করা সম্ভব হয়নি', style: TextStyle(color: Colors.white70)),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
            ),
          ),
        ),
      ),
    ),
  );
}

String decodeHtmlEntities(String input) {
  var text = input;
  text = text.replaceAll('&nbsp;', ' ');
  text = text.replaceAll('&amp;', '&');
  text = text.replaceAll('&quot;', '"');
  text = text.replaceAll('&#039;', "'");
  text = text.replaceAll('&#39;', "'");
  text = text.replaceAll('&lt;', '<');
  text = text.replaceAll('&gt;', '>');
  text = text.replaceAll('&ldquo;', '"');
  text = text.replaceAll('&rdquo;', '"');
  text = text.replaceAll('&#8220;', '"');
  text = text.replaceAll('&#8221;', '"');
  text = text.replaceAll('&lsquo;', "'");
  text = text.replaceAll('&rsquo;', "'");
  text = text.replaceAll('&#8216;', "'");
  text = text.replaceAll('&#8217;', "'");
  text = text.replaceAll('&hellip;', '...');
  text = text.replaceAll('&#8230;', '...');
  text = text.replaceAll('&mdash;', '—');
  text = text.replaceAll('&#8212;', '—');
  text = text.replaceAll('&ndash;', '–');
  text = text.replaceAll('&#8211;', '–');

  text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    try {
      final code = int.parse(match.group(1)!);
      return String.fromCharCode(code);
    } catch (_) {
      return match.group(0)!;
    }
  });

  text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
    try {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    } catch (_) {
      return match.group(0)!;
    }
  });

  return text;
}

class HtmlArticleRenderer extends StatelessWidget {
  final String html;
  final double fontScale;
  final bool isDark;

  const HtmlArticleRenderer({
    super.key,
    required this.html,
    required this.fontScale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _parseHtml(html);
    if (blocks.isEmpty) {
      return Text(
        decodeHtmlEntities(html),
        style: TextStyle(
          fontSize: 16 * fontScale,
          height: 1.8,
          color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) => _buildBlock(context, b)).toList(),
    );
  }

  List<_HtmlBlock> _parseHtml(String raw) {
    final list = <_HtmlBlock>[];
    if (raw.trim().isEmpty) return list;

    final regex = RegExp(
      r'<(h[1-6]|p|div|li|blockquote|pre)[^>]*>(.*?)</\1>|<img[^>]+src=["'']([^"'']+)["''][^>]*>',
      dotAll: true,
      caseSensitive: false,
    );

    final matches = regex.allMatches(raw);
    if (matches.isEmpty) {
      final paragraphs = raw.split(RegExp(r'\n{2,}'));
      for (final p in paragraphs) {
        final clean = decodeHtmlEntities(p).trim();
        if (clean.isNotEmpty) {
          list.add(_HtmlBlock(type: 'p', text: clean));
        }
      }
      return list;
    }

    for (final m in matches) {
      final tag = m.group(1)?.toLowerCase();
      final content = m.group(2);
      final imgSrc = m.group(3);

      if (imgSrc != null && imgSrc.isNotEmpty) {
        list.add(_HtmlBlock(type: 'img', url: imgSrc));
      } else if (tag != null && content != null) {
        final innerImgMatch = RegExp(r'<img[^>]+src=["'']([^"'']+)["''][^>]*>', caseSensitive: false).firstMatch(content);
        if (innerImgMatch != null) {
          final src = innerImgMatch.group(1);
          if (src != null && src.isNotEmpty) {
            list.add(_HtmlBlock(type: 'img', url: src));
          }
        }

        final linkMatch = RegExp(r'<a[^>]+href=["'']([^"'']+)["''][^>]*>(.*?)</a>', dotAll: true, caseSensitive: false).firstMatch(content);
        String? linkUrl;
        String? linkText;
        if (linkMatch != null) {
          linkUrl = linkMatch.group(1);
          linkText = _stripTags(linkMatch.group(2) ?? '');
        }

        final cleanText = _stripTags(content);
        if (cleanText.isNotEmpty) {
          list.add(_HtmlBlock(
            type: tag,
            text: cleanText,
            url: linkUrl,
            linkText: linkText,
          ));
        }
      }
    }
    return list;
  }

  String _stripTags(String s) {
    return decodeHtmlEntities(s.replaceAll(RegExp(r'<[^>]*>'), ' ')).replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }

  Widget _buildBlock(BuildContext context, _HtmlBlock b) {
    final textColor = isDark ? Colors.grey.shade300 : const Color(0xFF334155);

    if (b.type == 'img' && b.url != null && b.url!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: GestureDetector(
          onTap: () => openFullScreenImageViewer(context, b.url!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              b.url!,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    if (b.type.startsWith('h')) {
      double hSize = 20;
      if (b.type == 'h1') hSize = 22;
      if (b.type == 'h2') hSize = 21;
      if (b.type == 'h3') hSize = 19;
      if (b.type == 'h4' || b.type == 'h5' || b.type == 'h6') hSize = 18;

      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          b.text,
          style: TextStyle(
            fontSize: hSize * fontScale,
            fontWeight: FontWeight.bold,
            height: 1.4,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      );
    }

    if (b.type == 'blockquote') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          border: const Border(left: BorderSide(color: Color(0xFF0284C7), width: 4)),
          borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
        ),
        child: Text(
          b.text,
          style: TextStyle(
            fontSize: 15 * fontScale,
            fontStyle: FontStyle.italic,
            height: 1.6,
            color: textColor,
          ),
        ),
      );
    }

    if (b.type == 'li') {
      return Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(fontSize: 16 * fontScale, color: const Color(0xFF0284C7), fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(
                b.text,
                style: TextStyle(fontSize: 15.5 * fontScale, height: 1.65, color: textColor),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            b.text,
            style: TextStyle(
              fontSize: 16 * fontScale,
              height: 1.75,
              color: textColor,
            ),
          ),
          if (b.url != null && b.url!.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _safeLaunch(b.url!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      b.linkText != null && b.linkText!.isNotEmpty ? b.linkText! : b.url!,
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HtmlBlock {
  final String type;
  final String text;
  final String? url;
  final String? linkText;

  _HtmlBlock({required this.type, this.text = '', this.url, this.linkText});
}
