import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme.dart';
import 'neon_sync_service.dart';
import 'login_screen.dart';
import 'views/accounts_tab_view.dart';
import 'views/secrets_tab_view.dart';
import 'views/contacts_tab_view.dart';
import 'views/birthdays_tab_view.dart';
import 'views/wifi_tab_view.dart';
import 'modals/add_account_modal.dart';
import 'modals/add_secret_modal.dart';
import 'modals/add_contact_modal.dart';
import 'modals/add_birthday_modal.dart';
import 'modals/add_wifi_modal.dart';
import 'modals/delete_confirmation_modal.dart';
import 'modals/master_password_modal.dart';
import 'services/biometric_service.dart';
import 'services/local_vault_db.dart';
import 'services/vault_sync_coordinator.dart';
import 'views/components/vault_skeleton_loading.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userId;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  bool _isSyncing = false;
  int _unsyncedCount = 0;
  String? _activeUserId;

  // 🔒 Phase 5: Auto-Lock & Background Inactivity Shield
  DateTime? _pausedTimestamp;
  bool _isVaultLocked = false;
  bool _isAuthenticating = false;
  static const Duration _autoLockThreshold = Duration(seconds: 45); // 45 seconds dormancy threshold

  // Real Database Lists
  List<dynamic> _passwords = [];
  List<dynamic> _secrets = [];
  List<dynamic> _contacts = [];
  List<dynamic> _birthdays = [];
  List<dynamic> _wifiNetworks = [];

  // Clean Typography-Only Tabs (No Icons)
  final List<Map<String, String>> _tabs = [
    {'type': 'password', 'title': 'Accounts'},
    {'type': 'secret', 'title': 'Things to Remember'},
    {'type': 'contact', 'title': 'Contacts'},
    {'type': 'birthday', 'title': 'Birthdays'},
    {'type': 'wifi', 'title': 'Wi-Fi'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeUserId = widget.userId;
    _loadVaultData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // ⏸️ App minimized or phone screen turned off
      if (!_isAuthenticating && !_isVaultLocked) {
        _pausedTimestamp = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      // ▶️ User returned to the app
      if (_pausedTimestamp != null) {
        final elapsed = DateTime.now().difference(_pausedTimestamp!);
        _pausedTimestamp = null;

        if (elapsed >= _autoLockThreshold && !_isVaultLocked) {
          debugPrint('🔒 Auto-lock triggered! Background dormancy: ${elapsed.inSeconds}s');
          setState(() {
            _isVaultLocked = true;
          });
          _triggerUnlock();
        }
      }
    }
  }

  /// Trigger biometric or master password prompt to unlock the shielded vault
  Future<void> _triggerUnlock() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      final isDeviceSecAvailable = await BiometricService.isDeviceSecurityAvailable();
      final storedToken = await BiometricService.getStoredSessionToken(widget.userEmail);

      if (isDeviceSecAvailable && storedToken != null) {
        final authenticated = await BiometricService.authenticateWithDeviceSecurity(
          reason: 'Unlock PassKeep to access your secured vault',
        );

        if (authenticated) {
          if (!mounted) return;
          setState(() {
            _isVaultLocked = false;
          });
          _isAuthenticating = false;
          return;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error during auto-lock biometric unlock: $e');
    }

    _isAuthenticating = false;

    // Fallback to Master Password Modal if biometrics failed or cancelled
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => MasterPasswordModal(
        email: widget.userEmail,
        userName: widget.userName,
        userId: _activeUserId,
        isSetupMode: false,
        onAuthenticated: () {
          if (!mounted) return;
          setState(() {
            _isVaultLocked = false;
          });
        },
      ),
    );
  }

  Future<void> _loadVaultData() async {
    // 1. Instant Local Read from SQLite (Zero loading delay!)
    if (_activeUserId != null) {
      final localItems = await LocalVaultDb.instance.getAllVaultItems(_activeUserId!);
      final unsynced = await LocalVaultDb.instance.getUnsyncedCount(_activeUserId!);

      if (mounted) {
        setState(() {
          _passwords = localItems['passwords'] ?? [];
          _secrets = localItems['secrets'] ?? [];
          _contacts = localItems['contacts'] ?? [];
          _birthdays = localItems['birthdays'] ?? [];
          _wifiNetworks = localItems['wifi'] ?? [];
          _unsyncedCount = unsynced;
          _isLoading = false;
        });
      }
    }

    // 2. Initial Silent Background Pull if local was empty
    if (_passwords.isEmpty && _secrets.isEmpty && _contacts.isEmpty && _birthdays.isEmpty && _wifiNetworks.isEmpty) {
      _triggerOneClickSync(isBackground: true);
    }
  }

  Future<void> _triggerOneClickSync({bool isBackground = false}) async {
    if (_activeUserId == null || _isSyncing) return;

    setState(() {
      _isSyncing = true;
      _isLoading = true; // 👈 Shows shimmer skeleton immediately across the screen!
    });

    final result = await VaultSyncCoordinator.instance.syncVault(
      userEmail: widget.userEmail,
      userId: _activeUserId!,
    );

    if (!mounted) return;

    // Refresh local cache after sync
    final localItems = await LocalVaultDb.instance.getAllVaultItems(_activeUserId!);
    final unsynced = await LocalVaultDb.instance.getUnsyncedCount(_activeUserId!);

    setState(() {
      _passwords = localItems['passwords'] ?? [];
      _secrets = localItems['secrets'] ?? [];
      _contacts = localItems['contacts'] ?? [];
      _birthdays = localItems['birthdays'] ?? [];
      _wifiNetworks = localItems['wifi'] ?? [];
      _unsyncedCount = unsynced;
      _isSyncing = false;
      _isLoading = false;
    });

    if (!isBackground) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.isOffline ? AppColors.alertPersimmon : AppColors.primaryMatcha,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            result.message,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out of PassKeep?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'You will need to sign in with Google again and re-verify your Master Password.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertPersimmon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 🛡️ Explicitly wipe hardware Keystore credentials and local SQLite on logout
    await BiometricService.clearStoredSession();
    await LocalVaultDb.instance.clearAllLocalData();
    NeonSyncService.clearSession();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAddItemModal() {
    if (_activeUserId == null) return;

    switch (_selectedTabIndex) {
      case 0:
        AddAccountModal.show(
          context: context,
          userId: _activeUserId!,
          onAdded: _loadVaultData,
        );
        break;
      case 1:
        AddSecretModal.show(
          context: context,
          userId: _activeUserId!,
          onAdded: _loadVaultData,
        );
        break;
      case 2:
        AddContactModal.show(
          context: context,
          userId: _activeUserId!,
          onAdded: _loadVaultData,
        );
        break;
      case 3:
        AddBirthdayModal.show(
          context: context,
          userId: _activeUserId!,
          onAdded: _loadVaultData,
        );
        break;
      case 4:
      default:
        AddWifiModal.show(
          context: context,
          userId: _activeUserId!,
          onAdded: _loadVaultData,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _passwords.length +
        _secrets.length +
        _contacts.length +
        _birthdays.length +
        _wifiNetworks.length;

    return Scaffold(
      backgroundColor: AppColors.oatMilkBg,
      body: SafeArea(
        child: Column(
          children: [
            // 🌿 1. Header with dynamic user info & Log Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${widget.userName.split(' ').first} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PassKeep • $totalCount Items Secured',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // 🔄 1-Click Refresh / Sync Button
                      GestureDetector(
                        onTap: _isSyncing ? null : () => _triggerOneClickSync(isBackground: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _unsyncedCount > 0 ? AppColors.alertPersimmon : AppColors.primaryMatcha.withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isSyncing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMatcha),
                                      ),
                                    )
                                  : Icon(
                                      LucideIcons.refreshCw,
                                      size: 14,
                                      color: _unsyncedCount > 0 ? AppColors.alertPersimmon : AppColors.primaryMatcha,
                                    ),
                              const SizedBox(width: 6),
                              Text(
                                _isSyncing
                                    ? 'Syncing...'
                                    : _unsyncedCount > 0
                                        ? 'Sync ($_unsyncedCount)'
                                        : 'Sync',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _unsyncedCount > 0 ? AppColors.alertPersimmon : AppColors.primaryMatcha,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Log Out Pill (Clean text, no icon)
                      GestureDetector(
                        onTap: _handleLogout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.alertPersimmon.withValues(alpha: 0.5), width: 1.2),
                          ),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.alertPersimmon,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🍵 2. Typography Category Filter Tabs (Zero Icons)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final bool isSelected = _selectedTabIndex == index;
                  final tab = _tabs[index];

                  int count = 0;
                  if (index == 0) count = _passwords.length;
                  if (index == 1) count = _secrets.length;
                  if (index == 2) count = _contacts.length;
                  if (index == 3) count = _birthdays.length;
                  if (index == 4) count = _wifiNetworks.length;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryMatcha : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryMatcha : AppColors.borderMuted,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${tab['title']} ($count)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 📋 3. Dynamic Real List from Neon OR 🔒 Privacy Shield when locked
            Expanded(
              child: _isVaultLocked
                  ? _buildLockedPrivacyShield()
                  : (_isLoading || _isSyncing)
                      ? const VaultSkeletonLoading()
                      : RefreshIndicator(
                          onRefresh: () => _triggerOneClickSync(isBackground: false),
                          color: AppColors.primaryMatcha,
                          displacement: 24,
                          child: _buildCurrentList(),
                        ),
            ),
          ],
        ),
      ),

      // ➕ Floating Action Button for Adding Data (Hidden when Vault is Locked)
      floatingActionButton: _isVaultLocked
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddItemModal,
              backgroundColor: AppColors.primaryMatcha,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: const Text(
                'Add',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
    );
  }

  /// 🔒 Privacy Shield Widget displayed when Auto-Lock is engaged
  Widget _buildLockedPrivacyShield() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🍵 Monolith Architectural Emblem (No literal lock/key)
            SizedBox(
              width: 84,
              height: 84,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Vault Locked',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'PassKeep automatically locked your vault due to inactivity to protect your credentials.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _triggerUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMatcha,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Unlock Vault',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentList() {
    switch (_selectedTabIndex) {
      case 0:
        return AccountsTabView(
          items: _passwords,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_passwords, 'Changes saved successfully!'),
          onDelete: (item) => _confirmDeleteItem(
            title: item['title'] ?? 'Account',
            itemTypeLabel: 'Account',
            type: 'password',
            itemId: item['id'].toString(),
            targetList: _passwords,
          ),
        );
      case 1:
        return SecretsTabView(
          items: _secrets,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_secrets, 'Secret updated successfully!'),
          onPinnedToggled: () => _reSortListAndNotify(_secrets, null),
          onDelete: (item) => _confirmDeleteItem(
            title: item['title'] ?? 'Secret Note',
            itemTypeLabel: 'Secret',
            type: 'secret',
            itemId: item['id'].toString(),
            targetList: _secrets,
          ),
        );
      case 2:
        return ContactsTabView(
          items: _contacts,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_contacts, 'Contact updated successfully!'),
          onDelete: (item) => _confirmDeleteItem(
            title: item['name'] ?? 'Contact',
            itemTypeLabel: 'Contact',
            type: 'contact',
            itemId: item['id'].toString(),
            targetList: _contacts,
          ),
        );
      case 3:
        return BirthdaysTabView(
          items: _birthdays,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_birthdays, 'Birthday updated successfully!'),
          onDelete: (item) => _confirmDeleteItem(
            title: item['name'] ?? 'Birthday',
            itemTypeLabel: 'Birthday',
            type: 'birthday',
            itemId: item['id'].toString(),
            targetList: _birthdays,
          ),
        );
      case 4:
      default:
        return WifiTabView(
          items: _wifiNetworks,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_wifiNetworks, 'Wi-Fi network updated successfully!'),
          onDelete: (item) => _confirmDeleteItem(
            title: item['ssid'] ?? 'Wi-Fi Network',
            itemTypeLabel: 'Wi-Fi Network',
            type: 'wifi',
            itemId: item['id'].toString(),
            targetList: _wifiNetworks,
          ),
        );
    }
  }

  void _confirmDeleteItem({
    required String title,
    required String itemTypeLabel,
    required String type,
    required String itemId,
    required List<dynamic> targetList,
  }) {
    if (_activeUserId == null) return;

    DeleteConfirmationModal.show(
      context: context,
      title: title,
      itemTypeLabel: itemTypeLabel,
      type: type,
      itemId: itemId,
      userId: _activeUserId!,
      onDeleted: () {
        setState(() {
          targetList.removeWhere((element) => element['id'].toString() == itemId);
        });
        _loadVaultData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primaryMatcha,
              behavior: SnackBarBehavior.floating,
              content: Text('$itemTypeLabel deleted successfully!'),
            ),
          );
        }
      },
    );
  }

  void _reSortListAndNotify(List<dynamic> targetList, String? message) {
    setState(() {
      targetList.sort((a, b) {
        final aPinned = (a['is_pinned'] == true || a['is_pinned'] == 1) ? 1 : 0;
        final bPinned = (b['is_pinned'] == true || b['is_pinned'] == 1) ? 1 : 0;
        if (aPinned != bPinned) return bPinned.compareTo(aPinned);

        final aSynced = (a['is_synced'] == null || a['is_synced'] == 1 || a['is_synced'] == true) ? 1 : 0;
        final bSynced = (b['is_synced'] == null || b['is_synced'] == 1 || b['is_synced'] == true) ? 1 : 0;
        if (aSynced != bSynced) return aSynced.compareTo(bSynced); // Unsynced items (0) go on top

        final bTime = (b['updated_at'] ?? b['created_at'] ?? '').toString();
        final aTime = (a['updated_at'] ?? a['created_at'] ?? '').toString();
        return bTime.compareTo(aTime);
      });
    });

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryMatcha,
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
      _loadVaultData();
    }
  }
}
