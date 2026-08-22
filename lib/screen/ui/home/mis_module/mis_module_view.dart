import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/my_app_bar_new.dart';

import '../../../../fab/menu_fab.dart';
import 'package:newdigitalerp/repo/mis_repo.dart';
import 'mis_module_controller.dart';

/// MIS hub — grouped, searchable list of every report the app exposes.
/// The tile list is hard-coded in [MisModuleController.menuList].
class MisModuleView extends StatelessWidget {
  const MisModuleView({Key? key}) : super(key: key);

  static const _bg = Color(0xFFF4F5F9);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MisModuleController>(
      init: MisModuleController(),
      builder: (controller) => Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            // White header with a real back button.
            Container(
              color: whiteColor,
              child: Column(
                children: [
                  MyAppBar(
                    title: 'MIS Module',
                    onBackTap: () => Get.back(),
                  ),
                  _searchBar(controller),
                ],
              ),
            ),
            Expanded(child: _body(controller)),
          ],
        ),
        floatingActionButton: MenuFab(parentMenuId: 2383),
      ),
    );
  }

  Widget _searchBar(MisModuleController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: newSurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: newBorderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 20, color: newTextHint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: controller.onSearch,
                style: const TextStyle(fontSize: 14, color: newTextPrimary),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search reports',
                  hintStyle: TextStyle(fontSize: 14, color: newTextHint),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(MisModuleController controller) {
    final groups = controller.visibleGroups;
    final showReports = controller.query.isEmpty;
    if (groups.isEmpty && !showReports) return _emptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 90),
      // +1 leading slot for the server-driven report section.
      itemCount: groups.length + (showReports ? 1 : 0),
      itemBuilder: (context, index) {
        if (showReports && index == 0) return _reportsSection(controller);
        final i = index - (showReports ? 1 : 0);
        final group = groups[i];
        final tiles = controller.tilesOf(group);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (i != 0) const SizedBox(height: 22),
            _sectionHeader(group, tiles.length),
            const SizedBox(height: 10),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.18,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: tiles.length,
              itemBuilder: (_, index) => _card(controller, tiles[index]),
            ),
          ],
        );
      },
    );
  }

  /// Server-driven reports from /api/mis/reports, grouped by module. Each row
  /// opens the same generic report screen — the API decides what it contains.
  Widget _reportsSection(MisModuleController c) {
    if (c.reportsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (c.reports.isEmpty) return const SizedBox.shrink();

    final groups = c.reportsByModule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Reports', c.reports.length),
        const SizedBox(height: 10),
        ...groups.entries.map((e) => _reportGroup(c, e.key, e.value)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _reportGroup(
      MisModuleController c, String module, List<MisReport> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F4)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: newBlueColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.insights_rounded,
                    size: 17, color: newBlueColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _humanModule(module),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: newTextPrimary),
                ),
              ),
            ]),
          ),
          ...items.map((r) => InkWell(
                onTap: () => c.openReport(r),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
                  child: Row(children: [
                    const SizedBox(width: 42),
                    Expanded(
                      child: Text(
                        r.reportType.isEmpty ? r.reportName : r.reportType,
                        style: const TextStyle(
                            fontSize: 13, color: newTextPrimary),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: newTextSecondary),
                  ]),
                ),
              )),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// CreateSaleOrder -> Create Sale Order
  String _humanModule(String raw) => raw
      .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
      .trim();

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: newBlueColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: newTextPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: newBlueLightColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: newBlueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(MisModuleController controller, MisTile tile) {
    return Material(
      color: whiteColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.openTile(tile),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF0F4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tile.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tile.icon, size: 22, color: tile.color),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded,
                      size: 16, color: newTextHint),
                ],
              ),
              const Spacer(),
              Text(
                tile.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: newTextPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tile.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: newTextSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 46, color: newTextHint),
          const SizedBox(height: 10),
          const Text(
            'No report found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: newTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different keyword',
            style: TextStyle(fontSize: 12, color: newTextSecondary),
          ),
        ],
      ),
    );
  }
}
