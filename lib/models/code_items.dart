import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'code_item.g.dart';

@HiveType(typeId: 0)
class CodeItem extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String type;       // 'qr' | 'barcode'
  @HiveField(2) late String subtype;    // 'url','wifi','sms', 'code128', etc.
  @HiveField(3) late String data;       // encoded string
  @HiveField(4) late String label;      // human-readable label
  @HiveField(5) late DateTime createdAt;
  @HiveField(6) late bool isFavorite;
  @HiveField(7) late bool isGenerated;  // false = scanned
  @HiveField(8) String? imagePath;

  CodeItem({
    required this.type,
    required this.subtype,
    required this.data,
    required this.label,
    required this.isGenerated,
    this.imagePath,
  }) {
    id = const Uuid().v4();
    createdAt = DateTime.now();
    isFavorite = false;
  }
}