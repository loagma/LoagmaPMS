import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/staff_controller.dart';
import '../../theme/app_colors.dart';

/// Create or edit a subadmin account.
/// Pass [existing] (a staff map from the list) to enter edit mode.
class StaffFormScreen extends StatefulWidget {
  const StaffFormScreen({super.key, this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  late final Set<String> _selectedPerms;
  bool _isLocked = false;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.existing!;
      _nameCtrl.text = s['name'] as String? ?? '';
      _mobileCtrl.text = s['mobile'] as String? ?? '';
      _isLocked = s['is_locked'] == true;
      final perms = (s['permissions'] as List?)?.cast<String>() ?? [];
      _selectedPerms = perms.toSet();
    } else {
      _selectedPerms = {};
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPerms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one module permission')),
      );
      return;
    }

    setState(() => _isSaving = true);

    StaffController controller;
    try {
      controller = Get.find<StaffController>();
    } catch (_) {
      controller = Get.put(StaffController());
    }

    String? err;
    if (_isEdit) {
      err = await controller.updateStaff(
        deliId: widget.existing!['deli_id'] as int,
        name: _nameCtrl.text.trim(),
        permissions: _selectedPerms.toList(),
        isLocked: _isLocked,
      );
    } else {
      err = await controller.createStaff(
        name: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        permissions: _selectedPerms.toList(),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Subadmin updated' : 'Subadmin created')),
      );
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          _isEdit ? 'Edit Subadmin' : 'Add Subadmin',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Mobile — read-only in edit mode
              TextFormField(
                controller: _mobileCtrl,
                readOnly: _isEdit,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(),
                  filled: _isEdit,
                  fillColor: _isEdit ? Colors.grey.withValues(alpha: 0.08) : null,
                  helperText: _isEdit ? 'Mobile cannot be changed' : null,
                ),
                keyboardType: TextInputType.phone,
                validator: _isEdit
                    ? null
                    : (v) {
                        if (v == null || v.trim().isEmpty) return 'Mobile is required';
                        if (v.trim().length < 10) return 'Enter a valid mobile number';
                        return null;
                      },
              ),
              const SizedBox(height: 16),

              // Lock toggle (edit only)
              if (_isEdit) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Account Locked'),
                  subtitle: const Text('Locked accounts cannot log in'),
                  value: _isLocked,
                  activeThumbColor: Colors.redAccent,
                  onChanged: (v) => setState(() => _isLocked = v),
                ),
                const SizedBox(height: 8),
              ],

              // Module permissions
              const Text(
                'Module Permissions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select which modules this subadmin can access',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: StaffController.grantableModules.map((mod) {
                    final key = mod['key']!;
                    final label = mod['label']!;
                    final checked = _selectedPerms.contains(key);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(label),
                      value: checked,
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedPerms.add(key);
                          } else {
                            _selectedPerms.remove(key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isEdit ? 'Save Changes' : 'Create Subadmin',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
