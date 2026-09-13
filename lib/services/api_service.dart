import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';

class ApiService {
  // Use http://10.0.2.2:8000 on Android emulator instead of localhost
  static const String baseUrl = 'http://192.168.1.209:8000';

  static List<Customer>? _cache;

  static Future<List<Customer>> fetchCustomers() async {
    if (_cache != null) return _cache!;
    final response = await http.get(Uri.parse('$baseUrl/customers'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _cache = data
          .map((j) => Customer.fromJson(j as Map<String, dynamic>))
          .toList();
      return _cache!;
    }
    throw Exception('Failed to load customers (${response.statusCode})');
  }

  static Stream<String> streamChat(String companyId, String query) async* {
    final client = http.Client();
    try {
      final uri = Uri.parse('$baseUrl/chat').replace(
        queryParameters: {'company_id': companyId, 'query': query},
      );
      final response = await client.send(http.Request('GET', uri));
      if (response.statusCode != 200) {
        throw Exception('Chat failed (${response.statusCode})');
      }
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    } finally {
      client.close();
    }
  }
}
