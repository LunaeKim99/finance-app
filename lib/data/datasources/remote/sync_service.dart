import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../pb_helper.dart';
import '../sync_queue_helper.dart';
import '../../../services/pb_client.dart';

class SyncEvent {
  final String id;
  const SyncEvent({required this.id});
}

class SyncTransactionsCompleted extends SyncEvent {
  final List<String> ids;
  const SyncTransactionsCompleted({required this.ids}) : super(id: '');
}

class SyncService extends ChangeNotifier {
  final StreamController<SyncEvent> _eventController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get events => _eventController.stream;

  final PbHelper _pbHelper;
  final SyncQueueHelper _syncQueueHelper;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isSyncing = false;
  bool _isOnline = false;
  int _pendingCount = 0;
  bool _disposed = false;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingCount => _pendingCount;

  SyncService(
    this._pbHelper,
    this._syncQueueHelper,
  ) {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    await _updatePendingCount();
    if (!_disposed) notifyListeners();
  }

  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);

      if (!wasOnline && _isOnline) {
        debugPrint('[SyncService] Back online, starting sync...');
        await syncPendingItems();
      }
      if (!_disposed) notifyListeners();
    });

    if (_isOnline) {
      syncPendingItems();
    }
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  Future<void> _updatePendingCount() async {
    _pendingCount = await _syncQueueHelper.getPendingCount();
  }

  Future<void> syncPendingItems() async {
    if (_isSyncing || !_isOnline) return;

    final connected = await PbClient.isConnected();
    if (!connected) {
      debugPrint('[SyncService] PocketBase tidak dapat dijangkau, skip sync');
      return;
    }

    _isSyncing = true;
    if (!_disposed) notifyListeners();

    try {
      final pb = _pbHelper.pb;
      final pendingItems = await _syncQueueHelper.getPendingItems();

      debugPrint('[SyncService] Found ${pendingItems.length} pending items');

      final syncedIds = <String>[];

      for (final item in pendingItems) {
        final id = item['id'] as int;
        final operation = item['operation'] as String;
        final collection = item['collection'] as String;
        final payloadStr = item['payload'] as String;

        try {
          final payload = _parsePayload(payloadStr);

          bool success = false;

          switch (operation) {
            case 'create':
              await pb.collection(collection).create(body: payload);
              success = true;
              break;
            case 'update':
              final recordId = payload['id'] as String;
              await pb.collection(collection).update(recordId, body: payload);
              success = true;
              break;
            case 'delete':
              final recordId = payload['id'] as String;
              await pb.collection(collection).delete(recordId);
              success = true;
              break;
          }

          if (success) {
            await _syncQueueHelper.markSynced(id);
            debugPrint('[SyncService] Synced $operation $collection');

            if (operation == 'create') {
              final syncedId = payload['id'] as String?;
              if (syncedId != null) {
                syncedIds.add(syncedId);
              }
            }
          }
        } catch (e) {
          debugPrint('[SyncService] Failed to sync item $id: $e');
          await _syncQueueHelper.incrementRetryCount(id);
        }
      }

      if (syncedIds.isNotEmpty && !_disposed) {
        _eventController.add(SyncTransactionsCompleted(ids: syncedIds));
      }

      await _syncQueueHelper.deleteSyncedItems();
      await _updatePendingCount();
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
    }

    _isSyncing = false;
    if (!_disposed) notifyListeners();
  }

  Map<String, dynamic> _parsePayload(String payloadStr) {
    try {
      return jsonDecode(payloadStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopListening();
    _eventController.close();
    super.dispose();
  }
}
