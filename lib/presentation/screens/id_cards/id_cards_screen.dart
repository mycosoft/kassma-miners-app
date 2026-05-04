import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import 'create_id_card_screen.dart';

class IdCardsScreen extends StatefulWidget {
  const IdCardsScreen({super.key});

  @override
  State<IdCardsScreen> createState() => _IdCardsScreenState();
}

class _IdCardsScreenState extends State<IdCardsScreen> {
  List<dynamic> _idCards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIdCards();
  }

  Future<void> _loadIdCards() async {
    try {
      final response = await ApiService.getRoleAwareIdCards();
      setState(() {
        _idCards = response.data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ID Cards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIdCards,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _idCards.isEmpty ? 1 : _idCards.length,
                itemBuilder: (context, index) {
                  if (_idCards.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No ID cards found'),
                      ),
                    );
                  }
                  final card = _idCards[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryLight,
                        child: const Icon(Icons.badge, color: AppTheme.primaryColor),
                      ),
                      title: Text(card['member_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('ID: ${card['membership_number'] ?? 'N/A'}'),
                      trailing: _buildStatusChip(card['status'] ?? 'active', card['expiry_date']),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateIdCardScreen())); if (result == true) _loadIdCards(); },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String status, String? expiryDate) {
    bool isExpired = false;
    bool isExpiringSoon = false;
    if (expiryDate != null) {
      try {
        final exp = DateTime.parse(expiryDate);
        final now = DateTime.now();
        isExpired = exp.isBefore(now);
        isExpiringSoon = exp.difference(now).inDays < 30 && !isExpired;
      } catch (_) {}
    }

    Color color;
    String label;
    if (isExpired) {
      color = AppTheme.error;
      label = 'Expired';
    } else if (isExpiringSoon) {
      color = AppTheme.warning;
      label = 'Expiring';
    } else {
      color = AppTheme.success;
      label = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
