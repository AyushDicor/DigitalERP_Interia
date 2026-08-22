import 'package:get/get.dart';
import 'package:newdigitalerp/performa_invoice/performa_invoice_detail_view.dart';
import 'package:newdigitalerp/performa_invoice/sale_order_controller.dart';
import 'package:newdigitalerp/purchase_order/purchase_order_controller.dart';
import 'package:newdigitalerp/purchase_order/purchase_order_detail_view.dart';
import 'package:newdigitalerp/repo/recent_activity_repo.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_hub_controller/approval_hub_controller.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/approvals_list_responce.dart';
import 'package:newdigitalerp/services/notification/notification_router.dart';

/// Opens the record behind a Recent Activity row.
///
/// Most modules can open the document itself; a few can't, and land on their
/// list instead:
///
///  * **Task / Visit** — their detail screens take an id, so
///    [NotificationRouter] already knows how to open them. Reused rather than
///    duplicated, so a notification tap and a feed tap always agree.
///  * **Approval** — the detail screen is driven by the whole list row, which
///    the feed already carries in [RecentActivityItem.raw] (same endpoint, same
///    shape), so it opens directly.
///  * **Sale Order / Purchase Order** — `loadDetail(mainid)` then push the
///    detail view, exactly as their own lists do.
///  * **MRN / GRN / Indent** — deliberately NOT opened. Their "detail" is the
///    entry form pre-filled from the list row (`_prefillFromListItem`), not a
///    read-only detail screen; opening it from the dashboard would drop the
///    user into a half-populated edit form. They stay on their list.
///
/// Any failure falls back to the module list — a tap must always do something.
void openRecentActivity(RecentActivityItem item) {
  try {
    switch (item.menuId) {
      case 2385: // Task
      case 2379: // Visit
        NotificationRouter.open(
          module: item.menuId == 2385 ? 'task' : 'visit',
          id: item.id,
        );
        return;

      case 2384: // Approval
        if (item.id <= 0 || item.raw.isEmpty) break;
        final ctrl = Get.isRegistered<ApprovalHubController>()
            ? Get.find<ApprovalHubController>()
            : Get.put(ApprovalHubController());
        ctrl.onCardTap(ApprovalListData.fromJson(item.raw));
        return;

      case 9401: // Sale Order / Performa Invoice
        if (item.id <= 0) break;
        final ctrl = Get.isRegistered<SaleOrderController>()
            ? Get.find<SaleOrderController>()
            : Get.put(SaleOrderController());
        ctrl.loadDetail(item.id);
        Get.to(() => const PerformaInvoiceDetailView());
        return;

      case 9402: // Purchase Order
        if (item.id <= 0) break;
        final ctrl = Get.isRegistered<PurchaseOrderController>()
            ? Get.find<PurchaseOrderController>()
            : Get.put(PurchaseOrderController());
        ctrl.loadDetail(item.id);
        Get.to(() => const PurchaseOrderDetailView());
        return;
    }
  } catch (_) {
    // Fall through to the list below rather than dying on a tap.
  }

  if (item.route != null) Get.toNamed(item.route!);
}
