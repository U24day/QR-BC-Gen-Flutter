import 'package:flutter/material.dart';
import '../../models/code_item.dart';
import '../../main.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavState();
}

class _FavState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext ctx) {
    final items = historyService.getFavorites();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 8),
          Text(
            '${items.length} favorite${items.length == 1 ? "" : "s"}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                color: Color(0xFF1A3C6E)),
          ),
        ]),
      ),

      Expanded(
        child: items.isEmpty
            ? const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star_outline, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text('No favorites yet',
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
              SizedBox(height: 6),
              Text('Tap the ★ on any history item to save it here.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center),
            ]))
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final item = items[i];
            return Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A3C6E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                      item.type == 'qr'
                          ? Icons.qr_code
                          : Icons.barcode_reader,
                      color: const Color(0xFF1A3C6E), size: 22),
                ),
                title: Text(item.label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(
                    '${item.isGenerated ? "Generated" : "Scanned"}'
                        ' · ${item.subtype} · ${_fmt(item.createdAt)}',
                    style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.star_rounded,
                      color: Colors.amber),
                  onPressed: () async {
                    await historyService.toggleFavorite(item);
                    setState(() {});
                  },
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  String _fmt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}