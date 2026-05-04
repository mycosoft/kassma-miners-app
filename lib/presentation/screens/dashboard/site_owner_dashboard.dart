import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class SiteOwnerDashboard extends StatefulWidget {
  const SiteOwnerDashboard({super.key});

  @override
  State<SiteOwnerDashboard> createState() => _SiteOwnerDashboardState();
}

class _SiteOwnerDashboardState extends State<SiteOwnerDashboard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final response = await ApiService.getSiteOwnerDashboard();
      final body = response.data;
      final payload = body is Map<String, dynamic> ? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body) : <String, dynamic>{};
      setState(() {
        _data = payload;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = _parseError(e);
        _loading = false;
      });
    }
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('403')) return 'Access denied. Check your role permissions.';
    if (e.toString().contains('401')) return 'Session expired. Please login again.';
    if (e.toString().contains('Connection')) return 'Network error. Check your connection.';
    return 'Failed to load dashboard. Pull to retry.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome Back,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('Site Owner!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _loading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                  : _error != null
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary),
                                const SizedBox(height: 12),
                                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildListDelegate([
                            _buildProductionStats(),
                            const SizedBox(height: 24),
                            _buildQuickActions(context),
                            const SizedBox(height: 24),
                            _buildLeachingTanks(),
                          ]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionStats() {
    final stats = [
      {'icon': Icons.precision_manufacturing, 'value': '${_data?['total_processed'] ?? 0}', 'label': 'Processed', 'color': AppTheme.primaryColor},
      {'icon': Icons.science, 'value': '${_data?['active_tanks'] ?? 0}', 'label': 'Tanks', 'color': AppTheme.success},
      {'icon': Icons.monetization_on, 'value': '${_data?['total_gold_grams'] ?? 0}g', 'label': 'Gold Output', 'color': AppTheme.warning},
      {'icon': Icons.water_drop, 'value': '${_data?['elution_processes'] ?? 0}', 'label': 'Elutions', 'color': AppTheme.primaryDark},
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 28),
                const Spacer(),
                Text(stat['value'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(stat['label'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.add_circle, 'label': 'New Process', 'color': AppTheme.primaryColor},
      {'icon': Icons.science, 'label': 'Tank Status', 'color': AppTheme.success},
      {'icon': Icons.receipt_long, 'label': 'View Receipts', 'color': AppTheme.primaryColor},
      {'icon': Icons.assessment, 'label': 'Reports', 'color': AppTheme.primaryDark},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: actions.map((action) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(action['label'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLeachingTanks() {
    final tanks = _data?['leaching_tanks'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Leaching Tanks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),
        if (tanks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No leaching tanks', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: tanks.take(3).toList().asMap().entries.map((entry) {
                final tank = entry.value as Map<String, dynamic>;
                final isLast = entry.key == (tanks.length > 3 ? 2 : tanks.length - 1);
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        child: const Icon(Icons.science, color: AppTheme.primaryColor),
                      ),
                      title: Text(tank['name'] ?? 'Tank', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Status: ${tank['status'] ?? 'Unknown'}'),
                      trailing: _buildStatusChip(tank['status'] ?? 'active'),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppTheme.success;
        break;
      case 'processing':
        color = AppTheme.primaryColor;
        break;
      case 'completed':
        color = AppTheme.primaryDark;
        break;
      default:
        color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
