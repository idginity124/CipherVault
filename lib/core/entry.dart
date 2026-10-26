import 'dart:convert';
import 'dart:math';

String newId() => base64UrlEncode(
  List<int>.generate(18, (_) => Random.secure().nextInt(256)),
);

class Entry {
  final String id, title, username, password, url, category, notes;
  final DateTime createdAt, updatedAt;
  Entry({
    String? id,
    required this.title,
    required this.username,
    required this.password,
    this.url = '',
    this.category = 'Genel',
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? newId(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'username': username,
    'password': password,
    'url': url,
    'category': category,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
  factory Entry.fromJson(Map<String, dynamic> m) {
    String value(String k, [String fallback = '']) {
      final v = m[k];
      if (v == null) return fallback;
      if (v is! String || v.length > 100000) {
        throw const FormatException('Geçersiz kayıt.');
      }
      return v;
    }

    return Entry(
      id: value('id', newId()),
      title: value('title'),
      username: value('username'),
      password: value('password'),
      url: value('url'),
      category: value('category', 'Genel'),
      notes: value('notes'),
      createdAt: DateTime.tryParse(value('created_at')),
      updatedAt: DateTime.tryParse(value('updated_at')),
    );
  }
}
