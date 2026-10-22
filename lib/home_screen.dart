import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'theme.dart';
import 'neon_sync_service.dart';
import 'login_screen.dart';

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
    {'type': 'password', 'title': 'Passwords'},
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
                    _buildModalInput(controller: field2, label: 'Secret Content / Note', maxLines: 3),
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

                  const SizedBox(height: 20),

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
                      itemData = {
                        'title': field1.text.trim(),
                        'username_or_email': field2.text.trim(),
                        'password': field3.text.trim(),
                        'notes': field4.text.trim(),
                      };
                    } else if (type == 'secret') {
                      itemData = {
                        'title': field1.text.trim(),
                        'content': field2.text.trim(),
                      };
                    } else if (type == 'contact') {
                      itemData = {
                        'name': field1.text.trim(),
                        'phone_number': field2.text.trim(),
                        'relationship': field3.text.trim(),
                      };
                    } else if (type == 'birthday') {
                      itemData = {
                        'name': field1.text.trim(),
                        'birthdate': field2.text.trim().isEmpty ? '2000-01-01' : field2.text.trim(),
                        'relationship': field3.text.trim(),
                      };
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
                  child: const Text('Save to Neon Vault', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
        label: Text(
          'Add ${_tabs[_selectedTabIndex]['title']}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCurrentList() {
    List<dynamic> items = [];
    if (_selectedTabIndex == 0) items = _passwords;
    if (_selectedTabIndex == 1) items = _secrets;
    if (_selectedTabIndex == 2) items = _contacts;
    if (_selectedTabIndex == 3) items = _birthdays;

    if (items.isEmpty) {
      final String tabName = _tabs[_selectedTabIndex]['title']!;

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clean Typography Container (Zero Icons)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.pistachioMint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'VAULT STATUS',
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryMatcha,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Your $tabName Vault is Empty',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              // Pure Minimalist Typography Note (No Box/Card)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _getTabEmptyExplanation(_selectedTabIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'End-to-End Encrypted via Neon Cloud',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageMatcha,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Tap "Add $tabName" below to get started',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (_selectedTabIndex == 0) {
          return _buildItemCard(
            title: item['title'] ?? 'Account',
            subtitle: item['username_or_email'] ?? '',
            noteContent: item['notes'],
            onTap: () => _openItemDetail(item, 'password'),
          );
        } else if (_selectedTabIndex == 1) {
          return _buildItemCard(
            title: item['title'] ?? 'Secret Note',
            subtitle: item['content'] ?? '',
            onTap: () => _openItemDetail(item, 'secret'),
          );
        } else if (_selectedTabIndex == 2) {
          return _buildItemCard(
            title: item['name'] ?? 'Contact',
            subtitle: item['phone_number'] ?? '',
            noteContent: item['notes'] ?? item['relationship'],
            onTap: () => _openItemDetail(item, 'contact'),
          );
        } else {
          return _buildItemCard(
            title: item['name'] ?? 'Family',
            subtitle: 'Born: ${item['birthdate']?.toString().split('T').first ?? ''}',
            noteContent: item['relationship'],
            onTap: () => _openItemDetail(item, 'birthday'),
          );
        }
      },
    );
  }

  Widget _buildItemCard({
    required String title,
    required String subtitle,
    String? noteContent,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderMuted, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: AppColors.primaryMatcha.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryMatcha.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                if (noteContent != null && noteContent.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: ${noteContent.trim()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.sageMatcha,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openItemDetail(dynamic item, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool showSecretPassword = false;
        bool isEditing = false;
        bool isSaving = false;

        // Editable controllers
        final edit1 = TextEditingController(
          text: type == 'password' || type == 'secret' ? (item['title'] ?? '') : (item['name'] ?? ''),
        );
        final edit2 = TextEditingController(
          text: type == 'password'
              ? (item['username_or_email'] ?? '')
              : (type == 'secret'
                  ? (item['content'] ?? '')
                  : (type == 'contact'
                      ? (item['phone_number'] ?? '')
                      : (item['birthdate']?.toString().split('T').first ?? ''))),
        );
        final edit3 = TextEditingController(
          text: type == 'password'
              ? (item['encrypted_password'] ?? '')
              : (type == 'contact' || type == 'birthday' ? (item['relationship'] ?? '') : ''),
        );
        final edit4 = TextEditingController(
          text: item['notes'] ?? '',
        );

        return StatefulBuilder(
          builder: (context, setDetailState) {
            String title = '';
            List<Map<String, String>> fields = [];

            if (type == 'password') {
              title = item['title'] ?? 'Password Detail';
              fields = [
                {'label': 'Service / Title', 'value': item['title'] ?? ''},
                {'label': 'Username or Email', 'value': item['username_or_email'] ?? ''},
                {'label': 'Password', 'value': item['encrypted_password'] ?? '', 'isPassword': 'true'},
                if (item['notes'] != null && item['notes'].toString().trim().isNotEmpty)
                  {'label': 'Notes / Hint', 'value': item['notes'].toString()},
              ];
            } else if (type == 'secret') {
              title = item['title'] ?? 'Secret Note';
              fields = [
                {'label': 'Title', 'value': item['title'] ?? ''},
                {'label': 'Content', 'value': item['content'] ?? ''},
              ];
            } else if (type == 'contact') {
              title = item['name'] ?? 'Contact';
              fields = [
                {'label': 'Name', 'value': item['name'] ?? ''},
                {'label': 'Phone Number', 'value': item['phone_number'] ?? ''},
                {'label': 'Relationship', 'value': item['relationship'] ?? 'General'},
                if (item['notes'] != null && item['notes'].toString().trim().isNotEmpty)
                  {'label': 'Notes', 'value': item['notes'].toString()},
              ];
            } else {
              title = item['name'] ?? 'Family Birthday';
              fields = [
                {'label': 'Name', 'value': item['name'] ?? ''},
                {'label': 'Birthdate', 'value': item['birthdate']?.toString().split('T').first ?? ''},
                {'label': 'Relationship', 'value': item['relationship'] ?? 'Family'},
              ];
            }

            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit ${type == 'password' ? 'Password' : 'Item'}' : title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setDetailState(() {
                                    isEditing = !isEditing;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isEditing
                                        ? AppColors.primaryMatcha.withValues(alpha: 0.15)
                                        : AppColors.oatMilkBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isEditing ? AppColors.primaryMatcha : AppColors.borderMuted,
                                    ),
                                  ),
                                  child: Text(
                                    isEditing ? 'Cancel' : 'Edit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isEditing ? AppColors.primaryMatcha : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.oatMilkBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderMuted),
                                  ),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (isEditing) ...[
                        // ✏️ Inline Edit Mode
                        if (type == 'password') ...[
                          _buildModalInput(controller: edit1, label: 'Service / Title'),
                          const SizedBox(height: 12),
                          _buildModalInput(controller: edit2, label: 'Username or Email'),
                          const SizedBox(height: 12),
                          _buildModalInput(
                            controller: edit3,
                            label: 'Password',
                            isPassword: !showSecretPassword,
                            suffix: GestureDetector(
                              onTap: () {
                                setDetailState(() {
                                  showSecretPassword = !showSecretPassword;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text(
                                    showSecretPassword ? 'Hide' : 'Show',
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
                          _buildModalInput(controller: edit4, label: 'Note / Hint (Optional)', maxLines: 3),
                        ] else if (type == 'secret') ...[
                          _buildModalInput(controller: edit1, label: 'Secret Title'),
                          const SizedBox(height: 12),
                          _buildModalInput(controller: edit2, label: 'Secret Content', maxLines: 4),
                        ] else if (type == 'contact') ...[
                          _buildModalInput(controller: edit1, label: 'Full Name'),
                          const SizedBox(height: 12),
                          _buildModalInput(controller: edit2, label: 'Phone Number'),
                          const SizedBox(height: 12),
                          _buildModalInput(controller: edit3, label: 'Relationship'),
                          const SizedBox(height: 12),
                          _buildModalInput(controller: edit4, label: 'Notes (Optional)', maxLines: 2),
                        ] else ...[
                          _buildModalInput(controller: edit1, label: 'Name'),
                          const SizedBox(height: 12),
                          _buildModalInput(controller: edit2, label: 'Birthdate (YYYY-MM-DD)'),
                          const SizedBox(height: 12),
                          _buildModalInput(controller: edit3, label: 'Relationship'),
                        ],

                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (_activeUserId == null) return;
                                    setDetailState(() => isSaving = true);

                                    Map<String, dynamic> updateData = {};
                                    if (type == 'password') {
                                      updateData = {
                                        'title': edit1.text.trim(),
                                        'username_or_email': edit2.text.trim(),
                                        'password': edit3.text.trim(),
                                        'notes': edit4.text.trim(),
                                      };
                                    } else if (type == 'secret') {
                                      updateData = {
                                        'title': edit1.text.trim(),
                                        'content': edit2.text.trim(),
                                      };
                                    } else if (type == 'contact') {
                                      updateData = {
                                        'name': edit1.text.trim(),
                                        'phone_number': edit2.text.trim(),
                                        'relationship': edit3.text.trim(),
                                        'notes': edit4.text.trim(),
                                      };
                                    } else if (type == 'birthday') {
                                      updateData = {
                                        'name': edit1.text.trim(),
                                        'birthdate': edit2.text.trim(),
                                        'relationship': edit3.text.trim(),
                                      };
                                    }

                                    final success = await NeonSyncService.updateVaultItem(
                                      userId: _activeUserId!,
                                      itemId: item['id'].toString(),
                                      type: type,
                                      data: updateData,
                                    );

                                    if (!context.mounted) return;

                                    if (success) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: AppColors.primaryMatcha,
                                          behavior: SnackBarBehavior.floating,
                                          content: Text('Changes saved successfully!'),
                                        ),
                                      );
                                      _loadVaultData();
                                    } else {
                                      setDetailState(() => isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          content: Text('Failed to update. Please try again.'),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMatcha,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ] else ...[
                        // 👁️ Read-Only View Mode
                        ...fields.map((field) {
                          final bool isPassField = field['isPassword'] == 'true';
                          final String val = field['value'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.oatMilkBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderMuted),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field['label']!.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.sageMatcha,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isPassField
                                            ? (showSecretPassword ? val : ('•' * (val.isEmpty ? 8 : val.length.clamp(8, 14))))
                                            : val,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          letterSpacing: (isPassField && !showSecretPassword) ? 2.0 : 0.2,
                                        ),
                                      ),
                                    ),
                                    if (isPassField) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setDetailState(() {
                                            showSecretPassword = !showSecretPassword;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardSurface,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.borderMuted),
                                          ),
                                          child: Text(
                                            showSecretPassword ? 'Hide' : 'Show',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryMatcha,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.primaryMatcha,
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 1),
                                            content: Text('Copied ${field['label']} to clipboard!'),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.borderMuted),
                                        ),
                                        child: const Text(
                                          'Copy',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryMatcha,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getTabEmptyExplanation(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'No saved passwords or logins yet. Keep all your streaming, bank & work logins in one secure vault.';
      case 1:
        return 'No private secrets yet. Safely store recovery codes, WiFi passwords, and private personal memos.';
      case 2:
        return 'No emergency contacts saved yet. Store trusted family members, doctors, and emergency hotlines.';
      case 3:
        return 'No family birthdays recorded yet. Keep track of important family milestones and anniversaries.';
      default:
        return 'Your vault category is pristine and empty.';
    }
  }
}
