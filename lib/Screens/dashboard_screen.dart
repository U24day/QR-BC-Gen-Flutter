import 'package:flutter/material.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // We listen to updates when history changes. 
    // Since Hive doesn't automatically trigger UI rebuilds here natively without ValueListenableBuilder,
    // we get current items. In a full app, we'd use Hive listener or provider. 
    // But since it's a dashboard, getting values on build is a start.
    final generatedCount = historyService.getGenerated().length;
    final scannedCount = historyService.getScanned().length;
    final favCount = historyService.getFavorites().length;
    final recentItems = historyService.getAll().take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Stats
          _buildStatsRow(generatedCount, scannedCount, favCount),
          const SizedBox(height: 24),

          // Quick Actions
          const Text('Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildQuickActions(context),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (recentItems.isNotEmpty)
                TextButton(
                  onPressed: () => widget.onNavigate(3), // Navigate to History tab
                  child: const Text('View All'),
                )
            ],
          ),
          const SizedBox(height: 8),
          
          if (recentItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text('No activity yet', 
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = recentItems[index];
                return Card(
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
                            ' · ${item.subtype}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: Icon(
                          item.isFavorite
                              ? Icons.star : Icons.star_border,
                          color: item.isFavorite
                              ? Colors.amber : Colors.grey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int gen, int scan, int fav) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Generated', gen.toString(), Icons.add_box, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Scanned', scan.toString(), Icons.qr_code_scanner, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Favorites', fav.toString(), Icons.star, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(count,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Generate',
            icon: Icons.qr_code_2,
            color: const Color(0xFF1A3C6E),
            onTap: () => widget.onNavigate(1), // Navigate to Generate tab
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            title: 'Scan',
            icon: Icons.document_scanner,
            color: const Color(0xFF2558A8),
            onTap: () => widget.onNavigate(2), // Navigate to Scan tab
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
