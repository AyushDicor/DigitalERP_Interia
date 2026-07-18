// import 'dart:convert';
// import 'package:newdigitalerp/screen/base/base_controller.dart';
// import 'package:newdigitalerp/screen/ui/home/home_controller.dart';
// import 'package:newdigitalerp/utils/app_constant.dart';
// import 'package:newdigitalerp/utils/show_message.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
//
// class LeadManagementController extends AppBaseController {
//   HomeController homeController = Get.find<HomeController>();
//
//   //  Lead list (used by LeadManagementView)
//   // Replace `dynamic` with your actual LeadData model once the API is wired up
//   List<dynamic> leadList = [];
//
//   //  Text controllers
//   /// Lead entry
//   final TextEditingController leadNumberController = TextEditingController();
//   final TextEditingController requirementController = TextEditingController();
//   final TextEditingController companyNameController = TextEditingController();
//   final TextEditingController ownerNameController = TextEditingController();
//   final TextEditingController contactPersonController = TextEditingController();
//   final TextEditingController mobileNumberController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController alternateNumberController = TextEditingController();
//   final TextEditingController websiteController = TextEditingController();
//   final TextEditingController companyAddressController = TextEditingController();
//   final TextEditingController phoneNumberController = TextEditingController();
//   final TextEditingController businessNatureController = TextEditingController();
//
//   /// Followup details
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController specificationController = TextEditingController();
//   final TextEditingController remarksController = TextEditingController();
//   final TextEditingController followupTimeController = TextEditingController();
//   final TextEditingController remarkFollowController = TextEditingController();
//
//   //  Focus nodes
//   /// Lead entry
//   final FocusNode leadNoFocus = FocusNode();
//   final FocusNode requirementFocus = FocusNode();
//   final FocusNode companyNameFocus = FocusNode();
//   final FocusNode ownerNameFocus = FocusNode();
//   final FocusNode contactPersonFocus = FocusNode();
//   final FocusNode mobileNoFocus = FocusNode();
//   final FocusNode alternateNoFocus = FocusNode();
//   final FocusNode emailIdFocus = FocusNode();
//   final FocusNode websiteFocus = FocusNode();
//   final FocusNode companyAddresFocus = FocusNode();
//   final FocusNode phoneFocus = FocusNode();
//   final FocusNode businessFocus = FocusNode();
//
//   /// Followup details
//   final FocusNode addressFocus = FocusNode();
//   final FocusNode specificationFocus = FocusNode();
//   final FocusNode remarkFocus = FocusNode();
//   final FocusNode followupTimeFocus = FocusNode();
//   final FocusNode remarkFollowupFocus = FocusNode();
//
//   //  Observable
//   RxBool isCheck = false.obs;
//
//   void onChangeValue(var value) {
//     isCheck.value = value;
//   }
//
//   //  Date fields
//   String selectDate = 'Lead Date';
//   void setSelectedDate(String value) {
//     selectDate = value;
//     update();
//   }
//
//   void clearSelectedDate() {
//     selectDate = 'Lead Date';
//     update();
//   }
//
//   String selectDatef = 'Entry Date';
//   void setSelectedDatef(String value) {
//     selectDatef = value;
//     update();
//   }
//
//   void clearSelected() {
//     selectDatef = 'Entry Date';
//     update();
//   }
//
//   String selectDate2 = 'Entry Date';
//   void setSelectedDate2(String value) {
//     selectDate2 = value;
//     update();
//   }
//
//   void clearSelected2() {
//     selectDate2 = 'Entry Date';
//     update();
//   }
//
//   //  Validation
//
//   bool _isLeadValidate() {
//     if (leadNumberController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt.tr, AppString.pleaseEnterLeadNo.tr);
//       return false;
//     }
//     if (requirementController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterRequirementSpecification.tr);
//       return false;
//     }
//     if (companyNameController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterCompanyName.tr);
//       return false;
//     }
//     if (ownerNameController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterOwnerName.tr);
//       return false;
//     }
//     if (contactPersonController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterContactPersonTxt.tr);
//       return false;
//     }
//     if (mobileNumberController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterMobileTxt.tr);
//       return false;
//     }
//     if (mobileNumberController.text.trim().length != 10) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterValidMobileTxt.tr);
//       return false;
//     }
//     if (alternateNumberController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterAlternateMobileNo.tr);
//       return false;
//     }
//     // ✅ FIX: was checking mobileNumber twice — now checks alternateNumber length
//     if (alternateNumberController.text.trim().length != 10) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt.tr,
//           AppString.pleaseEnterValidMobileTxt.tr);
//       return false;
//     }
//     if (emailController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterEmailIdTxt.tr);
//       return false;
//     }
//     if (websiteController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterWebsite.tr);
//       return false;
//     }
//     if (companyAddressController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterCompanyAddress.tr);
//       return false;
//     }
//     if (phoneNumberController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterPhoneNo.tr);
//       return false;
//     }
//     if (businessNatureController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterBusinessNature.tr);
//       return false;
//     }
//     return true;
//   }
//
//   // ✅ FIX: Removed unreachable code that came after `return true` inside
//   // the nested block — the original had dead validation checks after that.
//   bool _isFollowupValidate() {
//     if (addressController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterAddress);
//       return false;
//     }
//     if (selectDatef == 'Entry Date') {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, 'Please Select Entry Date');
//       return false;
//     }
//     if (specificationController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(AppString.requiredFieldTxt,
//           AppString.pleaseEnterRequirementSpecification);
//       return false;
//     }
//     if (remarksController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterRemark);
//       return false;
//     }
//     if (followupTimeController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterFollowupTime);
//       return false;
//     }
//     if (remarkFollowController.text.trim().isEmpty) {
//       ShowMessage.showSnackBar(
//           AppString.requiredFieldTxt, AppString.pleaseEnterRemark);
//       return false;
//     }
//     return true;
//   }
//
//   //  API calls
//
//   void addleadApi() async {
//     unfocus();
//     setBusy(true);
//     if (_isLeadValidate()) {
//       try {
//         // TODO: populate body with actual field values
//         final Map<String, String> body = {};
//         final res = await api.addCompanyJson(json.encode(body));
//         if (res.status == 200) {
//           backTap();
//           ShowMessage.showSnackBar(
//               'Success', res.message.toString());
//         } else {
//           ShowMessage.showSnackBar(
//               'Error', res.message.toString());
//         }
//       } catch (e) {
//         ShowMessage.showSnackBar('Error', '$e');
//       } finally {
//         setBusy(false);
//       }
//     } else {
//       setBusy(false);
//     }
//   }
//
//   void followupDetailsApi() async {
//     unfocus();
//     setBusy(true);
//     if (_isFollowupValidate()) {
//       try {
//         // TODO: populate body with actual field values
//         final Map<String, String> body = {};
//         final res = await api.addCompanyJson(json.encode(body));
//         if (res.status == 200) {
//           backTap();
//           ShowMessage.showSnackBar(
//               'Success', res.message.toString());
//         } else {
//           ShowMessage.showSnackBar(
//               'Error', res.message.toString());
//         }
//       } catch (e) {
//         ShowMessage.showSnackBar('Error', '$e');
//       } finally {
//         setBusy(false);
//       }
//     } else {
//       setBusy(false);
//     }
//   }
//
//   //  Dispose
//
//   @override
//   void onClose() {
//     // Lead entry controllers
//     leadNumberController.dispose();
//     requirementController.dispose();
//     companyNameController.dispose();
//     ownerNameController.dispose();
//     contactPersonController.dispose();
//     mobileNumberController.dispose();
//     emailController.dispose();
//     alternateNumberController.dispose();
//     websiteController.dispose();
//     companyAddressController.dispose();
//     phoneNumberController.dispose();
//     businessNatureController.dispose();
//     // Followup controllers
//     addressController.dispose();
//     specificationController.dispose();
//     remarksController.dispose();
//     followupTimeController.dispose();
//     remarkFollowController.dispose();
//     super.onClose();
//   }
// }

import 'dart:convert';
import 'package:newdigitalerp/screen/base/base_controller.dart';
import '../../home/home_contoller.dart';
import '../lead_list_response.dart';
import '../lead_form_models.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class LeadManagementController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  //  Full dashboard bundle (leads + follow-ups + tasks + notes + estimates +
  //  quotations) from the ERP proc leaddetailsdetestnew.
  LeadBundle bundle = LeadBundle();

  //  All leads for the current filter (unsearched) and the search-filtered view.
  List<LeadData> allLeads = [];
  String searchText = '';

  //  Optional date range (yyyy-MM-dd). Empty => all leads.
  String fromDate = '';
  String toDate = '';

  //  Dynamic dropdown filters (client-side). '' = not applied. The option lists
  //  are auto-derived from the leads currently loaded (see *Options getters).
  String filterStatus = '';
  String filterSource = '';
  String filterHandler = '';
  String filterBusinessNature = '';
  String filterCompany = '';

  //  The lead currently being viewed (set when a card is tapped).
  LeadData? selectedLead;
  List<LeadFollowupData> followupList = [];

  //  Lead items for the detail screen (fetched on demand from EditLeadEntry).
  List<LeadItemData> selectedItems = [];
  bool itemsBusy = false;

  // ── Leads shown in the list: dynamic dropdown filters + free-text search ──
  List<LeadData> get leadList {
    Iterable<LeadData> list = allLeads;
    if (filterStatus.isNotEmpty) {
      list = list.where((l) => (l.status ?? '').trim() == filterStatus);
    }
    if (filterSource.isNotEmpty) {
      list = list.where((l) => (l.leadsource ?? '').trim() == filterSource);
    }
    if (filterHandler.isNotEmpty) {
      list = list.where((l) => (l.handler ?? '').trim() == filterHandler);
    }
    if (filterBusinessNature.isNotEmpty) {
      list = list
          .where((l) => (l.businessnature ?? '').trim() == filterBusinessNature);
    }
    if (filterCompany.isNotEmpty) {
      list = list.where((l) => (l.companyname ?? '').trim() == filterCompany);
    }
    final q = searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((l) {
        return (l.companyname ?? '').toLowerCase().contains(q) ||
            (l.contactperson ?? '').toLowerCase().contains(q) ||
            (l.mobilenumber ?? '').toLowerCase().contains(q) ||
            (l.leadnumber ?? '').toLowerCase().contains(q) ||
            (l.leadsource ?? '').toLowerCase().contains(q) ||
            (l.status ?? '').toLowerCase().contains(q);
      });
    }
    return list.toList();
  }

  // ── Dropdown filter options, auto-derived from the loaded leads ──
  List<String> _distinct(String? Function(LeadData) sel) {
    final s = allLeads
        .map(sel)
        .map((v) => (v ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return s;
  }

  List<String> get statusOptions => _distinct((l) => l.status);
  List<String> get sourceOptions => _distinct((l) => l.leadsource);
  List<String> get handlerOptions => _distinct((l) => l.handler);
  List<String> get businessNatureOptions => _distinct((l) => l.businessnature);
  List<String> get companyOptions => _distinct((l) => l.companyname);

  int get activeFilterCount =>
      (filterStatus.isNotEmpty ? 1 : 0) +
      (filterSource.isNotEmpty ? 1 : 0) +
      (filterHandler.isNotEmpty ? 1 : 0) +
      (filterBusinessNature.isNotEmpty ? 1 : 0) +
      (filterCompany.isNotEmpty ? 1 : 0);

  void setFilterStatus(String v) {
    filterStatus = v;
    update();
  }

  void setFilterSource(String v) {
    filterSource = v;
    update();
  }

  void setFilterHandler(String v) {
    filterHandler = v;
    update();
  }

  void setFilterBusinessNature(String v) {
    filterBusinessNature = v;
    update();
  }

  void setFilterCompany(String v) {
    filterCompany = v;
    update();
  }

  void resetLeadFilters() {
    filterStatus = '';
    filterSource = '';
    filterHandler = '';
    filterBusinessNature = '';
    filterCompany = '';
    update();
  }

  // ── KPI cards ──
  int get totalLeads => allLeads.length;
  int get openLeads =>
      allLeads.where((l) => (l.status ?? '').toLowerCase() == 'open').length;
  int get closedWonLeads => allLeads.where((l) {
        final s = (l.status ?? '').toLowerCase();
        return s == 'close' || s == 'closed' || s == 'won' || s == 'done';
      }).length;
  int get leadSourceCount => allLeads
      .map((l) => (l.leadsource ?? '').trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .length;

  // ── Chart data ──
  /// Leads grouped by status (donut). Ordered to match the web legend.
  Map<String, int> get statusCounts {
    const order = ['Open', 'Pending', 'Confirmed', 'Close', 'Done'];
    final counts = <String, int>{};
    for (final l in allLeads) {
      final s = (l.status ?? '').trim();
      if (s.isEmpty) continue;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    // Keep the known order first, then any extras.
    final result = <String, int>{};
    for (final k in order) {
      if (counts.containsKey(k)) result[k] = counts[k]!;
    }
    for (final e in counts.entries) {
      result.putIfAbsent(e.key, () => e.value);
    }
    return result;
  }

  /// Leads grouped by source (bar).
  Map<String, int> get sourceCounts {
    final counts = <String, int>{};
    for (final l in allLeads) {
      final s = (l.leadsource ?? '').trim();
      if (s.isEmpty) continue;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  /// Leads count by date (trend line), ascending by date.
  List<MapEntry<String, int>> get trendByDate {
    final counts = <String, int>{};
    for (final l in allLeads) {
      final d = (l.leaddate ?? '').trim();
      if (d.isEmpty) continue;
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => _dateKey(a.key).compareTo(_dateKey(b.key)));
    return entries;
  }

  // Turns 'dd-MM-yyyy' (or yyyy-MM-dd) into a sortable yyyyMMdd int.
  int _dateKey(String d) {
    final parts = d.contains('-') ? d.split('-') : d.split('/');
    if (parts.length != 3) return 0;
    // Detect which part is the 4-digit year.
    if (parts[0].length == 4) {
      return int.tryParse('${parts[0]}${parts[1]}${parts[2]}') ?? 0;
    }
    return int.tryParse('${parts[2]}${parts[1]}${parts[0]}') ?? 0;
  }

  void setSelectedLead(LeadData lead) {
    selectedLead = lead;
    // Slice the already-loaded bundle for this lead (no extra network call).
    followupList = bundle.followups
        .where((f) => f.leadId == lead.mainid)
        .toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    selectedItems = [];
    update();
  }

  // Detail slices for the selected lead (from the bundle).
  List<LeadTaskData> get selectedTasks =>
      bundle.tasks.where((t) => t.leadId == selectedLead?.mainid).toList();
  List<LeadNoteData> get selectedNotes =>
      bundle.notes.where((n) => n.leadId == selectedLead?.mainid).toList();
  LeadDocData? get latestEstimate {
    final list = bundle.estimates
        .where((e) => e.leadId == selectedLead?.mainid)
        .toList();
    return list.isEmpty ? null : list.first;
  }

  LeadDocData? get latestQuotation {
    final list = bundle.quotations
        .where((q) => q.leadId == selectedLead?.mainid)
        .toList();
    return list.isEmpty ? null : list.first;
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  String get _compId => homeController.currentUserData?.compId?.toString() ?? '';
  String get _branchId =>
      homeController.currentUserData?.branchId?.toString() ?? '0';
  String get _userId => homeController.currentUserData?.userid?.toString() ?? '0';

  void onSearch(String v) {
    searchText = v;
    update();
  }

  void setDateRange(String from, String to) {
    fromDate = from;
    toDate = to;
    loadDashboard();
  }

  void clearDateRange() {
    fromDate = '';
    toDate = '';
    loadDashboard();
  }

  /// Fetch the whole dashboard bundle from the API.
  Future<void> loadDashboard() async {
    setBusy(true);
    try {
      final res = await api.getLeadDashboard({
        'compid': _compId,
        'branchid': _branchId,
        'userid': _userId,
        'fromdate': fromDate,
        'todate': toDate,
      });
      if (res.status == 200 && res.data != null) {
        bundle = res.data!;
        allLeads = _withNextFollowup(bundle.leads);
      } else {
        bundle = LeadBundle();
        allLeads = [];
        if (res.status != 200) {
          ShowMessage.showSnackBar('Lead dashboard', res.message.toString());
        }
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      setBusy(false);
    }
  }

  // Backward-compat alias used by the entry/refresh flows.
  void getLeadList() => loadDashboard();

  // Compute each lead's next (latest) follow-up date from the bundle.
  List<LeadData> _withNextFollowup(List<LeadData> leads) {
    final byLead = <int, List<LeadFollowupData>>{};
    for (final f in bundle.followups) {
      if (f.leadId == null) continue;
      byLead.putIfAbsent(f.leadId!, () => []).add(f);
    }
    for (final l in leads) {
      final fs = byLead[l.mainid];
      if (fs == null || fs.isEmpty) continue;
      fs.sort((a, b) => _dateKey(b.followupdate ?? '')
          .compareTo(_dateKey(a.followupdate ?? '')));
      l.nextfollowupdate = fs.first.followupdate;
    }
    return leads;
  }

  /// Load item lines for the selected lead (detail screen "Lead Items").
  Future<void> loadSelectedItems() async {
    if (selectedLead?.mainid == null) return;
    itemsBusy = true;
    update();
    try {
      final res = await api.getLeadItems({
        'leadid': selectedLead!.mainid.toString(),
        'compid': _compId,
      });
      selectedItems = (res.status == 200) ? res.items : [];
    } catch (e) {
      selectedItems = [];
    } finally {
      itemsBusy = false;
      update();
    }
  }

  /// Follow-up history for the selected lead (already sliced from the bundle).
  Future<void> getFollowups() async {
    if (selectedLead?.mainid == null) return;
    followupList = bundle.followups
        .where((f) => f.leadId == selectedLead!.mainid)
        .toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    update();
  }

  // ══════════════════════ Detail write actions (Follow-up/Task/Note) ═════════
  String get _yearId =>
      homeController.currentUserData?.yearId?.toString() ?? '';

  // Reload the bundle, re-sync the open lead, and toast the result.
  // Callers that pop a full page afterwards (estimate/quotation) pass
  // showToast:false and toast after Get.back — popping the page while a GetX
  // snackbar is open dismisses the snackbar instead of the page. In-place
  // actions (follow-up/task/note) close only a dialog, so they keep the toast.
  Future<bool> _afterDetailWrite(dynamic res, String okMsg,
      {bool showToast = true}) async {
    if (res.status == 200) {
      await loadDashboard();
      final m = allLeads.where((l) => l.mainid == selectedLead?.mainid);
      if (m.isNotEmpty) setSelectedLead(m.first);
      if (showToast) {
        ShowMessage.showSnackBar(
            'Success', (res.message?.toString().isNotEmpty ?? false)
                ? res.message.toString()
                : okMsg);
      }
      return true;
    }
    ShowMessage.showSnackBar('Error', res.message?.toString() ?? 'Failed');
    return false;
  }

  Future<bool> submitFollowup({
    required String remarks,
    String status = '',
    int statusId = 0,
    String followupDate = '',
    String followupTime = '',
    String purpose = '',
  }) async {
    if (selectedLead?.mainid == null) return false;
    final res = await api.addLeadFollowup({
      'leadid': selectedLead!.mainid.toString(),
      'compid': _compId,
      'branchid': _branchId,
      'userid': _userId,
      'yearid': _yearId,
      'status': status,
      'statusid': statusId.toString(),
      'remarks': remarks,
      'followup_date': followupDate,
      'followup_time': followupTime,
      'purpose': purpose,
    });
    return _afterDetailWrite(res, 'Follow-up added');
  }

  Future<bool> submitTask({
    required String title,
    String description = '',
    String dueDate = '',
    String priority = '',
    String tags = '',
  }) async {
    if (selectedLead?.mainid == null) return false;
    final res = await api.addLeadTask({
      'leadid': selectedLead!.mainid.toString(),
      'compid': _compId,
      'branchid': _branchId,
      'userid': _userId,
      'yearid': _yearId,
      'tasktitle': title,
      'description': description,
      'duedate': dueDate,
      'priority': priority,
      'tags': tags,
      'assigneename': homeController.currentUserData?.name?.toString() ?? '',
      'clientreference': selectedLead?.companyname ?? '',
    });
    return _afterDetailWrite(res, 'Task created');
  }

  Future<bool> submitNote({
    String title = '',
    required String content,
  }) async {
    if (selectedLead?.mainid == null) return false;
    final res = await api.addLeadNote({
      'leadid': selectedLead!.mainid.toString(),
      'compid': _compId,
      'branchid': _branchId,
      'userid': _userId,
      'yearid': _yearId,
      'title': title,
      'content': content,
    });
    return _afterDetailWrite(res, 'Note added');
  }

  // ══════════════════════════ Estimation (from a lead) ══════════════════════
  List<LeadItemLine> estimateItems = [];

  void startEstimate() {
    estimateItems = [];
    if (itemMaster.isEmpty) loadFormData();
    update();
  }

  void addEstimateItem(LeadItemLine line) {
    estimateItems.add(line);
    update();
  }

  void removeEstimateItem(int index) {
    if (index >= 0 && index < estimateItems.length) {
      estimateItems.removeAt(index);
      update();
    }
  }

  double get estTotalQty => estimateItems.fold(0.0, (a, b) => a + b.quantity);
  double get estTotalAmount => estimateItems.fold(0.0, (a, b) => a + b.amount);
  double get estTotalGst => estimateItems.fold(0.0, (a, b) => a + b.gstAmount);
  double get estGrand => estTotalAmount + estTotalGst;

  Future<bool> submitEstimate({
    String customerOrderNo = '',
    String remarks = '',
    String date = '',
  }) async {
    if (selectedLead?.mainid == null) return false;
    if (estimateItems.isEmpty) {
      ShowMessage.showSnackBar('Required', 'Add at least one item');
      return false;
    }
    final res = await api.saveLeadEstimate({
      'leadid': selectedLead!.mainid.toString(),
      'compid': _compId,
      'branchid': _branchId,
      'userid': _userId,
      'yearid': _yearId,
      'partyid': '0',
      'partyname': selectedLead?.companyname ?? '',
      'customerorderno': customerOrderNo,
      'remarks': remarks,
      'estimatedate': date,
      'items': jsonEncode(estimateItems.map((e) => e.toJson()).toList()),
    });
    return _afterDetailWrite(res, 'Estimation created', showToast: false);
  }

  // ══════════════════════════ Quotation (from a lead) ═══════════════════════
  List<LeadItemLine> quotationItems = [];

  void startQuotation() {
    quotationItems = [];
    if (itemMaster.isEmpty) loadFormData();
    update();
  }

  void addQuotationItem(LeadItemLine line) {
    quotationItems.add(line);
    update();
  }

  void removeQuotationItem(int index) {
    if (index >= 0 && index < quotationItems.length) {
      quotationItems.removeAt(index);
      update();
    }
  }

  double get quoTotalQty => quotationItems.fold(0.0, (a, b) => a + b.quantity);
  double get quoTotalAmount => quotationItems.fold(0.0, (a, b) => a + b.amount);
  double get quoTotalGst => quotationItems.fold(0.0, (a, b) => a + b.gstAmount);
  double get quoGrand => quoTotalAmount + quoTotalGst;

  Future<bool> submitQuotation({
    String customerOrderNo = '',
    String remarks = '',
    String date = '',
  }) async {
    if (selectedLead?.mainid == null) return false;
    if (quotationItems.isEmpty) {
      ShowMessage.showSnackBar('Required', 'Add at least one item');
      return false;
    }
    final res = await api.saveLeadQuotation({
      'leadid': selectedLead!.mainid.toString(),
      'compid': _compId,
      'branchid': _branchId,
      'userid': _userId,
      'yearid': _yearId,
      'partyid': '0',
      'partyname': selectedLead?.companyname ?? '',
      'customerorderno': customerOrderNo,
      'remarks': remarks,
      'quotationdate': date,
      'items': jsonEncode(quotationItems.map((e) => e.toJson()).toList()),
    });
    return _afterDetailWrite(res, 'Quotation created', showToast: false);
  }

  // ══════════════════════════ LEAD ENTRY (create/edit) form ═════════════════
  LeadFormData formData = LeadFormData();
  bool formLoading = false;
  bool saving = false;

  // 0 = creating a new lead; >0 = editing that lead's mainid.
  int editingLeadId = 0;
  bool get isEditing => editingLeadId > 0;

  // Company type: 1 = Direct (free text), 2 = Existing (dropdown + auto-fill).
  int companyTypeId = 1;
  List<LeadOption> existingCompanies = [];
  int selectedCompanyId = 0;

  // Item grid + item master.
  List<LeadOption> itemMaster = [];
  List<LeadItemLine> itemLines = [];

  // "Type or pick" dropdown selections (id + typed/selected name).
  final Map<String, int> selId = {};
  final Map<String, String> selName = {};

  // Extra field controllers not present in the legacy form.
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController refNoController = TextEditingController();
  final TextEditingController refferByController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController approxAmtController = TextEditingController();
  final TextEditingController otherRemarksController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController gstController = TextEditingController();

  String get companyTypeName => companyTypeId == 2 ? 'Existing' : 'Direct';

  void setCompanyType(int id) {
    companyTypeId = id;
    if (id == 2 && existingCompanies.isEmpty) _loadCompanies();
    update();
  }

  /// Set a type-or-pick dropdown value (id=0 when the user typed a new value).
  void setOption(String field, int id, String name) {
    selId[field] = id;
    selName[field] = name;
    update();
  }

  /// Load the form dropdowns + item master (called when the entry screen opens).
  Future<void> loadFormData() async {
    formLoading = true;
    update();
    try {
      final res = await api.getLeadFormDropdowns(
          {'compid': _compId, 'branchid': _branchId});
      if (res.status == 200 && res.data != null) formData = res.data!;

      final im = await api.getLeadItemMaster({'compid': _compId});
      if (im.status == 200) itemMaster = im.data;
    } catch (e) {
      ShowMessage.showSnackBar('Lead form', '$e');
    } finally {
      formLoading = false;
      update();
    }
  }

  Future<void> _loadCompanies() async {
    try {
      final res = await api.getLeadCompanies(
          {'compid': _compId, 'branchid': _branchId});
      if (res.status == 200) {
        existingCompanies = res.data;
        update();
      }
    } catch (_) {}
  }

  /// User picked an Existing company → auto-fill from the party record.
  Future<void> onSelectExistingCompany(LeadOption company) async {
    selectedCompanyId = company.id;
    companyNameController.text = company.name;
    update();
    try {
      final res = await api.getLeadPartyDetail(
          {'compid': _compId, 'partyid': company.id.toString()});
      final d = res.detail;
      if (res.status == 200 && d != null) {
        if (d.address.isNotEmpty) companyAddressController.text = d.address;
        if (d.contactperson.isNotEmpty) {
          contactPersonController.text = d.contactperson;
        }
        if (d.mobileno.isNotEmpty) mobileNumberController.text = d.mobileno;
        if (d.emailid.isNotEmpty) emailController.text = d.emailid;
        if (d.ownername.isNotEmpty) ownerNameController.text = d.ownername;
        if (d.phoneno.isNotEmpty) phoneNumberController.text = d.phoneno;
        if (d.pincode.isNotEmpty) pincodeController.text = d.pincode;
        if (d.gstno.isNotEmpty) gstController.text = d.gstno;
        update();
      }
    } catch (_) {}
  }

  /// Prepare the entry form for a brand-new lead (clears any prior edit state).
  void startNewLead() {
    _resetEntry();
    update();
  }

  /// Open the entry form in EDIT mode for [lead]: fetch its full detail
  /// (EditLeadEntry header + items) and prefill every field.
  Future<void> openEditLead(LeadData lead) async {
    _resetEntry();
    editingLeadId = lead.mainid ?? 0;
    formLoading = true;
    update();
    try {
      if (itemMaster.isEmpty) await loadFormData(); // ensure dropdown options
      final res = await api.getLeadItems(
          {'leadid': (lead.mainid ?? 0).toString(), 'compid': _compId});
      final h = res.headerMap ?? {};
      String hs(String k) => (h[k] ?? '').toString();
      int hi(String k) => int.tryParse(hs(k)) ?? 0;

      companyNameController.text = hs('companyname');
      ownerNameController.text = hs('ownername');
      contactPersonController.text = hs('contactperson');
      mobileNumberController.text = hs('mobileno');
      alternateNumberController.text = hs('alternativemobileno');
      emailController.text = hs('emailid');
      websiteController.text = hs('website');
      companyAddressController.text = hs('companyaddress');
      phoneNumberController.text = hs('phoneno');
      businessNatureController.text = hs('businessnature');
      requirementController.text = hs('requirement');
      projectNameController.text = hs('projectname');
      refNoController.text = hs('refno');
      refferByController.text = hs('refferby');
      budgetController.text = _numText(h['budget']);
      approxAmtController.text = _numText(h['approxamt']);
      otherRemarksController.text = hs('otherremarks');
      pincodeController.text = hs('pincode');
      areaController.text = hs('area');
      whatsappController.text = hs('whatsappno');
      gstController.text = hs('gstno');

      final ld = _leadDateForForm(hs('leaddate'));
      if (ld.isNotEmpty) setSelectedDate(ld);

      companyTypeId = hi('companytypeid') == 2 ? 2 : 1;
      selectedCompanyId = hi('companynameid');
      if (companyTypeId == 2 && existingCompanies.isEmpty) _loadCompanies();

      setOption('leadSource', hi('leadsourceid'), hs('leadsource'));
      setOption('leadCategory', hi('leadcategoryid'), hs('leadcategory'));
      setOption('leadPriority', hi('leadpriorityid'), hs('leadpriority'));
      setOption('leadStatus', hi('leadstatusid'), hs('leadstatus'));
      setOption('designation', hi('designationid'), hs('designation'));
      setOption('marketSegment', hi('marketsegmentid'), hs('marketsegment'));
      setOption('industryType', hi('industrytypeid'), hs('industrytype'));
      setOption('assignTo', hi('assigntoid'), hs('assignto'));

      itemLines = res.items
          .map((it) => LeadItemLine(
                itemid: it.itemId ?? 0,
                itemname: it.itemName ?? '',
                quantity: it.quantity,
                saleprice: it.salePrice,
                mrp: it.mrp,
                billingunitid: it.billingUnitId ?? 0,
                billingunit: it.unit ?? '',
                sizename: it.size ?? '',
                weightname: it.weight ?? '',
              ))
          .toList();
    } catch (e) {
      ShowMessage.showSnackBar('Edit lead', '$e');
    } finally {
      formLoading = false;
      update();
    }
  }

  // Number → clean text ('' when zero/blank, no trailing .0).
  String _numText(dynamic v) {
    final d = double.tryParse((v ?? '').toString()) ?? 0;
    if (d == 0) return '';
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }

  // Normalise a stored lead date to an unambiguous yyyy-MM-dd for the form.
  String _leadDateForForm(String raw) {
    if (raw.isEmpty) return '';
    if (raw.contains('T')) return raw.split('T').first; // ISO datetime
    final parts = raw.split(RegExp(r'[-/]'));
    if (parts.length == 3 && parts[0].length <= 2) {
      // dd-MM-yyyy → yyyy-MM-dd
      return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    }
    return raw;
  }

  // ── item grid ──
  void addItemLine(LeadItemLine line) {
    itemLines.add(line);
    update();
  }

  void removeItemLine(int index) {
    if (index >= 0 && index < itemLines.length) {
      itemLines.removeAt(index);
      update();
    }
  }

  double get itemsTotalQty =>
      itemLines.fold(0.0, (a, b) => a + b.quantity);
  double get itemsTotalAmount =>
      itemLines.fold(0.0, (a, b) => a + b.amount);

  /// Build the save body and create the lead.
  Future<void> saveLeadEntry({bool isDraft = false}) async {
    unfocus();
    if (companyNameController.text.trim().isEmpty) {
      ShowMessage.showSnackBar('Required', 'Company name is required');
      return;
    }
    saving = true;
    update();
    try {
      final body = <String, String>{
        'compid': _compId,
        'branchid': _branchId,
        'userid': _userId,
        'yearid': homeController.currentUserData?.yearId?.toString() ?? '',
        'isdraft': isDraft ? '1' : '0',
        'leadid': editingLeadId.toString(), // 0 = create, >0 = update
        // header
        'companytypeid': companyTypeId.toString(),
        'companytype': companyTypeName,
        'companynameid': selectedCompanyId.toString(),
        'companyname': companyNameController.text.trim(),
        'ownername': ownerNameController.text.trim(),
        'contactperson': contactPersonController.text.trim(),
        'mobileno': mobileNumberController.text.trim(),
        'alternativemobileno': alternateNumberController.text.trim(),
        'emailid': emailController.text.trim(),
        'website': websiteController.text.trim(),
        'companyaddress': companyAddressController.text.trim(),
        'phoneno': phoneNumberController.text.trim(),
        'pincode': pincodeController.text.trim(),
        'area': areaController.text.trim(),
        'whatsappno': whatsappController.text.trim(),
        'gstno': gstController.text.trim(),
        'businessnature': businessNatureController.text.trim(),
        'requirement': requirementController.text.trim(),
        'projectname': projectNameController.text.trim(),
        'refno': refNoController.text.trim(),
        'refferby': refferByController.text.trim(),
        'budget': budgetController.text.trim(),
        'approxamt': approxAmtController.text.trim(),
        'otherremarks': otherRemarksController.text.trim(),
        'leaddate': selectDate == 'Lead Date' ? '' : selectDate,
        // type-or-pick dropdowns
        'leadsourceid': (selId['leadSource'] ?? 0).toString(),
        'leadsource': selName['leadSource'] ?? '',
        'leadcategoryid': (selId['leadCategory'] ?? 0).toString(),
        'leadcategory': selName['leadCategory'] ?? '',
        'leadpriorityid': (selId['leadPriority'] ?? 0).toString(),
        'leadpriority': selName['leadPriority'] ?? '',
        'leadstatusid': (selId['leadStatus'] ?? 0).toString(),
        'leadstatus': selName['leadStatus'] ?? '',
        'designationid': (selId['designation'] ?? 0).toString(),
        'designation': selName['designation'] ?? '',
        'marketsegmentid': (selId['marketSegment'] ?? 0).toString(),
        'marketsegment': selName['marketSegment'] ?? '',
        'industrytypeid': (selId['industryType'] ?? 0).toString(),
        'industrytype': selName['industryType'] ?? '',
        'assigntoid': (selId['assignTo'] ?? 0).toString(),
        'assignto': selName['assignTo'] ?? '',
        // items
        'items': jsonEncode(itemLines.map((e) => e.toJson()).toList()),
      };
      final res = await api.saveLead(body);
      if (res.status == 200) {
        final msg = res.message.toString();
        _resetEntry();
        await loadDashboard();
        // Navigate first, then toast on the list — popping the page while a GetX
        // snackbar is open dismisses the snackbar instead of the page.
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        backTap();
        ShowMessage.showSnackBar('Success', msg);
      } else {
        ShowMessage.showSnackBar('Error', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      saving = false;
      update();
    }
  }

  void _resetEntry() {
    for (final c in [
      leadNumberController, requirementController, companyNameController,
      ownerNameController, contactPersonController, mobileNumberController,
      alternateNumberController, emailController, websiteController,
      companyAddressController, phoneNumberController, businessNatureController,
      projectNameController, refNoController, refferByController,
      budgetController, approxAmtController, otherRemarksController,
      pincodeController, areaController, whatsappController, gstController,
    ]) {
      c.clear();
    }
    selId.clear();
    selName.clear();
    itemLines.clear();
    companyTypeId = 1;
    selectedCompanyId = 0;
    editingLeadId = 0;
    clearSelectedDate();
  }

  //  Text controllers
  /// Lead entry
  final TextEditingController leadNumberController = TextEditingController();
  final TextEditingController requirementController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController alternateNumberController =
      TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController companyAddressController =
      TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController businessNatureController =
      TextEditingController();

  /// Followup details
  final TextEditingController addressController = TextEditingController();
  final TextEditingController specificationController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController followupTimeController = TextEditingController();
  final TextEditingController remarkFollowController = TextEditingController();

  //  Focus nodes
  final FocusNode leadNoFocus = FocusNode();
  final FocusNode requirementFocus = FocusNode();
  final FocusNode companyNameFocus = FocusNode();
  final FocusNode ownerNameFocus = FocusNode();
  final FocusNode contactPersonFocus = FocusNode();
  final FocusNode mobileNoFocus = FocusNode();
  final FocusNode alternateNoFocus = FocusNode();
  final FocusNode emailIdFocus = FocusNode();
  final FocusNode websiteFocus = FocusNode();
  final FocusNode companyAddresFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode businessFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode specificationFocus = FocusNode();
  final FocusNode remarkFocus = FocusNode();
  final FocusNode followupTimeFocus = FocusNode();
  final FocusNode remarkFollowupFocus = FocusNode();

  //  Observables
  RxBool isCheck = false.obs;

  void onChangeValue(var value) {
    isCheck.value = value;
  }

  //  Date fields
  String selectDate = 'Lead Date';
  void setSelectedDate(String value) {
    selectDate = value;
    update();
  }

  void clearSelectedDate() {
    selectDate = 'Lead Date';
    update();
  }

  String selectDatef = 'Entry Date';
  void setSelectedDatef(String value) {
    selectDatef = value;
    update();
  }

  void clearSelected() {
    selectDatef = 'Entry Date';
    update();
  }

  String selectDate2 = 'Entry Date';
  void setSelectedDate2(String value) {
    selectDate2 = value;
    update();
  }

  void clearSelected2() {
    selectDate2 = 'Entry Date';
    update();
  }

  //  Validation
  bool _isLeadValidate() {
    if (leadNumberController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterLeadNo.tr,
      );
      return false;
    }
    if (requirementController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterRequirementSpecification.tr,
      );
      return false;
    }
    if (companyNameController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterCompanyName.tr,
      );
      return false;
    }
    if (ownerNameController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterOwnerName.tr,
      );
      return false;
    }
    if (contactPersonController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterContactPersonTxt.tr,
      );
      return false;
    }
    if (mobileNumberController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterMobileTxt.tr,
      );
      return false;
    }
    if (mobileNumberController.text.trim().length != 10) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterValidMobileTxt.tr,
      );
      return false;
    }
    if (alternateNumberController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterAlternateMobileNo.tr,
      );
      return false;
    }
    // ✅ FIX: was checking mobileNumber length twice — now correctly checks alternateNumber
    if (alternateNumberController.text.trim().length != 10) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterValidMobileTxt.tr,
      );
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterEmailIdTxt.tr,
      );
      return false;
    }
    if (websiteController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterWebsite.tr,
      );
      return false;
    }
    if (companyAddressController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterCompanyAddress.tr,
      );
      return false;
    }
    if (phoneNumberController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterPhoneNo.tr,
      );
      return false;
    }
    if (businessNatureController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterBusinessNature.tr,
      );
      return false;
    }
    return true;
  }

  bool _isFollowupValidate() {
    if (addressController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterAddress,
      );
      return false;
    }
    if (selectDatef == 'Entry Date') {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        'Please Select Entry Date',
      );
      return false;
    }
    if (specificationController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterRequirementSpecification,
      );
      return false;
    }
    if (remarksController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterRemark,
      );
      return false;
    }
    if (followupTimeController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterFollowupTime,
      );
      return false;
    }
    if (remarkFollowController.text.trim().isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt,
        AppString.pleaseEnterRemark,
      );
      return false;
    }
    return true;
  }

  //  API calls
  void addleadApi() async {
    unfocus();
    setBusy(true);
    if (_isLeadValidate()) {
      try {
        final Map<String, String> body = {
          'compid': _compId,
          'branchid': _branchId,
          'userid': _userId,
          'leadno': leadNumberController.text.trim(),
          'requirement': requirementController.text.trim(),
          'companyname': companyNameController.text.trim(),
          'ownername': ownerNameController.text.trim(),
          'contactperson': contactPersonController.text.trim(),
          'mobileno': mobileNumberController.text.trim(),
          'alternatemobileno': alternateNumberController.text.trim(),
          'email': emailController.text.trim(),
          'website': websiteController.text.trim(),
          'companyaddress': companyAddressController.text.trim(),
          'phoneno': phoneNumberController.text.trim(),
          'businessnature': businessNatureController.text.trim(),
          'leaddate': selectDate == 'Lead Date' ? '' : selectDate,
        };
        final res = await api.createLead(body);
        if (res.status == 200) {
          backTap();
          getLeadList(); // refresh list after add
          ShowMessage.showSnackBar('Success', res.message.toString());
        } else {
          ShowMessage.showSnackBar('Error', res.message.toString());
        }
      } catch (e) {
        ShowMessage.showSnackBar('Error', '$e');
      } finally {
        setBusy(false);
      }
    } else {
      setBusy(false);
    }
  }

  void followupDetailsApi() async {
    unfocus();
    if (selectedLead?.mainid == null) {
      ShowMessage.showSnackBar('Error', 'No lead selected for follow-up');
      return;
    }
    setBusy(true);
    if (_isFollowupValidate()) {
      try {
        final Map<String, String> body = {
          'leadid': selectedLead!.mainid.toString(),
          'compid': _compId,
          'branchid': _branchId,
          'userid': _userId,
          'entrydate': selectDatef == 'Entry Date' ? '' : selectDatef,
          'purpose': specificationController.text.trim(),
          'remarks': remarksController.text.trim(),
          'followup_time': followupTimeController.text.trim(),
          'followup_remark': remarkFollowController.text.trim(),
          'address': addressController.text.trim(),
          'companyname': selectedLead?.companyname ?? '',
          'contactperson': selectedLead?.contactperson ?? '',
          'mobileno': selectedLead?.mobilenumber ?? '',
        };
        final res = await api.addLeadFollowup(body);
        if (res.status == 200) {
          backTap();
          getFollowups(); // refresh history
          ShowMessage.showSnackBar('Success', res.message.toString());
        } else {
          ShowMessage.showSnackBar('Error', res.message.toString());
        }
      } catch (e) {
        ShowMessage.showSnackBar('Error', '$e');
      } finally {
        setBusy(false);
      }
    } else {
      setBusy(false);
    }
  }

  //  Dispose
  @override
  void onClose() {
    leadNumberController.dispose();
    requirementController.dispose();
    companyNameController.dispose();
    ownerNameController.dispose();
    contactPersonController.dispose();
    mobileNumberController.dispose();
    emailController.dispose();
    alternateNumberController.dispose();
    websiteController.dispose();
    companyAddressController.dispose();
    phoneNumberController.dispose();
    businessNatureController.dispose();
    addressController.dispose();
    specificationController.dispose();
    remarksController.dispose();
    followupTimeController.dispose();
    remarkFollowController.dispose();
    super.onClose();
  }
}
