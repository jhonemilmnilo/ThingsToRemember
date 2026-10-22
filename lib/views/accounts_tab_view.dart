import 'package:flutter/material.dart';
import '../drawers/account_drawer.dart';
import 'components/empty_tab_view.dart';
import 'components/vault_item_card.dart';

class AccountsTabView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyTabView(
        tabTitle: 'Accounts',
        explanation:
            'No saved passwords or logins yet. Keep all your streaming, bank & work logins in one secure vault.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isPinned = item['is_pinned'] == true;

        return VaultItemCard(
          title: item['title'] ?? 'Account',
          subtitle: item['username_or_email'] ?? '',
          noteContent: item['notes'],
          isPinned: isPinned,
          onTap: () {
            if (userId == null) return;
            AccountDrawer.show(
              context: context,
              item: item,
              userId: userId!,
              onSaved: onSaved,
            );
          },
        );
      },
    );
  }
}
