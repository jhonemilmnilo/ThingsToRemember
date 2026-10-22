import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    this.userName = 'Jhon Emil',
    this.userEmail = 'jhonemil@example.com',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Passwords', 'icon': LucideIcons.keyRound},
    {'title': 'Secrets', 'icon': LucideIcons.lock},
    {'title': 'Contacts', 'icon': LucideIcons.phoneCall},
    {'title': 'Birthdays', 'icon': LucideIcons.cake},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oatMilkBg,
      body: SafeArea(
        child: Column(
          children: [
            // 🌿 1. Vault Header
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
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.sageMatcha,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'PassKeep Life Vault • Encrypted',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // App Icon Mini Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.pistachioMint, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryMatcha.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
            ),

            // 🔍 2. Minimalist Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderMuted, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: const Row(
                  children: [
                    Icon(LucideIcons.search, size: 20, color: AppColors.sageMatcha),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search vault, secrets & contacts...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🍵 3. Category Filter Tabs
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

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryMatcha : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryMatcha : AppColors.borderMuted,
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryMatcha.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tab['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.sageMatcha,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 📋 4. Content Area Based on Active Tab
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildPasswordsView(),
                  _buildSecretsView(),
                  _buildContactsView(),
                  _buildBirthdaysView(),
                ],
              ),
            ),
          ],
        ),
      ),

      // ➕ Floating Action Button for Adding Data
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open dynamic add modal based on selected tab
        },
        backgroundColor: AppColors.primaryMatcha,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
        label: Text(
          'Add ${_tabs[_selectedTabIndex]['title']}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // 1. Passwords View
  Widget _buildPasswordsView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      children: [
        _buildVaultCard(
          icon: LucideIcons.globe,
          title: 'Google Account',
          subtitle: 'jhonemil@gmail.com',
          tag: 'Work & Personal',
          tagColor: AppColors.pistachioMint,
        ),
        _buildVaultCard(
          icon: LucideIcons.smartphone,
          title: 'Facebook / Meta',
          subtitle: '09123456789',
          tag: 'Social',
          tagColor: AppColors.sageMatcha,
        ),
        _buildVaultCard(
          icon: LucideIcons.creditCard,
          title: 'BDO Online Banking',
          subtitle: 'jhon_bdo_user',
          tag: 'Finance',
          tagColor: const Color(0xFFC8963E),
        ),
      ],
    );
  }

  // 2. Secrets View
  Widget _buildSecretsView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      children: [
        _buildVaultCard(
          icon: LucideIcons.shieldAlert,
          title: 'House Safe Combination',
          subtitle: '•••• •••• ••••',
          tag: 'Top Secret',
          tagColor: AppColors.alertPersimmon,
        ),
        _buildVaultCard(
          icon: LucideIcons.wifi,
          title: 'Home Fiber WiFi Password',
          subtitle: 'MatchaPasscode#2026',
          tag: 'Home Network',
          tagColor: AppColors.pistachioMint,
        ),
      ],
    );
  }

  // 3. Contacts View
  Widget _buildContactsView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      children: [
        _buildVaultCard(
          icon: LucideIcons.userCheck,
          title: 'Nanay (Emergency)',
          subtitle: '+63 917 123 4567',
          tag: 'Family',
          tagColor: AppColors.sageMatcha,
          isPhoneAction: true,
        ),
        _buildVaultCard(
          icon: LucideIcons.heartPulse,
          title: 'Family Doctor',
          subtitle: '+63 928 987 6543',
          tag: 'Medical',
          tagColor: AppColors.primaryMatcha,
          isPhoneAction: true,
        ),
      ],
    );
  }

  // 4. Birthdays View
  Widget _buildBirthdaysView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      children: [
        // Birthday Reminder Banner
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.pistachioMint.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pistachioMint, width: 1.2),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.sparkles, color: AppColors.primaryMatcha, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upcoming: Nanay\'s birthday is coming up soon!',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryMatcha,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildVaultCard(
          icon: LucideIcons.cake,
          title: 'Nanay',
          subtitle: 'March 14 • Mother',
          tag: 'Mother',
          tagColor: AppColors.sageMatcha,
        ),
        _buildVaultCard(
          icon: LucideIcons.cake,
          title: 'Tatay',
          subtitle: 'August 28 • Father',
          tag: 'Father',
          tagColor: AppColors.primaryMatcha,
        ),
      ],
    );
  }

  // Reusable Vault Card Widget
  Widget _buildVaultCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    bool isPhoneAction = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderMuted, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: tagColor),
          ),
          const SizedBox(width: 14),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Quick Action Icon (Copy or Call)
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primaryMatcha,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 1),
                  content: Text(
                    isPhoneAction ? 'Calling $title...' : 'Copied to clipboard!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            },
            icon: Icon(
              isPhoneAction ? LucideIcons.phone : LucideIcons.copy,
              size: 18,
              color: AppColors.sageMatcha,
            ),
          ),
        ],
      ),
    );
  }
}
