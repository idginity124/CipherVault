import 'package:hive/hive.dart';

part 'vault_entry.g.dart';

@HiveType(typeId: 0)
class VaultEntry extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String username;

  /// Şifreli (EncryptionService.encrypt sonucu)
  @HiveField(2)
  String password;

  @HiveField(3)
  String url;

  @HiveField(4)
  String category;

  /// Şifreli (EncryptionService.encrypt sonucu)
  @HiveField(5)
  String notes;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  VaultEntry({
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.category,
    required this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  VaultEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? category,
    String? notes,
    DateTime? updatedAt,
  }) {
    return VaultEntry(
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'username': username,
    'password': password,
    'url': url,
    'category': category,
    'notes': notes,
  };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
    title: (json['title'] ?? 'Adsız').toString(),
    username: (json['username'] ?? '').toString(),
    password: (json['password'] ?? '').toString(),
    url: (json['url'] ?? '').toString(),
    category: (json['category'] ?? 'Genel').toString(),
    notes: (json['notes'] ?? '').toString(),
  );
}
