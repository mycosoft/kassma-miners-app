import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<dynamic> _workers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
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
      setState(() { _workers = items; _loading = false; });
    } catch (e) {
      setState(() { _error = _parseError(e); _loading = false; });
    }
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('403')) return 'Access denied.';
    if (e.toString().contains('401')) return 'Session expired.';
    return 'Failed to load workers. Pull to retry.';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return AppTheme.success;
      case 'suspended': return AppTheme.error;
      case 'inactive': return AppTheme.textSecondary;
      default: return AppTheme.warning;
    }
  }

  void _showAddWorkerDialog() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final nationalIdCtrl = TextEditingController();
    String gender = 'male';
    DateTime? dob;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_add, color: AppTheme.primaryColor)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Add Worker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: TextField(controller: firstNameCtrl, decoration: _inputDeco('First Name *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: lastNameCtrl, decoration: _inputDeco('Last Name *'))),
                      ]),
                      const SizedBox(height: 14),
                      TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: _inputDeco('Email')),
                      const SizedBox(height: 14),
                      TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: _inputDeco('Phone Number')),
                      const SizedBox(height: 14),
                      TextField(controller: nationalIdCtrl, decoration: _inputDeco('National ID')),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: _inputDeco('Gender'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                        ],
                        onChanged: (v) => setSheetState(() => gender = v ?? 'male'),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: ctx, initialDate: DateTime(1990), firstDate: DateTime(1940), lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)));
                          if (d != null) setSheetState(() => dob = d);
                        },
                        child: InputDecorator(
                          decoration: _inputDeco('Date of Birth'),
                          child: Text(dob != null ? '${dob!.day}/${dob!.month}/${dob!.year}' : 'Select Date', style: TextStyle(color: dob != null ? Colors.black : Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (firstNameCtrl.text.isEmpty || lastNameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('First and last name required')));
                        return;
                      }
                      try {
                        await ApiService.createRoleAwareMember({
                          'first_name': firstNameCtrl.text,
                          'last_name': lastNameCtrl.text,
                          'email': emailCtrl.text.isNotEmpty ? emailCtrl.text : null,
                          'phone': phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null,
                          'national_id': nationalIdCtrl.text.isNotEmpty ? nationalIdCtrl.text : null,
                          'gender': gender,
                          'date_of_birth': dob?.toIso8601String(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadWorkers();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worker added successfully'), backgroundColor: AppTheme.success));
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Add Worker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workers'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWorkerDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Worker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkers,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadWorkers, child: const Text('Retry')),
                  ]))
                : _workers.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.people, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        const Text('No workers yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Tap + to add workers', style: TextStyle(color: Colors.grey.shade500)),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _workers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final worker = _workers[index] as Map<String, dynamic>;
                          final status = worker['status'] ?? 'active';
                          final fullName = worker['full_name'] ?? '${worker['first_name'] ?? ''} ${worker['last_name'] ?? ''}'.trim();
                          final initials = fullName.isNotEmpty ? fullName.split(' ').map((n) => n[0]).take(2).join().toUpperCase() : '??';
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(radius: 24, backgroundColor: AppTheme.primaryLight, child: Text(initials, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16))),
                              title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const SizedBox(height: 4),
                                Text(worker['membership_number'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                if (worker['phone'] != null) Text(worker['phone'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ]),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(status.toString().toUpperCase(), style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.w700)),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
