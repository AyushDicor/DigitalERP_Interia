// Tap Card — list page. Stat header + search + category chips + A–Z grouped
// card rows, matching the other list screens in the app. The FAB offers a choice
// between scanning a physical card and typing one in.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_constant_new.dart';
import '../utils/show_message.dart';
import '../utils/summary_cards.dart';
import 'tap_card_controller.dart';
import 'tap_card_create/tap_card_create_view.dart';
import 'tap_card_detail/tap_card_detail_view.dart';
import 'tap_card_filter/tap_card_filter_view.dart';
import 'tap_card_models.dart';
import 'tap_card_scan_view.dart';
import 'tap_card_utils/tap_card_widgets.dart';

class TapCardListView extends StatelessWidget {
  const TapCardListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TapCardController>(
      init: TapCardController(),
      builder: (c) => Scaffold(
        backgroundColor: kTapBg,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSheet(context, c),
          backgroundColor: purpleColor,
          elevation: 3,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        appBar: AppBar(
          backgroundColor: kTapSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: kTapBorder,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: newTextPrimary,
              size: 20,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Tap Card',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kTapTextPrimary,
                ),
              ),
              Text(
                'Your saved business cards',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: kTapTextSecondary,
                ),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () => Get.to(() => const TapCardFilterView()),
              child: Container(
                margin: const EdgeInsets.only(right: 18),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: purpleLightest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.filter_list_sharp,
                        size: 20,
                        color: purpleColor,
                      ),
                    ),
                    if (c.activeFilterCount > 0) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '${c.activeFilterCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kTapPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: kTapPrimary,
          onRefresh: () => c.loadList(),
          child: c.isBusy && c.allCards.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: kTapPrimary,
                    strokeWidth: 2.5,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                  children: [
                    if (c.offline || c.pendingCount > 0) _offlineBanner(c),
                    _statsRow(c),
                    const SizedBox(height: 14),
                    _searchField(c),
                    const SizedBox(height: 12),
                    _categoryChips(c),
                    const SizedBox(height: 12),
                    if (c.cardList.isEmpty)
                      _emptyState(c)
                    else
                      ..._groupedRows(c),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Offline / pending-sync banner ──
  Widget _offlineBanner(TapCardController c) {
    final pending = c.pendingCount;
    final text = c.offline
        ? (pending > 0
              ? 'Offline — $pending ${pending == 1 ? 'card is' : 'cards are'} waiting to sync.'
              : 'Offline — showing your saved cards.')
        : '$pending ${pending == 1 ? 'card' : 'cards'} waiting to sync.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: newOrangeLightColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: newOrangeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: newOrangeColor,
              ),
            ),
          ),
          if (c.pendingCount > 0)
            GestureDetector(
              onTap: () => c.syncPending(),
              child: const Text(
                'SYNC NOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: newOrangeColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statsRow(TapCardController c) => SummaryCards([
    SummaryStat('${c.totalRecords}', 'Total', newBlueColor, newBlueLightColor),
    SummaryStat(
      '${c.filteredCount}',
      'Showing',
      newGreenColor,
      newGreenLightColor,
    ),
  ], padding: EdgeInsets.zero);

  Widget _searchField(TapCardController c) => Container(
    decoration: BoxDecoration(
      color: kTapSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kTapBorder),
    ),
    child: TextField(
      onChanged: c.onSearch,
      style: const TextStyle(fontSize: 14, color: kTapTextPrimary),
      decoration: const InputDecoration(
        hintText: 'Search name, phone, company…',
        hintStyle: TextStyle(fontSize: 13.5, color: kTapTextHint),
        prefixIcon: Icon(Icons.search, size: 20, color: kTapTextSecondary),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      ),
    ),
  );

  /// Quick category filter — the same values as the filter page, surfaced here
  /// because it is the one filter people reach for constantly.
  Widget _categoryChips(TapCardController c) {
    final options = ['', ...TapCardCategory.all];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final opt = options[i];
          final active = c.filterCategory == opt;
          final label = opt.isEmpty ? 'All' : opt;
          final color = opt.isEmpty ? kTapPrimary : tapCategoryColor(opt);
          return GestureDetector(
            onTap: () => c.setFilterCategory(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? color.withValues(alpha: 0.12) : kTapSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active ? color : kTapBorder),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? color : kTapTextSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(TapCardController c) {
    final filtered = c.searchText.isNotEmpty || c.activeFilterCount > 0;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              filtered ? Icons.search_off_rounded : Icons.badge_outlined,
              size: 46,
              color: kTapTextHint,
            ),
            const SizedBox(height: 10),
            Text(
              filtered ? 'No cards match your filters' : 'No cards yet',
              style: const TextStyle(fontSize: 13.5, color: kTapTextSecondary),
            ),
            if (!filtered) ...[
              const SizedBox(height: 4),
              const Text(
                'Tap + to scan or add your first card',
                style: TextStyle(fontSize: 12, color: kTapTextHint),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A–Z sections, each with a sticky-looking letter header.
  List<Widget> _groupedRows(TapCardController c) {
    final out = <Widget>[];
    c.groupedCards.forEach((letter, cards) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kTapTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      out.addAll(cards.map((card) => _cardRow(c, card)));
    });
    return out;
  }

  Widget _cardRow(TapCardController c, TapCardModel card) {
    return GestureDetector(
      onTap: () => Get.to(() => TapCardDetailView(card: card)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kTapSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kTapBorder),
        ),
        child: Row(
          children: [
            TapCardAvatar(card),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: kTapTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (card.pendingSync)
                        const TapPendingBadge()
                      else
                        TapCategoryBadge(card.category),
                    ],
                  ),
                  if ((card.title ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      card.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTapTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  if ((card.phone ?? '').isNotEmpty)
                    _meta(Icons.phone_outlined, card.phone!),
                  if ((card.company ?? '').isNotEmpty)
                    _meta(Icons.business_outlined, card.company!),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: kTapTextHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      children: [
        Icon(icon, size: 12, color: kTapTextHint),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: kTapTextSecondary),
          ),
        ),
      ],
    ),
  );

  /// Refresh after returning from the create/scan flow. The result is either
  /// `true` or the success message the form wants shown — reported here, on
  /// the screen that survives, rather than from the one being popped.
  Future<void> _afterSave(TapCardController c, Object? result) async {
    if (result == null || result == false) return;
    await c.loadList();
    if (result is String && result.isNotEmpty) {
      ShowMessage.showSnackBar('Tap Card', result);
    }
  }

  // ── Add sheet: scan or type ──
  void _showAddSheet(BuildContext context, TapCardController c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kTapSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kTapBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add a card',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTapTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _addOption(
              icon: Icons.document_scanner_outlined,
              title: 'Scan a card',
              subtitle: 'Photograph it and we will read the details',
              onTap: () async {
                Get.back();
                final saved = await Get.to(() => const TapCardScanView());
                await _afterSave(c, saved);
              },
            ),
            const SizedBox(height: 10),
            _addOption(
              icon: Icons.edit_outlined,
              title: 'Enter manually',
              subtitle: 'Type the details yourself',
              onTap: () async {
                Get.back();
                final saved = await Get.to(() => const TapCardCreateView());
                await _afterSave(c, saved);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _addOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kTapBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTapBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: purpleLightest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: kTapPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTapTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: kTapTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: kTapTextHint,
          ),
        ],
      ),
    ),
  );
}
