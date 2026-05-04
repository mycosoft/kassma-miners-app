import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class AssignMembersScreen extends StatefulWidget {
  const AssignMembersScreen({super.key});

  @override
  State<AssignMembersScreen> createState() => _AssignMembersScreenState();
}

class _AssignMembersScreenState extends State<AssignMembersScreen> {
  String? _selectedManagerId;
  final Set<String> _selectedPitIds = {};
  List<Map<String, dynamic>> _managers = [];
  List<Map<String, dynamic>> _pits = [];
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final managersRes = await ApiService.getPitOwnerPitManagers();
      final managersData = managersRes.data;
      final pitsRes = await ApiService.fetchMyPits();
      final pitsData = pitsRes.data;
      final workersRes = await ApiService.getAvailableMembers();
      final workersData = workersRes.data;
      setState(() {
        _managers = List<Map<String, dynamic>>.from(managersData is Map<String, dynamic> ? (managersData['data'] ?? managersData) : []);
        _pits = List<Map<String, dynamic>>.from(pitsData is Map<String, dynamic> ? (pitsData['data'] ?? pitsData) : []);
        _workers = List<Map<String, dynamic>>.from(workersData is Map<String, dynamic> ? (workersData['data'] ?? workersData) : []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedManagerId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a manager'))); return; }
    if (_selectedPitIds.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one pit'))); return; }
    setState(() => _submitting = true);
    try {
      await ApiService.assignMembers({
        'manager_id': _selectedManagerId,
        'pit_ids': _selectedPitIds.toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pits assigned successfully!')));
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
      appBar: AppBar(title: const Text('Assign Workers'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Available Workers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_workers.isEmpty)
                    Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('No workers available. Add workers first.', style: TextStyle(color: Colors.grey.shade600))))
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _workers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final w = _workers[index];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: AppTheme.primaryLight, child: Text(w['full_name']?.toString().split(' ').map((n) => n[0]).take(2).join().toUpperCase() ?? '??', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12))),
                            title: Text(w['full_name'] ?? 'Unknown'),
                            subtitle: Text(w['membership_number'] ?? ''),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedManagerId,
                    decoration: const InputDecoration(labelText: 'Pit Manager *', prefixIcon: Icon(Icons.engineering)),
                    items: _managers.map((m) => DropdownMenuItem(value: m['id']?.toString(), child: Text(m['name'] ?? 'Unknown'))).toList(),
                    onChanged: (v) => setState(() => _selectedManagerId = v),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Pits to Assign:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._pits.map((pit) => CheckboxListTile(
                    value: _selectedPitIds.contains(pit['id']?.toString()),
                    title: Text(pit['name'] ?? pit['pit_number'] ?? 'Unknown'),
                    subtitle: pit['pit_number'] != null ? Text(pit['pit_number'].toString()) : null,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedPitIds.add(pit['id']?.toString() ?? '');
                        } else {
                          _selectedPitIds.remove(pit['id']?.toString());
                        }
                      });
                    },
                  )),
                  if (_pits.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No pits available'))),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Assign Pits'),
                  ),
                ],
              ),
            ),
    );
  }
}
