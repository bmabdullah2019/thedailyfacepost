import 'package:flutter_test/flutter_test.dart';
import 'package:thedailyfacepost/models/category_model.dart';
import 'package:thedailyfacepost/models/news_post_model.dart';
import 'package:thedailyfacepost/widgets/html_article_renderer.dart';

void main() {
  group('Models & Post Extractor Tests', () {
    test('extractPostList handles both direct and nested lists safely', () {
      final directJson = {
        'success': true,
        'data': [
          {
            'id': 101,
            'title': 'টেস্ট সংবাদ শিরোনাম',
            'slug': 'test-news',
            'excerpt': 'সংবাদ সারাংশ',
            'thumbnail': 'https://example.com/img.jpg',
            'author': 'প্রতিবেদক',
            'category': {'name': 'জাতীয়', 'slug': 'national'},
            'bangla_date': 'আজ',
            'share_url': 'https://example.com/101'
          }
        ]
      };

      final posts = extractPostList(directJson);
      expect(posts.length, 1);
      expect(posts[0].id, 101);
      expect(posts[0].title, 'টেস্ট সংবাদ শিরোনাম');
      expect(posts[0].categoryName, 'জাতীয়');

      // Nested data test
      final nestedJson = {
        'success': true,
        'data': {
          'data': [
            {
              'id': 102,
              'title': 'দ্বিতীয় সংবাদ',
              'slug': 'test-news-2',
              'excerpt': 'সারাংশ ২',
              'thumbnail': '',
              'author': 'প্রতিবেদক',
              'category': {'name': 'খেলাধুলা'},
              'bangla_date': 'গতকাল',
              'share_url': 'https://example.com/102'
            }
          ]
        }
      };

      final nestedPosts = extractPostList(nestedJson);
      expect(nestedPosts.length, 1);
      expect(nestedPosts[0].id, 102);
      expect(nestedPosts[0].categoryName, 'খেলাধুলা');
    });

    test('decodeHtmlEntities decodes all common entities and Bengali punctuation', () {
      final input = '&quot;উদ্ধৃতি&quot; &amp; &nbsp; &#8216;একক&#8217; &#8220;দ্বৈত&#8221; &hellip;';
      final output = decodeHtmlEntities(input);
      expect(output.contains('&quot;'), false);
      expect(output.contains('&amp;'), false);
      expect(output.contains('&hellip;'), false);
      expect(output.contains('...'), true);
      expect(output.contains('&'), true);
    });

    test('CategoryModel deserializes correctly', () {
      final json = {'id': 5, 'name': 'বিনোদন', 'slug': 'entertainment'};
      final cat = CategoryModel.fromJson(json);
      expect(cat.id, 5);
      expect(cat.name, 'বিনোদন');
      expect(cat.slug, 'entertainment');
    });
  });
}