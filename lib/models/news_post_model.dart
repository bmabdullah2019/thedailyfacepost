class NewsPostModel {
  final int id;
  final String title;
  final String slug;
  final String excerpt;
  final String thumbnail;
  final String author;
  final String categoryName;
  final String categorySlug;
  final String banglaDate;
  final String shareUrl;
  final String? content;

  NewsPostModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.thumbnail,
    required this.author,
    required this.categoryName,
    this.categorySlug = '',
    required this.banglaDate,
    required this.shareUrl,
    this.content,
  });

  factory NewsPostModel.fromJson(Map<String, dynamic> json) {
    String catName = 'জাতীয়';
    String catSlug = '';
    if (json['category'] != null && json['category'] is Map) {
      catName = json['category']['name'] ?? 'জাতীয়';
      catSlug = json['category']['slug'] ?? '';
    }
    return NewsPostModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt'] ?? '',
      thumbnail: json['thumbnail'] ?? (json['og_image'] ?? ''),
      author: json['author'] ?? 'নিজস্ব প্রতিবেদক',
      categoryName: catName,
      categorySlug: catSlug,
      banglaDate: json['bangla_date'] ?? 'আজ',
      shareUrl: json['share_url'] ?? 'https://thedailyfacepost.com',
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'excerpt': excerpt,
    'thumbnail': thumbnail,
    'author': author,
    'category': {'name': categoryName, 'slug': categorySlug},
    'bangla_date': banglaDate,
    'share_url': shareUrl,
    if (content != null) 'content': content,
  };
}

List<NewsPostModel> extractPostList(dynamic body) {
  if (body == null) return [];
  List<dynamic> list = [];
  if (body is Map<String, dynamic>) {
    final d = body['data'];
    if (d is List) {
      list = d;
    } else if (d is Map<String, dynamic> && d['data'] is List) {
      list = d['data'] as List;
    }
  } else if (body is List) {
    list = body;
  }
  return list
      .whereType<Map<String, dynamic>>()
      .map((e) => NewsPostModel.fromJson(e))
      .toList();
}