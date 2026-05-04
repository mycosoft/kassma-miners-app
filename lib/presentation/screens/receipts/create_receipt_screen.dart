import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class CreateReceiptScreen extends StatefulWidget {
  const CreateReceiptScreen({super.key});

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _transporterCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedPitId;
  String? _selectedMemberId;
  List<Map<String, dynamic>> _pits = [];
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final pitsRes = await ApiService.fetchMyPits();
      final pitsBody = pitsRes.data;
      final pitsData = pitsBody is Map<String, dynamic> ? (pitsBody['data'] ?? []) : pitsBody;
      final membersRes = await ApiService.getRoleAwareMembers();
      final membersBody = membersRes.data;
      final membersData = membersBody is Map<String, dynamic> ? (membersBody['data'] ?? []) : membersBody;
      setState(() {
        _pits = List<Map<String, dynamic>>.from(pitsData);
        _members = List<Map<String, dynamic>>.from(membersData);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPitId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a pit'))); return; }
    if (_selectedMemberId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a member'))); return; }

    setState(() => _submitting = true);
    try {
      await ApiService.createRoleAwareReceipt({
        'pit_id': _selectedPitId,
        'member_id': _selectedMemberId,
        'weight': double.tryParse(_weightCtrl.text) ?? 0,
        'transporter_name': _transporterCtrl.text.isEmpty ? null : _transporterCtrl.text,
        'vehicle_number': _vehicleCtrl.text.isEmpty ? null : _vehicleCtrl.text,
        'notes': _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt created successfully!')));
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
      appBar: AppBar(title: const Text('New Ore Receipt'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
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
                      value: _selectedMemberId,
                      decoration: const InputDecoration(labelText: 'Member *', prefixIcon: Icon(Icons.person)),
                      items: _members.map((m) => DropdownMenuItem(value: m['id']?.toString(), child: Text(m['full_name'] ?? '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim()))).toList(),
                      onChanged: (v) => setState(() => _selectedMemberId = v),
                      validator: (_) => _selectedMemberId == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _weightCtrl, decoration: const InputDecoration(labelText: 'Weight (kg) *', prefixIcon: Icon(Icons.scale)), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _transporterCtrl, decoration: const InputDecoration(labelText: 'Transporter Name', prefixIcon: Icon(Icons.local_shipping))),
                    const SizedBox(height: 16),
                    TextFormField(controller: _vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number', prefixIcon: Icon(Icons.directions_car))),
                    const SizedBox(height: 16),
                    TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.note)), maxLines: 3),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Receipt')),
                  ],
                ),
              ),
            ),
    );
  }
}