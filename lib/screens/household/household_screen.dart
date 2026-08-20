import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../models/household.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dish_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/dino_card.dart';
import 'create_or_join_household_dialog.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final householdProvider = Provider.of<HouseholdProvider>(context, listen: false);
      if (householdProvider.currentHousehold != null) {
        householdProvider.loadMembers();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isUploadingUserAvatar = false;

  Future<void> _pickAndUploadUserImage() async {
    if (_isUploadingUserAvatar) return;
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isUploadingUserAvatar = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final ext = pickedFile.name.split('.').last;
        
        if (!mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.uploadAvatar(bytes, ext);
        
        if (mounted) {
          if (success) {
            context.read<HouseholdProvider>().loadMembers(); // Refresh members list to show new avatar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profilbild erfolgreich hochgeladen!'), backgroundColor: AppTheme.primaryGreen),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authProvider.errorMessage ?? 'Fehler beim Upload'), backgroundColor: AppTheme.errorRed),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isUploadingUserAvatar = false);
      }
    }
  }

  void _confirmDeleteHousehold(
    BuildContext context,
    Household household,
    HouseholdProvider householdProvider,
    ShoppingProvider shoppingProvider,
    StockProvider stockProvider,
    DishProvider dishProvider,
  ) {
    final currentUserId = SupabaseConfig.currentUserId;
    final hasOtherMembers = householdProvider.members
        .where((m) => m.householdId == household.id && m.userId != currentUserId)
        .isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Haushalt wirklich löschen?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Der Haushalt "${household.name}" und seine gemeinsamen Daten werden dauerhaft gelöscht.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (hasOtherMembers) ...[
              const SizedBox(height: 12),
              const Text(
                'Dieser Haushalt wird auch für die anderen Mitglieder gelöscht.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorRed,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await householdProvider.deleteHousehold(household.id);
              if (context.mounted) {
                if (success) {
                  final active = householdProvider.currentHousehold;
                  if (active != null) {
                    shoppingProvider.bindToHousehold(active.id);
                    stockProvider.bindToHousehold(active.id);
                    dishProvider.loadDishes(active.id);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Haushalt wurde gelöscht.'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(householdProvider.errorMessage ?? 'Der Haushalt konnte nicht gelöscht werden.'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Haushalt löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final householdProvider = Provider.of<HouseholdProvider>(context);
    final shoppingProvider = Provider.of<ShoppingProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final dishProvider = Provider.of<DishProvider>(context, listen: false);
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
                  // --- SECTION 1: MEINE HAUSHALTE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Meine Haushalte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '${householdProvider.households.length} ${householdProvider.households.length == 1 ? 'Haushalt' : 'Haushalte'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...householdProvider.households.map((household) {
                    final isActive = householdProvider.isCurrentHousehold(household.id);
                    final isDefault = householdProvider.isDefaultHousehold(household.id);
                    final isOwner = householdProvider.isOwnerOf(household.id);
                    final canDelete = isOwner && householdProvider.households.length > 1;
                    final color = Color(int.parse(household.color.replaceFirst('#', '0xFF')));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (!isActive) {
                              householdProvider.setCurrentHousehold(household);
                              shoppingProvider.bindToHousehold(household.id);
                              stockProvider.bindToHousehold(household.id);
                              foodProvider.bindToHousehold(household.id);
                              dishProvider.loadDishes(household.id);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive ? AppTheme.primaryGreen : Colors.black.withValues(alpha: 0.06),
                                width: isActive ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // Favorite Star Button (★ / ☆)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isDefault ? Icons.star : Icons.star_border,
                                    color: isDefault ? const Color(0xFFF4A261) : AppTheme.textMuted.withValues(alpha: 0.45),
                                    size: 26,
                                  ),
                                  tooltip: isDefault ? 'Standardhaushalt (Favorit)' : 'Als Standardhaushalt setzen',
                                  onPressed: () async {
                                    if (!isDefault) {
                                      final success = await householdProvider.setDefaultHousehold(household.id);
                                      if (context.mounted && !success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(householdProvider.errorMessage ?? 'Der Standardhaushalt konnte nicht geändert werden.'),
                                            backgroundColor: AppTheme.errorRed,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(width: 12),

                                // Color indicator icon
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text('🏠', style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Household info: Name & Code / Role
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        household.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (household.inviteCode.isNotEmpty)
                                            Text(
                                              household.inviteCode.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          if (household.inviteCode.isNotEmpty && isOwner)
                                            const Text(' • ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                          if (isOwner)
                                            const Text(
                                              'Inhaber',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.primaryGreen,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Active indicator badge
                                if (isActive) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Aktiv',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],

                                // Delete button (only for owner and when user has > 1 household)
                                if (canDelete)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                                    tooltip: 'Haushalt löschen',
                                    onPressed: () {
                                      _confirmDeleteHousehold(
                                        context,
                                        household,
                                        householdProvider,
                                        shoppingProvider,
                                        stockProvider,
                                        dishProvider,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // Action: Create or Join another household
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) => const CreateOrJoinHouseholdDialog(isJoining: false),
                            );
                            if (result == true && householdProvider.currentHousehold != null) {
                              final active = householdProvider.currentHousehold!;
                              shoppingProvider.bindToHousehold(active.id);
                              stockProvider.bindToHousehold(active.id);
                              foodProvider.bindToHousehold(active.id);
                              dishProvider.loadDishes(active.id);
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Neuer Haushalt'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) => const CreateOrJoinHouseholdDialog(isJoining: true),
                            );
                            if (result == true && householdProvider.currentHousehold != null) {
                              final active = householdProvider.currentHousehold!;
                              shoppingProvider.bindToHousehold(active.id);
                              stockProvider.bindToHousehold(active.id);
                              foodProvider.bindToHousehold(active.id);
                              dishProvider.loadDishes(active.id);
                            }
                          },
                          icon: const Icon(Icons.group_add, size: 18),
                          label: const Text('Code beitreten'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 2: AKTIVER HAUSHALT DETAILS ---
                  if (currentHousehold != null) ...[
                    DinoCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(currentHousehold.color.replaceFirst('#', '0xFF'))),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(child: Text('🏠', style: TextStyle(fontSize: 22))),
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
                                            currentHousehold.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryGreen),
                                          tooltip: 'Haushalt umbenennen',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          onPressed: () {
                                            _showEditHouseholdDialog(
                                              context,
                                              householdProvider,
                                              currentHousehold,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (currentHousehold.inviteCode.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
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
                    const SizedBox(height: 24),
                  ],

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
                        final avatarUrl = member.profile?.avatarUrl;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: DinoCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                if (avatarUrl != null)
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: NetworkImage(avatarUrl),
                                    backgroundColor: AppTheme.primarySoft,
                                  )
                                else
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
                            GestureDetector(
                              onTap: _pickAndUploadUserImage,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (authProvider.profile?.avatarUrl != null)
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundImage: NetworkImage(authProvider.profile!.avatarUrl!),
                                      backgroundColor: AppTheme.primaryGreen,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppTheme.primaryGreen,
                                      child: const Text(
                                        '🦕',
                                        style: TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isUploadingUserAvatar
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.camera_alt, size: 12, color: AppTheme.primaryGreen),
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
                                  Text(
                                    authProvider.profile?.displayName ?? 'Dino-Nutzer',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Dino_food Account',
                                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textDark,
                              side: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
                            ),
                            onPressed: () {
                              _showEditDisplayNameDialog(context, authProvider, householdProvider);
                            },
                            icon: const Icon(Icons.badge_outlined, size: 18),
                            label: const Text('Anzeigename ändern'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textDark,
                              side: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
                            ),
                            onPressed: _pickAndUploadUserImage,
                            icon: const Icon(Icons.photo_camera_outlined, size: 18),
                            label: const Text('Profilbild ändern'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textDark,
                              side: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
                            ),
                            onPressed: () {
                              _showChangePasswordDialog(context, authProvider);
                            },
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Passwort ändern'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textDark,
                              side: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
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
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            _handleDeleteAccount(context, authProvider, householdProvider, shoppingProvider);
                          },
                          child: const Text(
                            'Account unwiderruflich löschen',
                            style: TextStyle(color: AppTheme.errorRed, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Discreet branding
                  const Center(
                    child: Text(
                      '🦕 X4rinia 2026',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _showEditHouseholdDialog(
    BuildContext context,
    HouseholdProvider householdProvider,
    Household currentHousehold,
  ) {
    final controller = TextEditingController(text: currentHousehold.name);
    String selectedColor = currentHousehold.color;

    final List<String> householdColors = [
      '#2A9D8F', // Green
      '#2196F3', // Blue
      '#E76F51', // Red
      '#F4A261', // Orange
      '#9C27B0', // Purple
      '#4CAF50', // Light Green
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Haushalt bearbeiten', style: TextStyle(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Name des Haushalts',
                    hintText: 'z.B. Dino WG',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Farbe wählen',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: householdColors.map((hexColor) {
                    final isSelected = selectedColor.toUpperCase() == hexColor.toUpperCase();
                    final color = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = hexColor;
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: AppTheme.textDark, width: 3)
                              : Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    final success = await householdProvider.updateHouseholdDetails(
                      controller.text.trim(),
                      selectedColor,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted && !success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fehler beim Aktualisieren des Haushalts.'),
                          backgroundColor: AppTheme.errorRed,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Speichern'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDisplayNameDialog(
    BuildContext context,
    AuthProvider authProvider,
    HouseholdProvider householdProvider,
  ) {
    final currentName = authProvider.profile?.displayName ?? '';
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

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
              child: const Text('👤', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            const Text(
              'Anzeigename ändern',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Anzeigename',
              hintText: 'z.B. Xarinia',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bitte gib einen Namen ein.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newName = controller.text.trim();
                Navigator.pop(ctx);
                final success = await authProvider.updateDisplayName(newName);
                if (success) {
                  await householdProvider.loadMembers();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anzeigename erfolgreich geändert!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Fehler beim Ändern des Namens.'),
                      backgroundColor: AppTheme.errorRed,
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

  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
              child: const Text('🔐', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            const Text(
              'Passwort ändern',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Neues Passwort',
                  hintText: 'Mindestens 6 Zeichen',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte neues Passwort eingeben';
                  }
                  if (value.length < 6) {
                    return 'Mindestens 6 Zeichen erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Neues Passwort wiederholen',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
                ),
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Passwörter stimmen nicht überein';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newPassword = passwordController.text;
                Navigator.pop(ctx);
                final success = await authProvider.changePassword(newPassword);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Passwort wurde geändert.'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.errorMessage ?? 'Passwort konnte nicht geändert werden.'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Passwort ändern'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(
    BuildContext context,
    AuthProvider authProvider,
    HouseholdProvider householdProvider,
    ShoppingProvider shoppingProvider,
  ) {
    final currentUserId = authProvider.currentUser?.id;
    final isOwner = householdProvider.members.any((m) => m.userId == currentUserId && m.role == 'owner');
    final hasOtherMembers = householdProvider.members.where((m) => m.userId != currentUserId).isNotEmpty;

    if (isOwner && hasOtherMembers) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.accentYellow, size: 24),
              SizedBox(width: 10),
              Text('Inhaberschaft übertragen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text(
            'Du bist Inhaber dieses Haushalts.\nÜbertrage zuerst die Inhaberschaft auf ein anderes Mitglied.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Verstanden'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
            SizedBox(width: 10),
            Text('Account löschen', style: TextStyle(color: AppTheme.errorRed, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('Möchtest du deinen Dino_food-Account wirklich unwiderruflich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await authProvider.deleteAccount();
              if (success) {
                householdProvider.reset();
                shoppingProvider.bindToHousehold(null);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authProvider.errorMessage ?? 'Account konnte nicht gelöscht werden.'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              }
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
