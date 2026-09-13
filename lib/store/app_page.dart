import 'package:flutter/foundation.dart';

class AppPage extends ChangeNotifier {
  int _index = 0;

  int get current => _index;

  setPage(int index) {
    _index = index;
    notifyListeners();
  }
}
