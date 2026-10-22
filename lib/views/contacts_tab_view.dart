import 'package:flutter/material.dart';
import '../drawers/contact_drawer.dart';
import 'components/empty_tab_view.dart';
import 'components/vault_item_card.dart';

class ContactsTabView extends StatelessWidget {
  final List<dynamic> items;
  final String? userId;
  final VoidCallback onSaved;
  final VoidCallback onPinnedToggled;
  final Function(dynamic item) onDelete;

  const ContactsTabView({
    super.key,
    required this.items,
    required this.userId,
    required this.onSaved,
    required this.onPinnedToggled,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyTabView(
        tabTitle: 'Contacts',
        explanation:
            'No emergency contacts saved yet. Store trusted family members, doctors, and emergency hotlines.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isPinned = item['is_pinned'] == true;

        return VaultItemCard(
          title: item['name'] ?? 'Contact',
          subtitle: item['phone_number'] ?? '',
          noteContent: item['notes'] ?? item['relationship'],
          isPinned: isPinned,
          onTap: () {
            if (userId == null) return;
            ContactDrawer.show(
              context: context,
              item: item,
              userId: userId!,
              onSaved: onSaved,
              onPinnedToggled: onPinnedToggled,
            );
          },
          onLongPress: () => onDelete(item),
        );
      },
    );
  }
}
