import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/household_provider.dart';

class CreateOrJoinHouseholdDialog extends StatefulWidget {
  final bool isJoining;

  const CreateOrJoinHouseholdDialog({super.key, this.isJoining = false});

  @override
  State<CreateOrJoinHouseholdDialog> createState() => _CreateOrJoinHouseholdDialogState();
}

class _CreateOrJoinHouseholdDialogState extends State<CreateOrJoinHouseholdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _codeController = TextEditingController();
  late bool _isJoining;

  @override
  void initState() {
    super.initState();
    _isJoining = widget.isJoining;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _postalCodeController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<HouseholdProvider>(context, listen: false);
    bool success;

    if (_isJoining) {
      success = await provider.joinHousehold(_codeController.text.trim());
    } else {
      success = await provider.createHousehold(
        name: _nameController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isJoining ? 'Haushalt beigetreten!' : 'Neuer Haushalt erstellt!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🏠', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isJoining ? 'Haushalt beitreten' : 'Neuer Haushalt',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented / Toggle Tab
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isJoining = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isJoining ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: !_isJoining
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Erstellen',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_isJoining ? FontWeight.w700 : FontWeight.w500,
                              color: !_isJoining ? AppTheme.primaryGreen : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isJoining = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isJoining ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _isJoining
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Beitreten',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isJoining ? FontWeight.w700 : FontWeight.w500,
                              color: _isJoining ? AppTheme.primaryGreen : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (!_isJoining) ...[
                // Household Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name des Haushalts *',
                    hintText: 'z. B. Dino WG',
                    prefixIcon: Icon(Icons.home_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Bitte Name eingeben';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Postal Code
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Postleitzahl (PLZ)',
                    hintText: 'z. B. 10115',
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textMuted),
                  ),
                ),
              ] else ...[
                // Invite Code
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Einladungscode (6 Zeichen) *',
                    hintText: 'z. B. a1b2c3',
                    prefixIcon: Icon(Icons.key_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Bitte Code eingeben';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isJoining ? 'Beitreten' : 'Erstellen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
