import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'theme.dart';
import 'neon_sync_service.dart';
import 'login_screen.dart';
import 'views/accounts_tab_view.dart';
import 'views/secrets_tab_view.dart';
import 'views/contacts_tab_view.dart';
import 'views/birthdays_tab_view.dart';
import 'modals/add_account_modal.dart';
import 'modals/add_secret_modal.dart';
import 'modals/add_contact_modal.dart';
import 'modals/add_birthday_modal.dart';
import 'modals/delete_confirmation_modal.dart';

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

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  String? _activeUserId;

  // Real Database Lists
  List<dynamic> _passwords = [];
  List<dynamic> _secrets = [];
  List<dynamic> _contacts = [];
  List<dynamic> _birthdays = [];

  // Clean Typography-Only Tabs (No Icons)
  final List<Map<String, String>> _tabs = [
    {'type': 'password', 'title': 'Accounts'},
    {'type': 'secret', 'title': 'Secrets'},
    {'type': 'contact', 'title': 'Contacts'},
    {'type': 'birthday', 'title': 'Birthdays'},
  ];

  @override
  void initState() {
    super.initState();
    _activeUserId = widget.userId;
    _loadVaultData();
  }

  Future<void> _loadVaultData() async {
    setState(() => _isLoading = true);
    final result = await NeonSyncService.fetchVaultItems(
      email: widget.userEmail,
      userId: _activeUserId,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _activeUserId = result['userId'] ?? _activeUserId;
        _passwords = result['passwords'] ?? [];
        _secrets = result['secrets'] ?? [];
        _contacts = result['contacts'] ?? [];
        _birthdays = result['birthdays'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
      default:
        AddBirthdayModal.show(
          context: context,
          userId: _activeUserId!,
          onAdded: _loadVaultData,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _passwords.length + _secrets.length + _contacts.length + _birthdays.length;

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
            ),

            // 🍵 2. Typography Category Filter Tabs (Zero Icons)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final bool isSelected = _selectedTabIndex == index;
                  final tab = _tabs[index];

                  int count = 0;
                  if (index == 0) count = _passwords.length;
                  if (index == 1) count = _secrets.length;
                  if (index == 2) count = _contacts.length;
                  if (index == 3) count = _birthdays.length;

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

            // 📋 3. Dynamic Real List from Neon
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMatcha),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVaultData,
                      color: AppColors.primaryMatcha,
                      child: _buildCurrentList(),
                    ),
            ),
          ],
        ),
      ),

      // ➕ Floating Action Button for Adding Data (Text-Only Label)
      floatingActionButton: FloatingActionButton.extended(
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
          onPinnedToggled: () => _reSortListAndNotify(_contacts, null),
          onDelete: (item) => _confirmDeleteItem(
            title: item['name'] ?? 'Contact',
            itemTypeLabel: 'Contact',
            type: 'contact',
            itemId: item['id'].toString(),
            targetList: _contacts,
          ),
        );
      case 3:
      default:
        return BirthdaysTabView(
          items: _birthdays,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_birthdays, 'Birthday updated successfully!'),
          onPinnedToggled: () => _reSortListAndNotify(_birthdays, null),
          onDelete: (item) => _confirmDeleteItem(
            title: item['name'] ?? 'Birthday',
            itemTypeLabel: 'Birthday',
            type: 'birthday',
            itemId: item['id'].toString(),
            targetList: _birthdays,
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
        final aPinned = (a['is_pinned'] == true) ? 1 : 0;
        final bPinned = (b['is_pinned'] == true) ? 1 : 0;
        if (aPinned != bPinned) return bPinned.compareTo(aPinned);
        return (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString());
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
