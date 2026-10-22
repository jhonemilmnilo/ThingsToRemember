import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'theme.dart';
import 'neon_sync_service.dart';
import 'login_screen.dart';
import 'views/accounts_tab_view.dart';
import 'views/secrets_tab_view.dart';
import 'views/contacts_tab_view.dart';
import 'views/birthdays_tab_view.dart';

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
    final activeTab = _tabs[_selectedTabIndex];
    final String type = activeTab['type']!;
    final String title = activeTab['title']!;

    final TextEditingController field1 = TextEditingController();
    final TextEditingController field2 = TextEditingController();
    final TextEditingController field3 = TextEditingController();
    final TextEditingController field4 = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.oatMilkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool obscurePassword = true;
        bool isPinned = false;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 22,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New $title',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.borderMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (type == 'password') ...[
                    _buildModalInput(controller: field1, label: 'Account / Service (e.g. Netflix, Gmail)'),
                    const SizedBox(height: 12),
                    _buildModalInput(controller: field2, label: 'Username or Email'),
                    const SizedBox(height: 12),
                    _buildModalInput(
                      controller: field3,
                      label: 'Password',
                      isPassword: obscurePassword,
                      suffix: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              obscurePassword ? 'Show' : 'Hide',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryMatcha,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildModalInput(
                      controller: field4,
                      label: 'Note / Hint (Optional)',
                      maxLines: 3,
                    ),
                  ] else if (type == 'secret') ...[
                    _buildModalInput(controller: field1, label: 'Secret Title (e.g. WiFi, Safe Pin)'),
                    const SizedBox(height: 12),
                    _buildModalInput(controller: field2, label: 'Secret Content / Note', maxLines: 4),
                  ] else if (type == 'contact') ...[
                    _buildModalInput(controller: field1, label: 'Full Name'),
                    const SizedBox(height: 12),
                    _buildModalInput(controller: field2, label: 'Phone Number (e.g. +63 917...)'),
                    const SizedBox(height: 12),
                    _buildModalInput(controller: field3, label: 'Relationship / Note (e.g. Mama, Doctor)'),
                  ] else if (type == 'birthday') ...[
                    _buildModalInput(controller: field1, label: 'Family Member Name'),
                    const SizedBox(height: 12),
                    _buildModalInput(controller: field2, label: 'Birthdate (YYYY-MM-DD)'),
                    const SizedBox(height: 12),
                    _buildModalInput(controller: field3, label: 'Relationship (e.g. Mother, Brother)'),
                  ],

                  if (type != 'password') ...[
                    const SizedBox(height: 14),

                    // 📌 Clean Text & Toggle (No Card Box)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pin to Top',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Keep this priority item at the top',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPinned ? AppColors.primaryMatcha : AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: isPinned,
                            activeTrackColor: AppColors.primaryMatcha,
                            onChanged: (val) {
                              setModalState(() {
                                isPinned = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_activeUserId == null) {
                          Navigator.pop(ctx);
                          return;
                        }

                        Map<String, dynamic> itemData = {};
                        if (type == 'password') {
                          itemData.addAll({
                            'title': field1.text.trim(),
                            'username_or_email': field2.text.trim(),
                            'password': field3.text.trim(),
                            'notes': field4.text.trim(),
                          });
                        } else if (type == 'secret') {
                          itemData.addAll({
                            'title': field1.text.trim(),
                            'content': field2.text.trim(),
                            'is_pinned': isPinned,
                          });
                        } else if (type == 'contact') {
                          itemData.addAll({
                            'name': field1.text.trim(),
                            'phone_number': field2.text.trim(),
                            'relationship': field3.text.trim(),
                            'is_pinned': isPinned,
                          });
                        } else if (type == 'birthday') {
                          itemData.addAll({
                            'name': field1.text.trim(),
                            'birthdate': field2.text.trim().isEmpty ? '2000-01-01' : field2.text.trim(),
                            'relationship': field3.text.trim(),
                            'is_pinned': isPinned,
                          });
                        }

                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);

                        await NeonSyncService.createVaultItem(
                          userId: _activeUserId!,
                          type: type,
                          data: itemData,
                        );

                        await _loadVaultData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMatcha,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalInput({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    int maxLines = 1,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardSurface,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryMatcha, width: 1.5),
        ),
      ),
    );
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
        );
      case 1:
        return SecretsTabView(
          items: _secrets,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_secrets, 'Secret updated successfully!'),
          onPinnedToggled: () => _reSortListAndNotify(_secrets, null),
        );
      case 2:
        return ContactsTabView(
          items: _contacts,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_contacts, 'Contact updated successfully!'),
          onPinnedToggled: () => _reSortListAndNotify(_contacts, null),
        );
      case 3:
      default:
        return BirthdaysTabView(
          items: _birthdays,
          userId: _activeUserId,
          onSaved: () => _reSortListAndNotify(_birthdays, 'Birthday updated successfully!'),
          onPinnedToggled: () => _reSortListAndNotify(_birthdays, null),
        );
    }
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
