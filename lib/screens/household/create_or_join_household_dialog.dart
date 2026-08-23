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
  final _codeController = TextEditingController();
  String _selectedColor = '#2A9D8F';
  late bool _isJoining;

  final List<String> _householdColors = [
    '#2A9D8F', // Green
    '#2196F3', // Blue
    '#E76F51', // Red
    '#F4A261', // Orange
    '#9C27B0', // Purple
    '#455A64', // Dark Grey
  ];

  @override
  void initState() {
    super.initState();
    _isJoining = widget.isJoining;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        color: _selectedColor,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
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
                    if (val == null || val.trim().isEmpty) {
                      return 'Bitte Name eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Color Picker
                const Text(
                  'Farbe des Haushalts',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _householdColors.map((colorHex) {
                    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                    final isSelected = _selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorHex;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: AppTheme.textDark, width: 3) : null,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))
                          ],
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }).toList(),
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
                    if (val == null || val.trim().isEmpty) {
                      return 'Bitte Code eingeben';
                    }
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
