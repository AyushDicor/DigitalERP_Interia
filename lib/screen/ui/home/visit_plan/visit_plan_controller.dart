import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/response/all_visit_data_response.dart';
import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../home/home_contoller.dart';
import '../../../../services/api_service/request_keys.dart';

class VisitPlanController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  final TextEditingController startDateController = TextEditingController();
  final FocusNode startDateFocus = FocusNode();
  final TextEditingController endDateController = TextEditingController();
  final FocusNode endDateFocus = FocusNode();
  String selectedExecutiveId = '';
  String selectedStateId = '';
  String selectedCityId = '';
  String selectedAreaId = '';
  String? fromVisitDate, toVisitDate;

  /// Filters supported by /api/visit/list. Empty = no filter.
  String selectedStatus = '';
  String selectedPurposeType = '';
  String searchText = '';

  RxList<VisitListData> visitListData = <VisitListData>[].obs;

  /// Visit dates arrive as "18 Aug 2026" from /api/visit/list and as
  /// "18-08-2026" from the older endpoints. Returns null if neither parses.
  static DateTime? _parseVisitDate(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    for (final f in ['dd MMM yyyy', 'dd-MM-yyyy', 'yyyy-MM-dd']) {
      try {
        return DateFormat(f).parseLoose(s);
      } catch (_) {/* try the next format */}
    }
    return null;
  }

  void applyVisitFilters({String? status, String? purposeType, String? search}) {
    if (status != null) selectedStatus = status;
    if (purposeType != null) selectedPurposeType = purposeType;
    if (search != null) searchText = search;
    getVisitPlanList();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    getVisitPlanList();
    super.onInit();
  }

  void resetFilter() {
    selectedExecutiveId = '';
    selectedCityId = '';
    selectedAreaId = '';
    selectedStatus = '';
    selectedPurposeType = '';
    searchText = '';
    fromVisitDate = null;
    toVisitDate = null;
    getVisitPlanList();
    update();
  }

  void tapOnCard(VisitListData item) {
    Get.toNamed(AppRoutes.visitPlanDetail, arguments: item);
  }

  void tapOnAdd() {
    Get.toNamed(AppRoutes.newVisitPlaning);
  }

  Future<void> getVisitPlanList() async {
    var date = DateTime.now().add(const Duration(days: 30));
    try {
      isBusy = true;
      visitListData.clear();
      String executiveId = '';
      if (selectedExecutiveId.isEmpty) {
        executiveId = homeController.currentUserData?.accountCode.toString() ?? '';
      } else {
        executiveId = selectedExecutiveId;
      }
      String fromDate = fromVisitDate ?? '';
      String toDate = toVisitDate ?? '';
      if (fromDate.isEmpty) {
        fromDate = getStartDateOfMonth(DateTime.now());
      }
      if (toDate.isEmpty) {
        toDate = formatDate(date.toString(), AppString.dateTimeFormat, AppString.yyyyMMdd);
      }
      // /api/visit/list takes: compid, userid, fromdate, todate, status,
      // purposetype, search. The old executiveid/cityid/areaid/branchid params
      // are ignored by this endpoint, so they are no longer sent.
      Map<String, String> body = {
        RequestKeys.compId: homeController.currentUserData?.compId.toString() ?? '',
        RequestKeys.userId: homeController.currentUserData?.userid.toString() ?? '',
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate,
        RequestKeys.status: selectedStatus,
        'purposetype': selectedPurposeType,
        'search': searchText,
      };
      var res = await api.allVisitListData(body);
      if (res.status == 200) {
        visitListData.value = res.data ?? [];

        /// Newest visit first.
        ///
        /// This used to compare the raw date STRINGS ascending, which put the
        /// newest visit at the bottom and wasn't even chronological — the new
        /// API sends "18 Aug 2026", so "2 Sep 2026" sorted before "18 Aug 2026"
        /// because '1' < '2'. Parse the date, sort descending, and fall back to
        /// the row id (higher = newer) when a date is missing or unparseable.
        visitListData.sort((a, b) {
          final da = _parseVisitDate(a.visitdate);
          final db = _parseVisitDate(b.visitdate);
          if (da != null && db != null && da != db) return db.compareTo(da);
          if (da == null && db != null) return 1;
          if (da != null && db == null) return -1;
          return (b.visitid ?? 0).compareTo(a.visitid ?? 0);
        });
      } else {
        //ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isBusy = false;
      update();
    }
  }
}
