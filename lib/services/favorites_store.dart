import 'package:flutter/foundation.dart';
import '../models/customer.dart';

class FavoriteEntry {
  final Customer customer;
  final int colorIndex;
  const FavoriteEntry({required this.customer, required this.colorIndex});
}

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();
  static final instance = FavoritesStore._();

  final _entries = <String, FavoriteEntry>{};

  List<FavoriteEntry> get favorites => _entries.values.toList();
  bool isFavorite(String id) => _entries.containsKey(id);

  void toggle(String id, String name, int colorIndex) {
    if (_entries.containsKey(id)) {
      _entries.remove(id);
    } else {
      _entries[id] = FavoriteEntry(
        customer: Customer(id: id, name: name),
        colorIndex: colorIndex,
      );
    }
    notifyListeners();
  }
}
