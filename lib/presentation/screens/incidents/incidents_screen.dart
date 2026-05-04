import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import 'create_incident_screen.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  List<dynamic> _incidents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final response = await ApiService.getRoleAwareIncidents();
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
        _incidents = items;
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
    return 'Failed to load incidents. Pull to retry.';
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return AppTheme.error;
      case 'high': return Colors.deepOrange;
      case 'medium': return AppTheme.warning;
      case 'low': return AppTheme.success;
      default: return AppTheme.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'accident': return Icons.local_hospital;
      case 'risk': return Icons.warning;
      case 'conflict': return Icons.group_off;
      case 'fatality': return Icons.dangerous;
      default: return Icons.report_problem;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': case 'closed': return AppTheme.success;
      case 'investigating': return AppTheme.primaryColor;
      default: return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incidents'), backgroundColor: AppTheme.error, foregroundColor: Colors.white),
      body: RefreshIndicator(
        onRefresh: _loadIncidents,
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
                        ElevatedButton(onPressed: _loadIncidents, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _incidents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            const Text('No incidents reported', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('All clear! Report an incident if needed.', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _incidents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final incident = _incidents[index] as Map<String, dynamic>;
                          final severity = incident['severity'] ?? 'low';
                          final type = incident['type'] ?? 'risk';
                          final status = incident['status'] ?? 'open';
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _severityColor(severity).withValues(alpha: 0.3), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _severityColor(severity).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(_typeIcon(type), color: _severityColor(severity), size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              type.toString().toUpperCase(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            Text(
                                              incident['location'] ?? 'No location',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status.toString().toUpperCase(),
                                          style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    incident['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _severityColor(severity).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          severity.toString().toUpperCase(),
                                          style: TextStyle(fontSize: 10, color: _severityColor(severity), fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(incident['occurred_at'] ?? incident['created_at']),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
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
        onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateIncidentScreen())); if (result == true) _loadIncidents(); },
        backgroundColor: AppTheme.error,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr.toString().substring(0, dateStr.toString().length > 10 ? 10 : dateStr.toString().length);
    }
  }
}
