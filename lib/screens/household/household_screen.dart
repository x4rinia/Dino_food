import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../models/household.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../widgets/dino_card.dart';
import 'create_or_join_household_dialog.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final _plzController = TextEditingController();
  bool _isEditingPlz = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final householdProvider = Provider.of<HouseholdProvider>(context, listen: false);
      if (householdProvider.currentHousehold != null) {
        _plzController.text = householdProvider.currentHousehold!.postalCode;
        householdProvider.loadMembers();
      }
    });
  }

  @override
  void dispose() {
    _plzController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.name.split('.').last;
      
      if (!mounted) return;
      final householdProvider = Provider.of<HouseholdProvider>(context, listen: false);
      final success = await householdProvider.uploadHouseholdImage(bytes, ext);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WG-Bild erfolgreich hochgeladen!'), backgroundColor: AppTheme.primaryGreen),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(householdProvider.errorMessage ?? 'Fehler beim Upload'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final householdProvider = Provider.of<HouseholdProvider>(context);
    final shoppingProvider = Provider.of<ShoppingProvider>(context, listen: false);
    final currentHousehold = householdProvider.currentHousehold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haushalt & Profil 🏠'),
      ),
      body: householdProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Household Card
                  DinoCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (currentHousehold?.imageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        currentHousehold!.imageUrl!,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 56,
                                      height: 56,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primarySoft,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(child: Text('🏠', style: TextStyle(fontSize: 24))),
                                    ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Aktiver Haushalt',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          currentHousehold?.name ?? 'Kein Haushalt',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      if (currentHousehold != null) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryGreen),
                                          tooltip: 'Haushalt umbenennen',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          onPressed: () {
                                            _showRenameHouseholdDialog(
                                              context,
                                              householdProvider,
                                              currentHousehold.name,
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (householdProvider.households.length > 1)
                              PopupMenuButton<Household>(
                                icon: const Icon(Icons.swap_horiz, color: AppTheme.primaryGreen),
                                tooltip: 'Haushalt wechseln',
                                onSelected: (h) {
                                  householdProvider.setCurrentHousehold(h);
                                  shoppingProvider.bindToHousehold(h.id);
                                  _plzController.text = h.postalCode;
                                },
                                itemBuilder: (ctx) {
                                  return householdProvider.households.map((h) {
                                    return PopupMenuItem(
                                      value: h,
                                      child: Text(h.name),
                                    );
                                  }).toList();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Postal Code Section
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 20, color: AppTheme.textMuted),
                            const SizedBox(width: 8),
                            const Text(
                              'Postleitzahl:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 10),
                            if (!_isEditingPlz) ...[
                              Text(
                                (currentHousehold?.postalCode.isNotEmpty == true)
                                    ? currentHousehold!.postalCode
                                    : 'Nicht festgelegt',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: currentHousehold?.postalCode.isNotEmpty == true
                                      ? AppTheme.textDark
                                      : AppTheme.textMuted,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryGreen),
                                onPressed: () {
                                  setState(() {
                                    _isEditingPlz = true;
                                    _plzController.text = currentHousehold?.postalCode ?? '';
                                  });
                                },
                              ),
                            ] else ...[
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _plzController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      hintText: 'PLZ z.B. 10115',
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, size: 20, color: AppTheme.primaryGreen),
                                onPressed: () {
                                  householdProvider.updatePostalCode(_plzController.text);
                                  setState(() => _isEditingPlz = false);
                                },
                              ),
                            ],
                          ],
                        ),

                        // Invite Code Section
                        if (currentHousehold != null &&
                            currentHousehold.inviteCode.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySoft.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.group_add_outlined, color: AppTheme.primaryGreen, size: 20),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Einladungscode für Mitbewohner:',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                    Text(
                                      currentHousehold.inviteCode.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryDark,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18, color: AppTheme.primaryGreen),
                                  tooltip: 'Code kopieren',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: currentHousehold.inviteCode.toUpperCase()),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Einladungscode in die Zwischenablage kopiert!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action: Create or Join another household
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const CreateOrJoinHouseholdDialog(isJoining: false),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Neuer Haushalt'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const CreateOrJoinHouseholdDialog(isJoining: true),
                            );
                          },
                          icon: const Icon(Icons.group_add, size: 18),
                          label: const Text('Code beitreten'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Members Section
                  const Text(
                    'Haushaltsmitglieder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (householdProvider.members.isEmpty)
                    DinoCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Text('🦕', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            authProvider.profile?.displayName ?? 'Du',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Inhaber',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: householdProvider.members.map((member) {
                        final isOwner = member.role == 'owner';
                        final name = member.profile?.displayName ?? 'Mitglied';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: DinoCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primarySoft,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOwner ? AppTheme.primarySoft : AppTheme.checkedGray,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOwner ? 'Inhaber' : 'Mitglied',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOwner ? AppTheme.primaryGreen : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 28),

                  // Profile & Account Card
                  const Text(
                    'Dein Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  DinoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryGreen,
                              child: const Text(
                                '🦕',
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authProvider.profile?.displayName ??
                                        authProvider.currentUser?.email?.split('@').first ??
                                        'Dino-Nutzer',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    authProvider.currentUser?.email ?? 'lokaler Demo-Modus',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              side: const BorderSide(color: AppTheme.errorRed),
                            ),
                            onPressed: () {
                              shoppingProvider.bindToHousehold(null);
                              householdProvider.reset();
                              authProvider.signOut();
                            },
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Abmelden'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _showRenameHouseholdDialog(
    BuildContext context,
    HouseholdProvider householdProvider,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('✏️', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            const Text(
              'Haushalt umbenennen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Haushaltsname',
            hintText: 'z. B. Dino WG',
            prefixIcon: Icon(Icons.home_outlined, color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await householdProvider.renameHousehold(newName);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Haushalt erfolgreich in "$newName" umbenannt!'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
