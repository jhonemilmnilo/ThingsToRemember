import 'package:flutter/material.dart';
import '../../theme.dart';
import '../drawers/secret_drawer.dart';
import 'components/empty_tab_view.dart';
import 'components/vault_item_card.dart';

class SecretsTabView extends StatefulWidget {
  final List<dynamic> items;
  final String? userId;
  final VoidCallback onSaved;
  final VoidCallback onPinnedToggled;
  final Function(dynamic item) onDelete;

  const SecretsTabView({
    super.key,
    required this.items,
    required this.userId,
    required this.onSaved,
    required this.onPinnedToggled,
    required this.onDelete,
  });

  @override
  State<SecretsTabView> createState() => _SecretsTabViewState();
}

class _SecretsTabViewState extends State<SecretsTabView> {
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
        tabTitle: 'Things to Remember',
        explanation:
            'No items saved yet. Safely store recovery codes, WiFi passwords, and private personal memos.',
      );
    }

    final String query = _searchQuery.trim().toLowerCase();
    final List<dynamic> filteredItems = widget.items.where((item) {
      if (query.isEmpty) return true;
      final title = (item['title'] ?? '').toString().toLowerCase();
      return title.contains(query);
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
                hintText: 'Search things to remember (e.g. WiFi, Codes)...',
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
                          'No items found for "$_searchQuery"',
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
                      title: item['title'] ?? 'Secret Note',
                      // Omit subtitle/content to keep secrets private in list
                      subtitle: null,
                      isPinned: isPinned,
                      isCompact: true,
                      onTap: () {
                        if (widget.userId == null) return;
                        SecretDrawer.show(
                          context: context,
                          item: item,
                          userId: widget.userId!,
                          onSaved: widget.onSaved,
                          onPinnedToggled: widget.onPinnedToggled,
                        );
                      },
                      onLongPress: () => widget.onDelete(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
