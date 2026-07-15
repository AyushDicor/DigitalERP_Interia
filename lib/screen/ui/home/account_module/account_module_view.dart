
import 'package:newdigitalerp/fab/menu_fab.dart';

import 'package:newdigitalerp/screen/ui/home/account_module/account_module_controller.dart';
import 'package:newdigitalerp/utils/app_assets.dart';
import 'package:newdigitalerp/utils/my_app_bar_new.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//  Design tokens 
const Color _kBg     = Color(0xFFF8F9FC);
const Color _kWhite  = Colors.white;
const Color _kText   = Color(0xFF111827);
const Color _kSub    = Color(0xFF6B7280);
const Color _kBorder = Color(0xFFE4E7EF);

// Icon map per menu index
const List<IconData> _menuIcons = [
  Icons.payments_outlined,           // Payment Entry
  Icons.receipt_long_outlined,       // Receipt Entry
  Icons.account_balance_outlined,    // Collection
  Icons.money_off_outlined,          // Expenses
  Icons.swap_horiz_outlined,         // Party Ledger
  Icons.compare_arrows_outlined,     // Contra
  Icons.book_outlined,               // Journal
  Icons.person_search_outlined,      // Party Transactions
];

class AccountModuleView extends StatelessWidget {
  const AccountModuleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountModuleController>(
      init: AccountModuleController(),
      builder: (controller) => Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kWhite,
          elevation: 0,
          surfaceTintColor: _kWhite,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kText, size: 18),
          ),
          title: const Text(
            'Accounts',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: _kText),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _kBorder, height: 1),
          ),
        ),
        floatingActionButton: MenuFab(parentMenuId: 2382),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: controller.menuList.length,
            itemBuilder: (context, index) => _MenuCard(
              name: controller.menuList[index].name,
              color1: controller.menuList[index].color1,
              color2: controller.menuList[index].color2,
              icon: index < _menuIcons.length
                  ? _menuIcons[index]
                  : Icons.widgets_outlined,
              onTap: () => controller.tapOnCard(index),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String name;
  final Color color1;
  final Color color2;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.name,
    required this.color1,
    required this.color2,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color1.withValues(alpha:0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorative circle
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.08),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: -16,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.06),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}