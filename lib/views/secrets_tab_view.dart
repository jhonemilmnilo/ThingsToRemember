import 'package:flutter/material.dart';
import '../drawers/secret_drawer.dart';
import 'components/empty_tab_view.dart';
import 'components/vault_item_card.dart';

class SecretsTabView extends StatelessWidget {
  final List<dynamic> items;
  final String? userId;
  final VoidCallback onSaved;
  final VoidCallback onPinnedToggled;

  const SecretsTabView({
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
        tabTitle: 'Secrets',
        explanation:
            'No private secrets yet. Safely store recovery codes, WiFi passwords, and private personal memos.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isPinned = item['is_pinned'] == true;

        return VaultItemCard(
          title: item['title'] ?? 'Secret Note',
          subtitle: item['content'] ?? '',
          isPinned: isPinned,
          onTap: () {
            if (userId == null) return;
            SecretDrawer.show(
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
