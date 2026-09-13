import 'dart:math';

class Customer {
  final String id;
  final String name;

  const Customer({required this.id, required this.name});

  factory Customer.fromJson(Map<String, dynamic> json) =>
      Customer(id: json['id'] as String, name: json['name'] as String);

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return name.substring(0, min(2, name.length)).toUpperCase();
  }
}
