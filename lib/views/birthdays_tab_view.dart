import 'package:flutter/material.dart';
import '../drawers/birthday_drawer.dart';
import 'components/empty_tab_view.dart';
import 'components/vault_item_card.dart';

class BirthdaysTabView extends StatelessWidget {
  final List<dynamic> items;
  final String? userId;
  final VoidCallback onSaved;
  final VoidCallback onPinnedToggled;

  const BirthdaysTabView({
    super.key,
    required this.items,
    required this.userId,
    required this.onSaved,
    required this.onPinnedToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyTabView(
        tabTitle: 'Birthdays',
        explanation:
            'No family birthdays recorded yet. Keep track of important family milestones and anniversaries.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isPinned = item['is_pinned'] == true;

        return VaultItemCard(
          title: item['name'] ?? 'Family',
          subtitle: 'Born: ${item['birthdate']?.toString().split('T').first ?? ''}',
          noteContent: item['relationship'],
          isPinned: isPinned,
          onTap: () {
            if (userId == null) return;
            BirthdayDrawer.show(
              context: context,
              item: item,
              userId: userId!,
              onSaved: onSaved,
              onPinnedToggled: onPinnedToggled,
            );
          },
        );
      },
    );
  }
}
