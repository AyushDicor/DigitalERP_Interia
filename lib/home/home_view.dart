
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/home_view_new.dart';
import 'package:newdigitalerp/homeview_new_controller.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_view.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/dashboard_view.dart';
import 'package:newdigitalerp/screen/ui/home/drawer/drawer_view.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_list_drawer_view.dart';
import 'package:newdigitalerp/screen/ui/home/quick_links/quick_links_sheet.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:upgrader/upgrader.dart';

// Nav item model — UNCHANGED
class _NavItem {
  final String? assetImage;
  final IconData? icon;
  final IconData activeIcon;
  final String label;
  final Widget page;

  /// True for tabs that open a sheet instead of switching pages (More).
  /// Such a tab never becomes the selected tab — the sheet is the destination.
  final bool opensSheet;

  const _NavItem({
    this.assetImage,
    this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
    this.opensSheet = false,
  });
}

// Map: menu ID → nav item definition — UNCHANGED
const Map<int, _NavItem> _menuNavMap = {
  // 2378: _NavItem(
  //   assetImage: 'assets/bottomNavIcons/orderNav.png',
  //   icon: Icons.inventory_2_outlined,
  //   activeIcon: Icons.inventory_2_rounded,
  //   label: 'Orders',
  //   page: OrderViewDrawer(),
  // ),
  2377: _NavItem(
    assetImage: 'assets/bottomNavIcons/groupNav.png',
    icon: Icons.group_outlined,
    activeIcon: Icons.group_rounded,
    label: 'Team',
    page: ExecutiveListDrawerView(),
  ),
};

//
// HomeView — FUNCTIONALITY UNCHANGED
//
class HomeView extends StatelessWidget {
  HomeView({Key? key}) : super(key: key);

  final _upgrader = Upgrader(
    storeController: UpgraderStoreController(
      onAndroid: () => UpgraderAppcastStore(appcastURL: AppConst.appCastUrl),
      oniOS: () => UpgraderAppcastStore(appcastURL: AppConst.appCastUrl),
    ),
  );

  /// The store-update prompt, but only for a build that is actually published
  /// under the appcast's listing — see [AppConst.checkForUpdates]. It has no
  /// Ignore or Later button, so on any other build it would reappear on every
  /// launch and send the user to the wrong app.
  Widget _maybeUpgradeAlert({required Widget child}) {
    if (!AppConst.checkForUpdates) return child;
    return UpgradeAlert(
      upgrader: _upgrader,
      showIgnore: false,
      showLater: false,
      shouldPopScope: () => false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: lightGreyColor,
          drawer: const DrawerView(),
          resizeToAvoidBottomInset: false,
          body: _maybeUpgradeAlert(
            child: GetBuilder<HomeViewNewController>(
              init: HomeViewNewController(),
              builder: (menuCtrl) {
                final isLoading = menuCtrl.isBusy;
                final dynamicTabs = _buildTabs(controller, menuCtrl);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: _currentPage(controller, dynamicTabs),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: isLoading
                          ? const _NavBarShimmer()
                          : _BottomNav(
                        tabs: dynamicTabs,
                        selectedIndex: controller.selectedTabI
                            .clamp(0, dynamicTabs.length - 1),
                        onTap: (i) => controller.onItemTapped(i),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // UNCHANGED
  List<_NavItem> _buildTabs(
      HomeController controller, HomeViewNewController menuCtrl) {
    final menuIds = menuCtrl.menuListData
        .map((e) => e.menuid ?? -1)
        .where((id) => id > 0)
        .toSet();

    final tabs = <_NavItem>[
      const _NavItem(
        assetImage: 'assets/bottomNavIcons/homeNav.png',
        icon: Icons.home_filled,
        activeIcon: Icons.home_filled,
        label: 'Home',
        page: DashboardView(),
      ),
    ];

    if (controller.isCustomer != true) {
      tabs.add(_NavItem(
        icon: Icons.date_range_outlined,
        activeIcon: Icons.date_range_rounded,
        label: 'Attendance',
        page: AttendanceView(),
      ));
    }

    for (final entry in _menuNavMap.entries) {
      if (menuIds.contains(entry.key)) {
        tabs.add(entry.value);
      }
    }

    // More opens the Quick Links sheet directly — the old behaviour landed on
    // HomeViewNew and needed a second tap on "Quick Links" to reach the modules.
    tabs.add(const _NavItem(
      assetImage: 'assets/bottomNavIcons/moreNav.png',
      icon: Icons.apps_outlined,
      activeIcon: Icons.apps_rounded,
      label: 'More',
      page: HomeViewNew(),
      opensSheet: true,
    ));

    return tabs;
  }

  Widget _currentPage(HomeController controller, List<_NavItem> tabs) {
    final idx = controller.selectedTabI.clamp(0, tabs.length - 1);
    return tabs[idx].page;
  }
}

//
// SHIMMER — UNCHANGED
//
class _NavBarShimmer extends StatefulWidget {
  const _NavBarShimmer();

  @override
  State<_NavBarShimmer> createState() => _NavBarShimmerState();
}

class _NavBarShimmerState extends State<_NavBarShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _fade = Tween(begin: 0.25, end: 0.7).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: Container(
          decoration: const BoxDecoration(
            color: whiteColor,
            border: Border(top: BorderSide(color: newBorderColor, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (_) => _shimmerTab()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

//
// BOTTOM NAV BAR — UI ONLY CHANGE
//
class _BottomNav extends StatelessWidget {
  final List<_NavItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              tabs.length,
                  (i) => _NavTile(
                item: tabs[i],
                isSelected: selectedIndex == i,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // A sheet tab keeps the current page underneath, so the tab
                  // selection is left untouched.
                  if (tabs[i].opensSheet) {
                    openQuickLinksSheet();
                    return;
                  }
                  onTap(i);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//
// NAV TILE — UI redesigned to match the image
// Active state   → rounded square filled with purple, white icon, colored label
// Inactive state → plain icon + grey label (no background)
//
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  // Active purple — matches image
  static const _activeColor = purpleColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon — filled rounded square when active, plain when not
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 48,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? _activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                // ← ADD Center
                child: item.assetImage != null
                    ? Image.asset(
                  item.assetImage!,
                  width: 24, // ← fix: was missing explicit size
                  height: 24, // ← fix: was missing explicit size
                  fit: BoxFit.contain,
                  color:
                  isSelected ? Colors.white : const Color(0xFF6B7380),
                )
                    : Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 22,
                  color:
                  isSelected ? Colors.white : const Color(0xFF6B7380),
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Label
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? _activeColor : const Color(0xFF6B7380),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
