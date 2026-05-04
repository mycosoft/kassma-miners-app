import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class MemberPickerScreen extends StatefulWidget {
  const MemberPickerScreen({super.key});

  @override
  State<MemberPickerScreen> createState() => _MemberPickerScreenState();
}

class _MemberPickerScreenState extends State<MemberPickerScreen> {
  List<dynamic> _members = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final response = await ApiService.getRoleAwareMembers();
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
        _members = items;
        _filtered = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load members. Pull to retry.';
        _loading = false;
      });
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _members;
      } else {
        final q = query.toLowerCase();
        _filtered = _members.where((m) {
          final map = m as Map<String, dynamic>;
          final name = (map['full_name'] ?? '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}').toString().toLowerCase();
          final memNum = (map['membership_number'] ?? '').toString().toLowerCase();
          return name.contains(q) || memNum.contains(q);
        }).toList();
      }
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return AppTheme.success;
      case 'suspended': return AppTheme.error;
      default: return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            Expanded(
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
                              ElevatedButton(onPressed: _loadMembers, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people, size: 64, color: AppTheme.textSecondary),
                                  const SizedBox(height: 16),
                                  Text(_searchCtrl.text.isEmpty ? 'No members found' : 'No matching members', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final member = _filtered[index] as Map<String, dynamic>;
                                final status = member['status'] ?? 'active';
                                final fullName = member['full_name'] ?? '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
                                final initials = fullName.isNotEmpty ? fullName.split(' ').map((n) => n[0]).take(2).join().toUpperCase() : '??';
                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryLight,
                                      child: Text(initials, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                    title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Text(member['membership_number'] ?? 'N/A', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(status.toString().toUpperCase(), style: TextStyle(fontSize: 9, color: _statusColor(status), fontWeight: FontWeight.w700)),
                                    ),
                                    onTap: () => Navigator.pop(context, member),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
