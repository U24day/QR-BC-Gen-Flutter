import 'package:flutter/material.dart';
import '../../models/code_item.dart';
import '../../main.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistState();
}

class _HistState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CodeItem> get _items {
    List<CodeItem> list = switch (_tab.index) {
      1 => historyService.getGenerated(),
      2 => historyService.getScanned(),
      _ => historyService.getAll(),
    };
    if (_q.isNotEmpty) {
      list = list.where((e) =>
      e.label.toLowerCase().contains(_q.toLowerCase()) ||
          e.data.toLowerCase().contains(_q.toLowerCase())).toList();
    }
    return list;
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete All'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await historyService.deleteAll();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Column(children: [
      // Tabs
      Container(
        color: const Color(0xFF1A3C6E),
        child: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Generated'),
            Tab(text: 'Scanned'),
          ],
        ),
      ),

      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search history…',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            suffixIcon: _q.isNotEmpty
                ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _q = '');
                })
                : null,
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),

      // Delete all row
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_items.length} item${_items.length == 1 ? "" : "s"}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 18),
              label: const Text('Delete All',
                  style: TextStyle(color: Colors.red, fontSize: 13)),
              onPressed: _confirmDeleteAll,
            ),
          ],
        ),
      ),

      // List
      Expanded(
        child: _items.isEmpty
            ? const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text('No history yet',
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
            ]))
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final item = _items[i];
            return Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) async {
                await historyService.delete(item);
                setState(() {});
              },
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A3C6E).withValues(alpha: 0.1),
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
                    icon: Icon(
                        item.isFavorite
                            ? Icons.star : Icons.star_border,
                        color: item.isFavorite
                            ? Colors.amber : Colors.grey),
                    onPressed: () async {
                      await historyService.toggleFavorite(item);
                      setState(() {});
                    },
                  ),
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