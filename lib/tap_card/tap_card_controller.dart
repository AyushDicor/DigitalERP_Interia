// Tap Card — list controller. Search + category/date filters over the user's
// private card wallet, with an offline-first cache and a replayed write queue.
//
// Flow on open: paint the cached list immediately, then refresh from the server.
// Writes go through [saveCard]/[deleteCard], which update the local list first
// and either call the server now or queue the op for when the connection is back.

import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/reimbursement_repo.dart';
import 'package:newdigitalerp/utils/show_message.dart';

import 'tap_card_utils/tap_card_local_store.dart';
import 'tap_card_models.dart';

class TapCardController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  List<TapCardModel> allCards = [];
  String searchText = '';

  /// '' = no filter. Options are the fixed category list, not derived from data,
  /// so an empty wallet still offers them.
  String filterCategory = '';
  String filterCompany = '';

  /// True when the last load came from the cache because there was no
  /// connection — the list screen shows an offline banner for this.
  bool offline = false;

  /// Number of writes still waiting to reach the server.
  int pendingCount = 0;

  String get _compId =>
      homeController.currentUserData?.compId?.toString() ?? '';
  String get _branchId =>
      homeController.currentUserData?.branchId?.toString() ?? '0';
  String get _userId =>
      homeController.currentUserData?.userid?.toString() ?? '';

  // ── Date window ──
  // Unlike the ERP document modules this defaults to "everything": a card
  // wallet is small, and a contact saved last year is exactly the one you go
  // looking for. The filter screen narrows it when asked.
  DateTime? fromDate;
  DateTime? toDate;

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  static String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool get hasDateRange => fromDate != null && toDate != null;
  String get dateRangeLabel =>
      hasDateRange ? '${_dmy(fromDate!)} — ${_dmy(toDate!)}' : 'All time';

  Future<void> setDateRange(DateTime from, DateTime to) async {
    fromDate = from;
    toDate = to;
    update();
    await loadList();
  }

  Future<void> clearDateRange() async {
    fromDate = null;
    toDate = null;
    update();
    await loadList();
  }

  @override
  void onInit() {
    super.onInit();
    // Cache first so the list is never blank on open, then hit the server.
    allCards = TapCardLocalStore.readCache(_compId, _userId);
    pendingCount = TapCardLocalStore.readQueue(_compId, _userId).length;
    loadList();
  }

  // ── Filtering / search ──
  List<TapCardModel> get cardList {
    Iterable<TapCardModel> list = allCards;
    if (filterCategory.isNotEmpty) {
      list = list.where((c) => (c.category ?? '') == filterCategory);
    }
    if (filterCompany.isNotEmpty) {
      list = list.where((c) => (c.company ?? '').trim() == filterCompany);
    }
    final q = searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where(
        (c) =>
            c.name.toLowerCase().contains(q) ||
            (c.phone ?? '').toLowerCase().contains(q) ||
            (c.email ?? '').toLowerCase().contains(q) ||
            (c.company ?? '').toLowerCase().contains(q) ||
            (c.title ?? '').toLowerCase().contains(q),
      );
    }
    return list.toList();
  }

  /// The list grouped A–Z by first letter, the way TapCard presents it.
  /// Returns section letter -> cards, in alphabetical order.
  Map<String, List<TapCardModel>> get groupedCards {
    final sorted = cardList
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final out = <String, List<TapCardModel>>{};
    for (final c in sorted) {
      out.putIfAbsent(c.initial, () => []).add(c);
    }
    return out;
  }

  int get totalRecords => allCards.length;
  int get filteredCount => cardList.length;

  List<String> get companyOptions {
    final s =
        allCards
            .map((c) => (c.company ?? '').trim())
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return s;
  }

  int get activeFilterCount =>
      (filterCategory.isNotEmpty ? 1 : 0) +
      (filterCompany.isNotEmpty ? 1 : 0) +
      (hasDateRange ? 1 : 0);

  void onSearch(String v) {
    searchText = v;
    update();
  }

  void setFilterCategory(String v) {
    filterCategory = v;
    update();
  }

  void setFilterCompany(String v) {
    filterCompany = v;
    update();
  }

  void resetFilters() {
    filterCategory = '';
    filterCompany = '';
    update();
  }

  // ── Load ──
  Future<void> loadList() async {
    setBusy(true);
    try {
      // Replay anything queued before reading, so the list we fetch already
      // reflects the user's offline edits.
      await syncPending(silent: true);

      final res = await api.getTapCardList({
        'compid': _compId,
        'userid': _userId,
        if (hasDateRange) 'fromdate': _ymd(fromDate!),
        if (hasDateRange) 'todate': _ymd(toDate!),
      });

      if (res.status == 200) {
        offline = false;
        // Server rows are the truth, but cards still queued locally haven't
        // reached it yet — keep them visible on top or they'd vanish mid-sync.
        final queuedKeys = TapCardLocalStore.readQueue(_compId, _userId)
            .where((o) => o.op == TapCardPendingOp.opSave)
            .map((o) => o.localKey)
            .toSet();
        final stillPending = allCards
            .where((c) => c.pendingSync && queuedKeys.contains(c.key))
            .toList();

        allCards = [...stillPending, ...res.data];
        await TapCardLocalStore.writeCache(_compId, _userId, allCards);
      } else if (res.status == 503) {
        // No connection — keep showing the cache rather than emptying the list.
        offline = true;
        if (allCards.isEmpty) {
          allCards = TapCardLocalStore.readCache(_compId, _userId);
        }
      } else {
        ShowMessage.showSnackBar('Tap Card', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      pendingCount = TapCardLocalStore.readQueue(_compId, _userId).length;
      setBusy(false);
    }
  }

  // ── Save (create or update) ──
  /// Saves [card], uploading any local image files first. Returns null on
  /// success, or an error message. A card saved without a connection is kept
  /// locally and queued — that is still a success from the user's point of view.
  Future<String?> saveCard(TapCardModel card) async {
    final isNew = card.id <= 0;
    final localKey =
        card.localId ??
        (isNew ? 'local_${DateTime.now().millisecondsSinceEpoch}' : card.key);

    // Show it in the list straight away, marked pending.
    final optimistic = card.copyWith(
      localId: localKey,
      pendingSync: true,
      createdAt: card.createdAt ?? DateTime.now(),
    );
    _upsertLocal(optimistic, replaceKey: card.key);
    await TapCardLocalStore.writeCache(_compId, _userId, allCards);

    final online = await _isOnline();
    if (!online) {
      await TapCardLocalStore.enqueue(
        _compId,
        _userId,
        TapCardPendingOp(
          op: TapCardPendingOp.opSave,
          card: optimistic,
          localKey: optimistic.key,
        ),
      );
      pendingCount = TapCardLocalStore.readQueue(_compId, _userId).length;
      offline = true;
      update();
      return null;
    }

    final err = await _pushCard(optimistic);
    if (err != null) {
      // Couldn't reach the server — hold it in the queue rather than lose it.
      await TapCardLocalStore.enqueue(
        _compId,
        _userId,
        TapCardPendingOp(
          op: TapCardPendingOp.opSave,
          card: optimistic,
          localKey: optimistic.key,
        ),
      );
      pendingCount = TapCardLocalStore.readQueue(_compId, _userId).length;
      update();
      return err;
    }

    await TapCardLocalStore.writeCache(_compId, _userId, allCards);
    update();
    return null;
  }

  /// Upload pending images, POST the card, then swap the local row for the
  /// server's. Returns an error message, or null on success.
  Future<String?> _pushCard(TapCardModel card) async {
    try {
      var toSend = card;

      // Images captured offline are local file paths; upload them now so the
      // row stores an http URL (the image widgets only render those).
      final front = await _uploadIfLocal(card.imageUrl);
      final back = await _uploadIfLocal(card.backImageUrl);
      toSend = toSend.copyWith(imageUrl: front, backImageUrl: back);

      final res = await api.saveTapCard(
        toSend.toFormBody(
          compid: _compId,
          branchid: _branchId,
          userid: _userId,
        ),
      );

      if (res.status == 200 && res.data != null) {
        _upsertLocal(
          res.data!.copyWith(pendingSync: false),
          replaceKey: card.key,
        );
        return null;
      }
      if (res.status == 503) return 'No internet';
      return res.message.isEmpty ? 'Could not save the card' : res.message;
    } catch (e) {
      log('TapCard: push failed — $e');
      return '$e';
    }
  }

  /// Returns the value to store: an already-uploaded http URL unchanged, a
  /// local file path replaced by its uploaded URL, null left as null.
  Future<String?> _uploadIfLocal(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    try {
      final res = await ReimbursementRepo.uploadReimbursementFile(
        path,
        compid: _compId,
        userid: _userId,
      );
      if (res.status == true && res.statusCode == 200) {
        final data =
            (res.data as Map<String, dynamic>?)?['data']
                as Map<String, dynamic>?;
        // `filename` is the absolute URL; `url` is the same value.
        final url = data?['filename']?.toString() ?? data?['url']?.toString();
        if (url != null && url.startsWith('http')) return url;
      }
      log('TapCard: image upload failed — ${res.message}');
    } catch (e) {
      log('TapCard: image upload threw — $e');
    }
    // Keep the local path so the image still shows on this device and the
    // next sync can retry the upload.
    return path;
  }

  // ── Delete ──
  Future<String?> deleteCard(TapCardModel card) async {
    allCards.removeWhere((c) => c.key == card.key);
    await TapCardLocalStore.writeCache(_compId, _userId, allCards);
    update();

    final online = await _isOnline();
    if (!online || card.id <= 0) {
      await TapCardLocalStore.enqueue(
        _compId,
        _userId,
        TapCardPendingOp(
          op: TapCardPendingOp.opDelete,
          cardId: card.id,
          localKey: card.key,
        ),
      );
      pendingCount = TapCardLocalStore.readQueue(_compId, _userId).length;
      update();
      return null;
    }

    try {
      final res = await api.deleteTapCard({
        'compid': _compId,
        'userid': _userId,
        'id': card.id.toString(),
      });
      if (res.status == 200) return null;

      await TapCardLocalStore.enqueue(
        _compId,
        _userId,
        TapCardPendingOp(
          op: TapCardPendingOp.opDelete,
          cardId: card.id,
          localKey: card.key,
        ),
      );
      pendingCount = TapCardLocalStore.readQueue(_compId, _userId).length;
      update();
      return res.message ?? 'Could not delete the card';
    } catch (e) {
      return '$e';
    }
  }

  // ── Sync ──
  /// Replay queued writes. Ops that still fail stay queued for the next attempt.
  /// [silent] suppresses the snackbar when called as part of a normal load.
  Future<void> syncPending({bool silent = false}) async {
    final queue = TapCardLocalStore.readQueue(_compId, _userId);
    if (queue.isEmpty) return;
    if (!await _isOnline()) return;

    final failed = <TapCardPendingOp>[];
    var synced = 0;

    for (final op in queue) {
      if (op.op == TapCardPendingOp.opSave && op.card != null) {
        final err = await _pushCard(op.card!);
        if (err != null) {
          failed.add(op);
        } else {
          synced++;
        }
      } else if (op.op == TapCardPendingOp.opDelete && op.cardId > 0) {
        try {
          final res = await api.deleteTapCard({
            'compid': _compId,
            'userid': _userId,
            'id': op.cardId.toString(),
          });
          // A 404 means it's already gone — that's the outcome we wanted, so
          // don't keep retrying it forever.
          if (res.status == 200 || res.status == 404) {
            synced++;
          } else {
            failed.add(op);
          }
        } catch (_) {
          failed.add(op);
        }
      }
    }

    await TapCardLocalStore.writeQueue(_compId, _userId, failed);
    await TapCardLocalStore.writeCache(_compId, _userId, allCards);
    pendingCount = failed.length;
    update();

    if (!silent && synced > 0) {
      ShowMessage.showSnackBar(
        'Tap Card',
        '$synced pending ${synced == 1 ? 'change' : 'changes'} synced.',
      );
    }
  }

  /// Replace the row with [replaceKey] (or append), keeping list order stable.
  void _upsertLocal(TapCardModel card, {String? replaceKey}) {
    final key = replaceKey ?? card.key;
    final i = allCards.indexWhere((c) => c.key == key);
    if (i >= 0) {
      allCards[i] = card;
    } else {
      allCards.insert(0, card);
    }
    update();
  }

  Future<bool> _isOnline() async {
    try {
      final c = await Connectivity().checkConnectivity();
      return c.contains(ConnectivityResult.wifi) ||
          c.contains(ConnectivityResult.mobile) ||
          c.contains(ConnectivityResult.ethernet);
    } catch (_) {
      // If we can't tell, assume online and let the call itself fail — that
      // path already queues the write.
      return true;
    }
  }
}
