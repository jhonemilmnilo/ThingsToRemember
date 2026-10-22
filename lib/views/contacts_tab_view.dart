import 'package:flutter/material.dart';
import '../../theme.dart';
import '../drawers/contact_drawer.dart';
import 'components/empty_tab_view.dart';
import 'components/vault_item_card.dart';

class ContactsTabView extends StatefulWidget {
  final List<dynamic> items;
  final String? userId;
  final VoidCallback onSaved;
  final Function(dynamic item) onDelete;

  const ContactsTabView({
    super.key,
    required this.items,
    required this.userId,
    required this.onSaved,
    required this.onDelete,
  });

  @override
  State<ContactsTabView> createState() => _ContactsTabViewState();
}

class _ContactsTabViewState extends State<ContactsTabView> {
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
        tabTitle: 'Contacts',
        explanation:
            'No emergency contacts saved yet. Store trusted family members, doctors, and emergency hotlines.',
      );
    }

    final String query = _searchQuery.trim().toLowerCase();
    final List<dynamic> filteredItems = widget.items.where((item) {
      if (query.isEmpty) return true;
      final name = (item['name'] ?? '').toString().toLowerCase();
      final phone = (item['phone_number'] ?? '').toString().toLowerCase();
      final relationship = (item['relationship'] ?? '').toString().toLowerCase();
      return name.contains(query) || phone.contains(query) || relationship.contains(query);
    }).toList();

    return Column(
      children: [
        // 🔍 Minimalist Dedicated Search Bar for Contacts
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
                hintText: 'Search contacts (e.g. Papa, Doctor)...',
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

        // 📋 Filtered List or Empty Results
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No contacts found for "$_searchQuery"',
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

                    return VaultItemCard(
                      title: item['name'] ?? 'Contact',
                      tag: item['relationship'],
                      subtitle: item['phone_number'] ?? '',
                      noteContent: item['notes'],
                      isPinned: false,
                      isCompact: true,
                      onTap: () {
                        if (widget.userId == null) return;
                        ContactDrawer.show(
                          context: context,
                          item: item,
                          userId: widget.userId!,
                          onSaved: widget.onSaved,
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
