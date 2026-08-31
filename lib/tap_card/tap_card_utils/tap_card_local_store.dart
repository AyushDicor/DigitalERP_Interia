// Offline-first storage for the Tap Card module, ported from TapCard's
// LocalStorageService + the sync-queue half of its ContactProvider.
//
// Why this module has one when no other module does: cards get captured
// in the field — at a stall, in a lobby, in a basement — where the ERP modules
// are simply not used. Losing a scanned card because there was no signal is the
// one failure this module can't afford, so writes land on disk first and are
// replayed to the server later.
//
// Two pieces of state, both in GetStorage (already a dependency, used app-wide):
//   • cache  — the last known list of cards, per user, for instant cold start
//   • queue  — pending create/update/delete operations awaiting a connection
//
// Both are namespaced by "<compid>_<userid>" so switching company or user never
// shows the previous account's wallet.

import 'dart:convert';
import 'dart:developer';

import 'package:get_storage/get_storage.dart';

import '../tap_card_models.dart';

/// A single queued write, replayed in order once the device is back online.
class TapCardPendingOp {
  static const opSave = 'save';
  static const opDelete = 'delete';

  final String op;

  /// For a save: the full card. For a delete: only [cardId] is meaningful.
  final TapCardModel? card;
  final int cardId;

  /// Local key of the card this op belongs to, so a queued update can be
  /// matched to the create that preceded it.
  final String localKey;

  TapCardPendingOp({
    required this.op,
    this.card,
    this.cardId = 0,
    this.localKey = '',
  });

  Map<String, dynamic> toJson() => {
    'op': op,
    'cardId': cardId,
    'localKey': localKey,
    if (card != null) 'card': card!.toJson(),
  };

  factory TapCardPendingOp.fromJson(Map<String, dynamic> j) => TapCardPendingOp(
    op: '${j['op']}',
    cardId: j['cardId'] is int
        ? j['cardId'] as int
        : int.tryParse('${j['cardId']}') ?? 0,
    localKey: '${j['localKey'] ?? ''}',
    card: j['card'] is Map<String, dynamic>
        ? TapCardModel.fromJson(j['card'] as Map<String, dynamic>)
        : null,
  );
}

class TapCardLocalStore {
  static final GetStorage _box = GetStorage();

  static String _cacheKey(String compid, String userid) =>
      'tapcard_cache_${compid}_$userid';
  static String _queueKey(String compid, String userid) =>
      'tapcard_queue_${compid}_$userid';

  // ── Cached list ─────────────────────────────────────────────────────────
  static List<TapCardModel> readCache(String compid, String userid) {
    try {
      final raw = _box.read(_cacheKey(compid, userid));
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List;
      return list
          .map((e) => TapCardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // A corrupt cache must never block the screen — fall back to empty and
      // let the next server load repopulate it.
      log('TapCard: cache read failed — $e');
      return [];
    }
  }

  static Future<void> writeCache(
    String compid,
    String userid,
    List<TapCardModel> cards,
  ) async {
    try {
      await _box.write(
        _cacheKey(compid, userid),
        jsonEncode(cards.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      log('TapCard: cache write failed — $e');
    }
  }

  // ── Pending write queue ─────────────────────────────────────────────────
  static List<TapCardPendingOp> readQueue(String compid, String userid) {
    try {
      final raw = _box.read(_queueKey(compid, userid));
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List;
      return list
          .map((e) => TapCardPendingOp.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('TapCard: queue read failed — $e');
      return [];
    }
  }

  static Future<void> writeQueue(
    String compid,
    String userid,
    List<TapCardPendingOp> ops,
  ) async {
    try {
      await _box.write(
        _queueKey(compid, userid),
        jsonEncode(ops.map((o) => o.toJson()).toList()),
      );
    } catch (e) {
      log('TapCard: queue write failed — $e');
    }
  }

  /// Append an op, collapsing redundant work for the same card:
  ///   • a queued save replaces an earlier queued save (latest wins)
  ///   • a delete drops any queued saves for a card that never reached the
  ///     server, and then needs no server call of its own
  static Future<void> enqueue(
    String compid,
    String userid,
    TapCardPendingOp op,
  ) async {
    final ops = readQueue(compid, userid);

    if (op.op == TapCardPendingOp.opSave) {
      ops.removeWhere(
        (o) => o.op == TapCardPendingOp.opSave && o.localKey == op.localKey,
      );
      ops.add(op);
    } else {
      final wasNeverSaved = op.cardId <= 0;
      ops.removeWhere((o) => o.localKey == op.localKey);
      // Only a card the server knows about needs a delete call.
      if (!wasNeverSaved) ops.add(op);
    }

    await writeQueue(compid, userid, ops);
  }

  static Future<void> clearQueue(String compid, String userid) =>
      writeQueue(compid, userid, const []);
}
