import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/Menu_new_list_responce.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/homeview_new_controller.dart';
import 'package:newdigitalerp/new_menu_defalut_screen.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

/// The module grid ("Quick Links").
///
/// Lives here rather than inside a screen because it is opened straight from
/// the **More** tab of the bottom navigation bar — tapping More no longer walks
/// the user through an intermediate page to reach their modules.
///
/// The sheet opens at half the screen height and can be dragged up to almost
/// full height; the grid itself scrolls, so any number of menu items is fine.
void openQuickLinksSheet() {
  final context = Get.context;
  if (context == null) return;

  // The More tab no longer mounts HomeViewNew, which used to re-fetch the menu
  // on resume — so top the list up here if it never loaded.
  if (Get.isRegistered<HomeViewNewController>()) {
    final ctrl = Get.find<HomeViewNewController>();
    if (ctrl.menuListData.isEmpty) ctrl.getNewMenuList(0);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      // Half the screen, as asked; the rest of the menu scrolls.
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (sheetContext, scrollController) =>
          _QuickLinksSheet(scrollController: scrollController),
    ),
  );
}

class _QuickLinksSheet extends StatelessWidget {
  final ScrollController scrollController;

  const _QuickLinksSheet({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: GetBuilder<HomeViewNewController>(
        builder: (ctrl) => Column(
          children: [
            const SizedBox(height: 10),
            // Drag handle — signals the sheet can be pulled up.
            Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            _header(context, ctrl),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            Expanded(child: _grid(context, ctrl)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, HomeViewNewController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: newBlueLightColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: newBlueColor, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Quick Links',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: newTextPrimary),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close_rounded,
                  size: 18, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, HomeViewNewController ctrl) {
    if (ctrl.isListLoading) {
      return const Center(child: CircularProgressIndicator(color: newBlueColor));
    }
    if (ctrl.menuListData.isEmpty) {
      return Center(
        child: Text('No menu items found',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      itemCount: ctrl.menuListData.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, i) => _menuTile(context, ctrl.menuListData[i], ctrl),
    );
  }

  Widget _menuTile(
      BuildContext context, MenuNewData data, HomeViewNewController ctrl) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(); // close the sheet first

        // Known menu ids get an explicit route, checked before the child==1
        // branch so hub screens aren't replaced by the generic sub-menu list.
        final route = _directRoute(data.menuid);
        if (route != null) {
          Get.toNamed(route);
          return;
        }

        if (data.child == 1) {
          Get.to(() => MenuDefaultScreen(
                menuID: data.menuid!,
                title: data.menuname ?? 'Menu',
              ));
        } else {
          Get.toNamed(HomeViewNewController.getRouteNameById(data.menuid));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: newBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: newBlueLightColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Image.asset(
                  ctrl.imageList()[data.menuname] ?? '',
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.grid_view_rounded,
                      color: newBlueColor,
                      size: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                data.menuname ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: newTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _directRoute(int? menuId) {
    const directRoutes = {
      126: AppRoutes.dashboard,
      127: AppRoutes.reportsHub,
      2384: AppRoutes.approvalHub,
      2385: AppRoutes.taskManagement,
      2754: AppRoutes.mrnScreen,
      2701: AppRoutes.reimbursement,
      2586: AppRoutes.paymentRequestListScreen,
    };
    return menuId != null ? directRoutes[menuId] : null;
  }
}
