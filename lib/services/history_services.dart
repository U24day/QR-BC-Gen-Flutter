import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_item.dart';

class HistoryService {
  static const _boxName = 'history';
  late Box<CodeItem> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CodeItemAdapter());
    _box = await Hive.openBox<CodeItem>(_boxName);
  }

  List<CodeItem> getAll() => _box.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<CodeItem> getGenerated() =>
      getAll().where((e) => e.isGenerated).toList();

  List<CodeItem> getScanned() =>
      getAll().where((e) => !e.isGenerated).toList();

  List<CodeItem> getFavorites() =>
      getAll().where((e) => e.isFavorite).toList();

  List<CodeItem> search(String q) => getAll()
      .where((e) =>
  e.label.toLowerCase().contains(q.toLowerCase()) ||
      e.data.toLowerCase().contains(q.toLowerCase()))
      .toList();

  Future<void> add(CodeItem item) => _box.put(item.id, item);

  Future<void> toggleFavorite(CodeItem item) {
    item.isFavorite = !item.isFavorite;
    return item.save();
  }

  Future<void> delete(CodeItem item) => item.delete();
  Future<void> deleteAll() => _box.clear();

  Future<void> deleteGenerated() async {
    final keys = _box.values
        .where((e) => e.isGenerated).map((e) => e.key).toList();
    await _box.deleteAll(keys);
  }

  Future<void> deleteScanned() async {
    final keys = _box.values
        .where((e) => !e.isGenerated).map((e) => e.key).toList();
    await _box.deleteAll(keys);
  }
}