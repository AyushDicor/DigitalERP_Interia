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

  //  The lead currently being viewed (set when a card is tapped).
  LeadData? selectedLead;
  List<LeadFollowupData> followupList = [];

  //  Lead items for the detail screen (fetched on demand from EditLeadEntry).
  List<LeadItemData> selectedItems = [];
  bool itemsBusy = false;

  // ── Search-filtered leads shown in the list ──
  List<LeadData> get leadList {
    if (searchText.trim().isEmpty) return allLeads;
    final q = searchText.toLowerCase();
    return allLeads.where((l) {
      return (l.companyname ?? '').toLowerCase().contains(q) ||
          (l.contactperson ?? '').toLowerCase().contains(q) ||
          (l.mobilenumber ?? '').toLowerCase().contains(q) ||
          (l.leadnumber ?? '').toLowerCase().contains(q) ||
          (l.leadsource ?? '').toLowerCase().contains(q) ||
          (l.status ?? '').toLowerCase().contains(q);
    }).toList();
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

  // ══════════════════════════ LEAD ENTRY (create) form ══════════════════════
  LeadFormData formData = LeadFormData();
  bool formLoading = false;
  bool saving = false;

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
        ShowMessage.showSnackBar('Success', res.message.toString());
        _resetEntry();
        await loadDashboard();
        backTap();
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
