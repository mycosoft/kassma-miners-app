import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class CreateIdCardScreen extends StatefulWidget {
  const CreateIdCardScreen({super.key});

  @override
  State<CreateIdCardScreen> createState() => _CreateIdCardScreenState();
}

class _CreateIdCardScreenState extends State<CreateIdCardScreen> {
  String? _selectedMemberId;
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final res = await ApiService.getRoleAwareMembers();
      final body = res.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? []) : body;
      setState(() { _members = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedMemberId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a member'))); return; }
    setState(() => _submitting = true);
    try {
      await ApiService.createRoleIdCard({'member_id': _selectedMemberId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Card issued successfully!')));
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
      appBar: AppBar(title: const Text('Issue ID Card'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMemberId,
                    decoration: const InputDecoration(labelText: 'Member *', prefixIcon: Icon(Icons.person)),
                    items: _members.map((m) => DropdownMenuItem(value: m['id']?.toString(), child: Text(m['full_name'] ?? '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim()))).toList(),
                    onChanged: (v) => setState(() => _selectedMemberId = v),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Issue ID Card')),
                ],
              ),
            ),
    );
  }
}