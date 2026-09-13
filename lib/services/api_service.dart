import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:voicebot_directory/store/api_store.dart';
import '../models/customer.dart';

class ApiService {
  final ApiStore apiStore;

  ApiService(this.apiStore);

  String get baseUrl => apiStore.apiUrl;

  static final Map<String, List<Customer>> _cache = {};

  Future<List<Customer>> fetchCustomers() async {
    final url = baseUrl;

    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    final response = await http
        .get(Uri.parse('$url/customers'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final customers = data
          .map((j) => Customer.fromJson(j as Map<String, dynamic>))
          .toList();

      _cache[url] = customers;

      return customers;
    }
    throw Exception('Failed to load customers (${response.statusCode})');
  }

  Stream<String> streamChat(String companyId, String query) async* {
    final client = http.Client();
    try {
      final uri = Uri.parse('$baseUrl/chat').replace(
        queryParameters: {'company_id': companyId, 'query': query},
      );
      final response = await client
          .send(http.Request('GET', uri))
          .timeout(const Duration(seconds: 5));
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
