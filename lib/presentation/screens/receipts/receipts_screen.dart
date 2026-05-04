import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import 'create_receipt_screen.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  List<dynamic> _receipts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    try {
      final response = await ApiService.getRoleAwareReceipts();
      final body = response.data;
      List<dynamic> items;
      if (body is Map<String, dynamic>) {
        items = body['data'] is List ? body['data'] as List : [];
      } else if (body is List) {
        items = body;
      } else {
        items = [];
      }
      setState(() {
        _receipts = items;
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
    if (e.toString().contains('403')) return 'Access denied.';
    if (e.toString().contains('401')) return 'Session expired.';
    return 'Failed to load receipts. Pull to retry.';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified': return AppTheme.success;
      case 'issued': return AppTheme.primaryColor;
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ore Receipts'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      body: RefreshIndicator(
        onRefresh: _loadReceipts,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadReceipts, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _receipts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            const Text('No receipts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Create your first ore receipt', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _receipts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final receipt = _receipts[index] as Map<String, dynamic>;
                          final status = receipt['status'] ?? 'issued';
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          receipt['receipt_number'] ?? 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status.toString().toUpperCase(),
                                          style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _infoChip(Icons.local_shipping, receipt['transporter_name'] ?? 'N/A'),
                                      const SizedBox(width: 12),
                                      _infoChip(Icons.scale, '${receipt['weight'] ?? 0} kg'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _infoChip(Icons.calendar_today, receipt['issue_date'] ?? 'N/A'),
                                      if (receipt['vehicle_number'] != null) ...[
                                        const SizedBox(width: 12),
                                        _infoChip(Icons.directions_car, receipt['vehicle_number']),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReceiptScreen())); if (result == true) _loadReceipts(); },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }
}
