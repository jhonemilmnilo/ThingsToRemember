import 'package:flutter/foundation.dart';
import 'local_vault_db.dart';
import '../neon_sync_service.dart';

class SyncStatusResult {
  final bool success;
  final String message;
  final int syncedCount;
  final bool isOffline;

  const SyncStatusResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.isOffline = false,
  });
}

class VaultSyncCoordinator {
  VaultSyncCoordinator._();
  static final VaultSyncCoordinator instance = VaultSyncCoordinator._();

  final LocalVaultDb _db = LocalVaultDb.instance;

  /// 🌟 1-Click Sync: Push local offline changes, then Pull fresh remote data
  Future<SyncStatusResult> syncVault({
    required String userEmail,
    required String userId,
  }) async {
    int pushedCount = 0;

    // -------------------------------------------------------------
    // PHASE 1: PUSH DIRTY RECORDS (where is_synced == 0)
    // -------------------------------------------------------------
    try {
      final dirtyItems = await _db.getUnsyncedItems(userId);

      // 1. Process Credentials
      pushedCount += await _pushTableItems(
        tableName: 'local_credentials',
        type: 'password',
        userId: userId,
        items: dirtyItems['credentials'] ?? [],
      );

      // 2. Process Secrets
      pushedCount += await _pushTableItems(
        tableName: 'local_secure_notes',
        type: 'secret',
        userId: userId,
        items: dirtyItems['secure_notes'] ?? [],
      );

      // 3. Process Contacts
      pushedCount += await _pushTableItems(
        tableName: 'local_emergency_contacts',
        type: 'contact',
        userId: userId,
        items: dirtyItems['emergency_contacts'] ?? [],
      );

      // 4. Process Birthdays
      pushedCount += await _pushTableItems(
        tableName: 'local_family_members',
        type: 'birthday',
        userId: userId,
        items: dirtyItems['family_members'] ?? [],
      );

      // 5. Process WiFi
      pushedCount += await _pushTableItems(
        tableName: 'local_wifi_networks',
        type: 'wifi',
        userId: userId,
        items: dirtyItems['wifi_networks'] ?? [],
      );
    } catch (pushErr) {
      debugPrint('⚠️ Push phase error (likely offline): $pushErr');
      return const SyncStatusResult(
        success: false,
        isOffline: true,
        message: 'No internet connection. Saved locally on device.',
      );
    }

    // -------------------------------------------------------------
    // PHASE 2: PULL REMOTE RECORDS & HYDRATE LOCAL SQLITE
    // -------------------------------------------------------------
    try {
      final remoteData = await NeonSyncService.fetchVaultItems(
        email: userEmail,
        userId: userId,
      );

      if (remoteData == null) {
        return SyncStatusResult(
          success: pushedCount > 0,
          isOffline: true,
          syncedCount: pushedCount,
          message: pushedCount > 0
              ? 'All items are synced'
              : 'All items are synced locally',
        );
      }

      if (remoteData['unauthorized'] == true) {
        return const SyncStatusResult(
          success: false,
          message: 'Session expired. Please re-authenticate.',
        );
      }

      // Upsert pulled items from remote without overwriting local unsynced edits
      await _hydrateTableFromRemote(
        tableName: 'local_credentials',
        remoteList: remoteData['passwords'] ?? [],
        userId: userId,
      );

      await _hydrateTableFromRemote(
        tableName: 'local_secure_notes',
        remoteList: remoteData['secrets'] ?? [],
        userId: userId,
      );

      await _hydrateTableFromRemote(
        tableName: 'local_emergency_contacts',
        remoteList: remoteData['contacts'] ?? [],
        userId: userId,
      );

      await _hydrateTableFromRemote(
        tableName: 'local_family_members',
        remoteList: remoteData['birthdays'] ?? [],
        userId: userId,
      );

      await _hydrateTableFromRemote(
        tableName: 'local_wifi_networks',
        remoteList: remoteData['wifi'] ?? [],
        userId: userId,
      );

      return SyncStatusResult(
        success: true,
        isOffline: false,
        syncedCount: pushedCount,
        message: 'All items are synced',
      );
    } catch (pullErr) {
      debugPrint('⚠️ Pull phase error: $pullErr');
      return SyncStatusResult(
        success: pushedCount > 0,
        isOffline: true,
        syncedCount: pushedCount,
        message: 'All items are synced locally',
      );
    }
  }

  /// Helper to push items from a table to Neon Worker
  Future<int> _pushTableItems({
    required String tableName,
    required String type,
    required String userId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) return 0;

    int successCount = 0;
    final List<String> successfullySyncedIds = [];
    final List<String> successfullyDeletedIds = [];

    for (final item in items) {
      final String id = item['id'].toString();
      final bool isDeleted = (item['is_deleted'] == 1);

      if (isDeleted) {
        // Send DELETE to Cloudflare Worker
        final deleted = await NeonSyncService.deleteVaultItem(
          userId: userId,
          itemId: id,
          type: type,
        );
        if (deleted) {
          successfullyDeletedIds.add(id);
          successCount++;
        }
      } else {
        // Send CREATE / UPDATE
        final payload = Map<String, dynamic>.from(item);
        payload.remove('is_synced');
        payload.remove('is_deleted');

        final updated = await NeonSyncService.updateVaultItem(
          userId: userId,
          itemId: id,
          type: type,
          data: payload,
        );

        if (updated) {
          successfullySyncedIds.add(id);
          successCount++;
        } else {
          // If update failed (e.g. item doesn't exist on server yet), try create
          final createdItem = await NeonSyncService.createVaultItem(
            userId: userId,
            type: type,
            data: payload,
          );
          if (createdItem != null) {
            final serverId = createdItem['id']?.toString();
            if (serverId != null && serverId != id) {
              // Replace local temporary UUID with server generated UUID to prevent duplicates
              final db = await _db.database;
              await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
              payload['id'] = serverId;
              payload['is_synced'] = 1;
              await _db.upsertLocalItem(
                table: tableName,
                row: payload,
                markDirty: false,
              );
            } else {
              successfullySyncedIds.add(id);
            }
            successCount++;
          }
        }
      }
    }

    if (successfullySyncedIds.isNotEmpty || successfullyDeletedIds.isNotEmpty) {
      await _db.markBatchSynced(
        table: tableName,
        activeIds: successfullySyncedIds,
        deletedIds: successfullyDeletedIds,
      );
    }

    return successCount;
  }

  /// Helper to upsert pulled items into SQLite without clobbering dirty edits
  Future<void> _hydrateTableFromRemote({
    required String tableName,
    required List<dynamic> remoteList,
    required String userId,
  }) async {
    final db = await _db.database;

    // Get current dirty IDs that have pending local edits
    final dirtyRows = await db.query(
      tableName,
      columns: ['id'],
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    final dirtyIds = dirtyRows.map((r) => r['id'].toString()).toSet();

    for (final raw in remoteList) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id']?.toString();
      if (id == null) continue;

      // 🛡️ DO NOT OVERWRITE if user has a pending offline edit on this row!
      if (dirtyIds.contains(id)) {
        continue;
      }

      final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
      row['user_id'] = userId;
      // Handle boolean to integer for sqlite
      if (row.containsKey('is_pinned')) {
        row['is_pinned'] = (row['is_pinned'] == true || row['is_pinned'] == 1) ? 1 : 0;
      }

      await _db.upsertLocalItem(
        table: tableName,
        row: row,
        markDirty: false, // 👈 Remote copy is already in sync!
      );
    }
  }
}
