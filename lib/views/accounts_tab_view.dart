import 'package:flutter/material.dart';
import '../../theme.dart';
import '../drawers/account_drawer.dart';
import 'components/empty_tab_view.dart';
import 'components/vault_item_card.dart';

class AccountsTabView extends StatefulWidget {
  final List<dynamic> items;
  final String? userId;
  final VoidCallback onSaved;

  const AccountsTabView({
    super.key,
    required this.items,
    required this.userId,
    required this.onSaved,
  });

  @override
  State<AccountsTabView> createState() => _AccountsTabViewState();
}

class _AccountsTabViewState extends State<AccountsTabView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const EmptyTabView(
        tabTitle: 'Accounts',
        explanation:
            'No saved passwords or logins yet. Keep all your streaming, bank & work logins in one secure vault.',
      );
    }

    final String query = _searchQuery.trim().toLowerCase();
    final List<dynamic> filteredItems = widget.items.where((item) {
      if (query.isEmpty) return true;
      final title = (item['title'] ?? '').toString().toLowerCase();
      final user = (item['username_or_email'] ?? '').toString().toLowerCase();
      final notes = (item['notes'] ?? '').toString().toLowerCase();
      return title.contains(query) || user.contains(query) || notes.contains(query);
    }).toList();

    return Column(
      children: [
        // 🔍 Minimalist Dedicated Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderMuted, width: 1.2),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search accounts (e.g. Netflix, Gmail)...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.sageMatcha,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        // 📋 Filtered List or No Results State
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No accounts found for "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Text(
                            'Clear search',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryMatcha,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final bool isPinned = item['is_pinned'] == true;

                    return VaultItemCard(
                      title: item['title'] ?? 'Account',
                      subtitle: item['username_or_email'] ?? '',
                      noteContent: item['notes'],
                      isPinned: isPinned,
                      isCompact: true,
                      onTap: () {
                        if (widget.userId == null) return;
                        AccountDrawer.show(
                          context: context,
                          item: item,
                          userId: widget.userId!,
                          onSaved: widget.onSaved,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
