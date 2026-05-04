import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../receipts/create_receipt_screen.dart';
import '../incidents/create_incident_screen.dart';
import '../id_cards/create_id_card_screen.dart';
import '../members/assign_members_screen.dart';
import '../members/members_screen.dart';

class PitOwnerDashboard extends StatefulWidget {
  final String userName;
  final String rolePrefix;
  const PitOwnerDashboard({super.key, this.userName = 'User', this.rolePrefix = 'pit-owner'});

  @override
  State<PitOwnerDashboard> createState() => _PitOwnerDashboardState();
}

class _PitOwnerDashboardState extends State<PitOwnerDashboard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = widget.rolePrefix == 'pit-manager'
          ? await ApiService.getPitManagerDashboard()
          : await ApiService.getPitOwnerDashboard();
      final body = response.data as Map<String, dynamic>;
      final payload = (body['data'] is Map<String, dynamic>) ? body['data'] as Map<String, dynamic> : body;
      setState(() { _data = payload; _loading = false; });
    } on DioException catch (e) {
      setState(() { _error = _parseDioError(e); _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load dashboard'; _loading = false; });
    }
  }

  String _parseDioError(DioException e) {
    if (e.response?.statusCode == 401) return 'Session expired. Please login again.';
    if (e.response?.statusCode == 500) return '';
    return 'Network error. Please try again.';
  }

  Future<void> _navigateToAction(String label) async {
    Widget screen;
    switch (label) {
      case 'New Receipt': screen = const CreateReceiptScreen(); break;
      case 'Report Incident': screen = const CreateIncidentScreen(); break;
      case 'Issue ID Card': screen = const CreateIdCardScreen(); break;
      case 'Assign Workers': screen = const AssignMembersScreen(); break;
      case 'View Workers': screen = const MembersScreen(); break;
      default: return;
    }
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (result == true) _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('All Systems Active', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats Row
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                  child: RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null && _error!.isNotEmpty
                            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.cloud_off, size: 48, color: AppTheme.textSecondary),
                                const SizedBox(height: 12),
                                Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
                              ]))
                            : SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(child: _buildStatCard(Icons.people, '${_data?['total_members'] ?? 0}', 'View Workers', AppTheme.primaryColor)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildStatCard(Icons.receipt, '${_data?['total_receipts'] ?? 0}', 'Receipts', AppTheme.success)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildStatCard(Icons.warning, '${(_data?['recent_incidents'] as List?)?.length ?? 0}', 'Incidents', AppTheme.warning)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildStatCard(Icons.landscape, '${_data?['active_pits'] ?? 0}', 'Active Pits', AppTheme.primaryDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 28),
                                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                                    const SizedBox(height: 14),
                                    _buildActionButton(Icons.receipt_long, 'New Receipt', Colors.white, AppTheme.primaryColor),
                                    const SizedBox(height: 10),
                                    _buildActionButton(Icons.warning_amber, 'Report Incident', Colors.white, const Color(0xFFE65100)),
                                    const SizedBox(height: 10),
                                    _buildActionButton(Icons.badge_outlined, 'Issue ID Card', Colors.white, const Color(0xFF1565C0)),
                                    const SizedBox(height: 10),
                                    _buildActionButton(Icons.assignment_ind, 'Assign Workers', Colors.white, const Color(0xFF2E7D32)),
                                    const SizedBox(height: 10),
                                    _buildActionButton(Icons.person_search, 'View Workers', Colors.white, const Color(0xFF6A1B9A)),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color textColor, Color bgColor) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToAction(label),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
