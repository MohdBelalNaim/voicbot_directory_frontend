import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiStore extends ChangeNotifier {
  String _apiUrl = dotenv.env['BASE_URL'] ?? '';

  String get apiUrl => _apiUrl;

  updateApiUrl(String newApiUrl) {
    _apiUrl = newApiUrl;
    notifyListeners();
  }
}
