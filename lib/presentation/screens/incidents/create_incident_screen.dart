import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _selectedPitId;
  String _selectedType = 'risk';
  String _selectedSeverity = 'medium';
  DateTime? _occurredAt;
  List<Map<String, dynamic>> _pits = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPits();
  }

  Future<void> _loadPits() async {
    try {
      final res = await ApiService.fetchMyPits();
      final body = res.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? []) : body;
      setState(() { _pits = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPitId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a pit'))); return; }

    setState(() => _submitting = true);
    try {
      await ApiService.createRoleAwareIncident({
        'pit_id': _selectedPitId,
        'type': _selectedType,
        'severity': _selectedSeverity,
        'description': _descCtrl.text,
        'location': _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
        'occurred_at': _occurredAt?.toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident reported successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident'), backgroundColor: AppTheme.error, foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedPitId,
                      decoration: const InputDecoration(labelText: 'Pit *', prefixIcon: Icon(Icons.landscape)),
                      items: _pits.map((p) => DropdownMenuItem(value: p['id']?.toString(), child: Text(p['name'] ?? p['pit_number'] ?? 'Unknown'))).toList(),
                      onChanged: (v) => setState(() => _selectedPitId = v),
                      validator: (_) => _selectedPitId == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Type *', prefixIcon: Icon(Icons.category)),
                      items: const [DropdownMenuItem(value: 'accident', child: Text('Accident')), DropdownMenuItem(value: 'risk', child: Text('Risk')), DropdownMenuItem(value: 'conflict', child: Text('Conflict')), DropdownMenuItem(value: 'fatality', child: Text('Fatality'))],
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSeverity,
                      decoration: const InputDecoration(labelText: 'Severity *', prefixIcon: Icon(Icons.signal_cellular_alt)),
                      items: const [DropdownMenuItem(value: 'low', child: Text('Low')), DropdownMenuItem(value: 'medium', child: Text('Medium')), DropdownMenuItem(value: 'high', child: Text('High')), DropdownMenuItem(value: 'critical', child: Text('Critical'))],
                      onChanged: (v) => setState(() => _selectedSeverity = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description *', prefixIcon: Icon(Icons.description)), maxLines: 3, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on))),
                    const SizedBox(height: 16),
                    ListTile(contentPadding: EdgeInsets.zero, title: Text(_occurredAt == null ? 'Select Date/Time' : '${_occurredAt!.day}/${_occurredAt!.month}/${_occurredAt!.year}'), leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor), trailing: const Icon(Icons.chevron_right), onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now()); if (d != null) setState(() => _occurredAt = d); }),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _submitting ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Report Incident')),
                  ],
                ),
              ),
            ),
    );
  }
}