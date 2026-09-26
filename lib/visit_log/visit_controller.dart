import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/response/party_dropdown_list_response.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:newdigitalerp/visit_log/visit_detail_view.dart';
import 'package:newdigitalerp/visit_log/visit_form_view.dart';
import 'package:newdigitalerp/visit_log/visit_models.dart';

/// Drives the Visit module: the visit-log list (filters + search), a visit
/// detail (attachments + follow-ups), and the New/Edit Visit form (enquiry,
/// party, purpose, GPS, measurements grid, attachments).
class VisitController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();

  // ── Session ──
  String get _compid =>
      homeController.currentUserData?.compId?.toString() ?? '';
  String get _branchid =>
      homeController.currentUserData?.branchId?.toString() ?? '';
  String get _userid =>
      homeController.currentUserData?.userid?.toString() ?? '';
  String get _yearid =>
      homeController.currentUserData?.yearId?.toString() ?? '';

  // ── Dropdowns / lookups ──
  VisitDropdowns dd = VisitDropdowns.fallback;
  List<OpenLead> openLeads = [];
  List<PartyDropdownData> parties = [];
  int selectedPartyId = 0;
  String selectedPartyName = '';

  // ── List + filters ──
  List<VisitListItem> visits = [];
  bool listLoading = false;
  String listError = '';
  DateTime? fromDate;
  DateTime? toDate;
  String statusFilter = 'Planned'; // default view = Planned; '' = all
  String purposeFilter = '';
  final TextEditingController searchCtrl = TextEditingController();

  // ── Detail ──
  VisitDetail? detail;
  bool detailLoading = false;
  final TextEditingController followupCtrl = TextEditingController();
  bool postingFollowup = false;

  // ── Form (new = id 0, edit = id > 0) ──
  int editingId = 0;
  final visitToCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final contactPersonCtrl = TextEditingController();
  final contactNoCtrl = TextEditingController();
  final distanceCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final outcomeCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  DateTime? visitDate;
  DateTime? checkIn;
  DateTime? checkOut;
  String formStatus = 'Completed';
  String formPurposeType = '';
  String formTravelMode = '';
  int leadId = 0;
  List<VisitMeasurement> measurements = [];
  List<PlatformFile> pickedFiles = [];
  bool saving = false;

  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _dtFmt = DateFormat('yyyy-MM-dd HH:mm');
  final dayFmt = DateFormat('dd MMM yyyy');

  @override
  void onInit() {
    super.onInit();
    // Default the list to the last 30 days (login yearid is an id, not a
    // label, so a server-side FY filter would empty the list — [[list-date-window]]).
    toDate = DateTime.now();
    fromDate = DateTime.now().subtract(const Duration(days: 30));
    loadDropdowns();
    loadList();
  }

  @override
  void onClose() {
    for (final c in [
      searchCtrl, followupCtrl, visitToCtrl, locationCtrl, contactPersonCtrl,
      contactNoCtrl, distanceCtrl, purposeCtrl, outcomeCtrl, latCtrl, lngCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  // ── Loads ──────────────────────────────────────────────────────────────
  Future<void> loadDropdowns() async {
    dd = await api.getVisitDropdowns({'compid': _compid});
    update();
  }

  Future<void> loadList() async {
    listLoading = true;
    listError = '';
    update();
    try {
      Map<String, String> body(String status) => {
            'compid': _compid,
            'userid': _userid,
            'status': status,
            'purposetype': purposeFilter,
            'search': searchCtrl.text.trim(),
            if (fromDate != null) 'fromdate': _dateFmt.format(fromDate!),
            if (toDate != null) 'todate': _dateFmt.format(toDate!),
          };
      if (statusFilter.isEmpty || statusFilter == 'Planned') {
        // Backend quirk: visit/list is disjoint by status — status='' returns
        // real saved visits (no enquiries), while status='Planned' returns ONLY
        // the pending-enquiry worklist (Id 0), dropping real Planned visits.
        // So both the All and Planned views must merge the two calls.
        final all = await api.getVisitList(body(''));
        final enquiryRows = await api.getVisitList(body('Planned'));
        final enquiries = enquiryRows.where((v) => v.isEnquiry).toList();
        if (statusFilter == 'Planned') {
          final plannedVisits = all
              .where((v) => !v.isEnquiry && v.status.toLowerCase() == 'planned')
              .toList();
          visits = [...plannedVisits, ...enquiries];
        } else {
          // All Status: every real visit + the pending enquiries.
          visits = [...all.where((v) => !v.isEnquiry), ...enquiries];
        }
      } else {
        visits = await api.getVisitList(body(statusFilter));
      }
      if (visits.isEmpty) listError = 'No visits found.';
    } catch (e) {
      listError = '$e';
    } finally {
      listLoading = false;
      update();
    }
  }

  void setStatusFilter(String s) {
    statusFilter = s;
    loadList();
  }

  void setPurposeFilter(String s) {
    purposeFilter = s;
    loadList();
  }

  Future<void> pickFromDate() async {
    final d = await _pickDate(fromDate ?? DateTime.now());
    if (d != null) {
      fromDate = d;
      loadList();
    }
  }

  Future<void> pickToDate() async {
    final d = await _pickDate(toDate ?? DateTime.now());
    if (d != null) {
      toDate = d;
      loadList();
    }
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: Get.context!,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );

  // ── Detail ───────────────────────────────────────────────────────────
  Future<void> openDetail(int id) async {
    detail = null;
    detailLoading = true;
    update();
    Get.to(() => const VisitDetailView());
    await _fetchDetail(id);
  }

  Future<void> _fetchDetail(int id) async {
    detailLoading = true;
    update();
    try {
      detail = await api.getVisitDetail({'compid': _compid, 'id': '$id'});
    } catch (_) {
      detail = null;
    } finally {
      detailLoading = false;
      update();
    }
  }

  Future<void> refreshDetail() async {
    final id = detail?.visit?.id ?? 0;
    if (id > 0) await _fetchDetail(id);
  }

  // ── Follow-ups ───────────────────────────────────────────────────────
  Future<void> addFollowup() async {
    final id = detail?.visit?.id ?? 0;
    final text = followupCtrl.text.trim();
    if (id <= 0 || text.isEmpty) return;
    postingFollowup = true;
    update();
    try {
      final res = await api.addVisitFollowup({
        'compid': _compid,
        'id': '$id',
        'comment': text,
        'userid': _userid,
      });
      if (res.status == 200) {
        followupCtrl.clear();
        await refreshDetail();
      } else {
        ShowMessage.showSnackBar('Follow-up', res.message ?? 'Could not add.');
      }
    } finally {
      postingFollowup = false;
      update();
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────
  Future<void> deleteVisit(int id) async {
    try {
      final res = await api
          .deleteVisit({'compid': _compid, 'id': '$id', 'userid': _userid});
      if (res.status == 200) {
        // Leave the detail screen FIRST, then show the snackbar. Get.snackbar
        // is a route, so showing it before Get.back() makes Get.back() pop the
        // snackbar instead of the page — leaving you stuck on detail with no
        // visible message.
        Get.back();
        await loadList();
        ShowMessage.showSnackBar('Visit', 'Visit deleted.');
      } else {
        ShowMessage.showSnackBar('Visit', res.message ?? 'Could not delete.');
      }
    } catch (e) {
      ShowMessage.showSnackBar('Visit', 'Could not delete — $e');
    }
  }

  // ── Attachments (shared store, modulekey "Visit") ─────────────────────
  // Pick files on the detail screen and upload them to the open visit at once.
  Future<void> addAttachmentsToCurrentVisit() async {
    final id = detail?.visit?.id ?? 0;
    if (id <= 0) return;
    final res = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (res == null) return;
    final files =
        res.files.where((f) => f.size > 0 && f.path != null).toList();
    if (files.isEmpty) return;
    detailLoading = true;
    update();
    final failures = <String>[];
    for (final f in files) {
      final err = await AttachmentRepo.upload(
        filePath: f.path!,
        compid: _compid,
        modulekey: AttachmentModule.visit,
        recordid: id,
        userid: _userid,
      );
      if (err != null) failures.add(err);
    }
    await refreshDetail();
    if (failures.isNotEmpty) {
      ShowMessage.showSnackBar('Attachment',
          '${failures.length} file(s) could not be uploaded — ${failures.first}');
    }
  }

  // image_picker returns a *scaled* copy in the cache dir when maxWidth/quality
  // are set, and the OS can purge that cache before we upload. Copy it into the
  // app's own documents dir right away so the path stays valid until upload.
  Future<String> _persistImage(XFile shot) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = shot.name.isEmpty ? 'photo.jpg' : shot.name;
    final dest =
        '${dir.path}/visit_att_${DateTime.now().millisecondsSinceEpoch}_$name';
    await shot.saveTo(dest);
    return dest;
  }

  // Capture a photo (camera) or pick one image (gallery) and upload it to the
  // open visit straight away — the on-site "snap a photo" flow.
  Future<void> addPhotoToCurrentVisit({required bool fromCamera}) async {
    final id = detail?.visit?.id ?? 0;
    if (id <= 0) return;
    final shot = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (shot == null) return;
    final path = await _persistImage(shot);
    detailLoading = true;
    update();
    final err = await AttachmentRepo.upload(
      filePath: path,
      compid: _compid,
      modulekey: AttachmentModule.visit,
      recordid: id,
      userid: _userid,
    );
    await refreshDetail();
    if (err != null) {
      ShowMessage.showSnackBar('Attachment', 'Could not upload photo — $err');
    }
  }

  Future<void> deleteAttachment(int attachmentId) async {
    final ok = await AttachmentRepo.delete(compid: _compid, id: attachmentId);
    if (ok) {
      await refreshDetail();
      ShowMessage.showSnackBar('Attachment', 'Attachment removed.');
    } else {
      ShowMessage.showSnackBar('Attachment', 'Could not delete file.');
    }
  }

  // ── Form ─────────────────────────────────────────────────────────────
  void startNew() {
    editingId = 0;
    leadId = 0;
    selectedPartyId = 0;
    selectedPartyName = '';
    visitDate = DateTime.now();
    checkIn = null;
    checkOut = null;
    formStatus = 'Completed';
    formPurposeType = '';
    formTravelMode = '';
    for (final c in [
      visitToCtrl, locationCtrl, contactPersonCtrl, contactNoCtrl,
      distanceCtrl, purposeCtrl, outcomeCtrl, latCtrl, lngCtrl,
    ]) {
      c.clear();
    }
    measurements = [];
    pickedFiles = [];
    loadOpenLeads();
    loadParties();
    Get.to(() => const VisitFormView());
  }

  // Tapping a pending-enquiry row in the Planned list logs a visit against it:
  // open a fresh form pre-seeded with the enquiry's lead + name.
  void startNewFromEnquiry(VisitListItem v) {
    startNew();
    leadId = v.leadId;
    if (v.visitTo.trim().isNotEmpty) visitToCtrl.text = v.visitTo.trim();
    if (v.contactPerson.trim().isNotEmpty) {
      contactPersonCtrl.text = v.contactPerson.trim();
    }
    update();
  }

  void startEdit() {
    final v = detail?.visit;
    if (v == null) return;
    editingId = v.id;
    leadId = v.leadId;
    selectedPartyId = v.partyId;
    selectedPartyName = v.partyId > 0 ? v.visitTo : '';
    visitDate = DateTime.tryParse(v.visitDate);
    checkIn = v.checkInTime.isNotEmpty ? DateTime.tryParse(v.checkInTime) : null;
    checkOut =
        v.checkOutTime.isNotEmpty ? DateTime.tryParse(v.checkOutTime) : null;
    formStatus = v.status.isNotEmpty ? v.status : 'Completed';
    formPurposeType = v.purposeType;
    formTravelMode = v.travelMode;
    visitToCtrl.text = v.visitTo;
    locationCtrl.text = v.location;
    contactPersonCtrl.text = v.contactPerson;
    contactNoCtrl.text = v.contactNo;
    distanceCtrl.text = v.distanceKm == 0 ? '' : _trim(v.distanceKm);
    purposeCtrl.text = v.purpose;
    outcomeCtrl.text = v.outcome;
    latCtrl.text = v.latitude == 0 ? '' : '${v.latitude}';
    lngCtrl.text = v.longitude == 0 ? '' : '${v.longitude}';
    measurements =
        (detail?.measurements ?? []).map((m) => VisitMeasurement.fromJson({
              'ItemName': m.itemName, 'Description': m.description,
              'Length': m.length, 'Width': m.width, 'Height': m.height,
              'Qty': m.qty, 'Unit': m.unit, 'Area': m.area, 'Remarks': m.remarks,
            })).toList();
    pickedFiles = [];
    loadOpenLeads();
    loadParties();
    Get.to(() => const VisitFormView());
  }

  Future<void> loadOpenLeads() async {
    openLeads =
        await api.getVisitOpenLeads({'compid': _compid, 'branchid': '0'});
    update();
  }

  // Pick an enquiry/lead for the visit. Seeds the required "Visited" field from
  // the enquiry label (strips the leading "3 - " code) when it's still blank, so
  // the enquiry → visit flow isn't blocked by the empty-visitto guard on save.
  void selectLead(int? v) {
    leadId = v ?? 0;
    if (leadId != 0 && visitToCtrl.text.trim().isEmpty) {
      OpenLead? match;
      for (final l in openLeads) {
        if (l.value == leadId) {
          match = l;
          break;
        }
      }
      if (match != null) {
        final txt = match.text;
        final i = txt.indexOf(' - ');
        final name = i >= 0 ? txt.substring(i + 3).trim() : txt.trim();
        if (name.isNotEmpty) visitToCtrl.text = name;
      }
    }
    update();
  }

  // Party picker (optional) — flat searchable list, sets partyid + prefills the
  // "Visited" name (still editable). partyid 0 = free-typed, per the API.
  // Sends branchid + executiveid too (executiveid=0 = no executive filter); the
  // widened endpoint uses them, the legacy one ignores them.
  Future<void> loadParties() async {
    if (parties.isNotEmpty) return; // load once per form session
    // Rich customer list (Fullpartydetailwithbranch) — carries mobileno/address/
    // location so selectParty can prefill Contact No + GPS. executiveid 0 = all.
    final res = await api.getFullPartyList({
      'compid': _compid,
      'branchid': _branchid,
      'executiveid': '0',
    });
    if (res.status == 200) parties = res.data ?? [];
    update();
  }

  void selectParty(PartyDropdownData p) {
    selectedPartyId = p.partyid ?? 0;
    selectedPartyName = (p.partyname ?? '').trim();
    if (selectedPartyName.isNotEmpty) visitToCtrl.text = selectedPartyName;
    // Non-destructively prefill from the enriched party record (widened
    // endpoint only; fields are null on the legacy shape). Never clobber what
    // the user already typed.
    final mob = (p.mobileno ?? '').trim();
    if (mob.isNotEmpty && contactNoCtrl.text.trim().isEmpty) {
      contactNoCtrl.text = mob;
    }
    final addr = (p.address ?? '').trim();
    if (addr.isNotEmpty && locationCtrl.text.trim().isEmpty) {
      locationCtrl.text = addr;
    }
    // location = "lat,lng" → seed GPS only when both are empty.
    final loc = (p.location ?? '').trim();
    if (loc.contains(',') &&
        latCtrl.text.trim().isEmpty &&
        lngCtrl.text.trim().isEmpty) {
      final parts = loc.split(',');
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts.length > 1 ? parts[1].trim() : '');
      if (lat != null && lng != null) {
        latCtrl.text = '$lat';
        lngCtrl.text = '$lng';
      }
    }
    update();
  }

  void clearParty() {
    selectedPartyId = 0;
    selectedPartyName = '';
    update();
  }

  Future<void> pickFormDate() async {
    final d = await _pickDate(visitDate ?? DateTime.now());
    if (d != null) {
      visitDate = d;
      update();
    }
  }

  Future<void> pickCheckIn() async {
    final dt = await _pickDateTime(checkIn);
    if (dt != null) {
      checkIn = dt;
      update();
    }
  }

  Future<void> pickCheckOut() async {
    final dt = await _pickDateTime(checkOut);
    if (dt != null) {
      checkOut = dt;
      update();
    }
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final base = initial ?? DateTime.now();
    final d = await _pickDate(base);
    if (d == null) return null;
    final t = await showTimePicker(
        context: Get.context!, initialTime: TimeOfDay.fromDateTime(base));
    if (t == null) return DateTime(d.year, d.month, d.day);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  // GPS capture — best-effort, mirrors the attendance flow.
  Future<void> captureGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        ShowMessage.showSnackBar('Location', 'Enable location permission in settings.');
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
      }
      final pos = await Geolocator.getCurrentPosition();
      latCtrl.text = pos.latitude.toStringAsFixed(6);
      lngCtrl.text = pos.longitude.toStringAsFixed(6);
      // Fill Location text from a reverse-geocode if it's still empty.
      if (locationCtrl.text.trim().isEmpty) {
        try {
          final marks =
              await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (marks.isNotEmpty) {
            final m = marks.first;
            final parts = <String?>[
              m.subLocality, m.locality, m.administrativeArea
            ].where((s) => (s ?? '').trim().isNotEmpty).map((s) => s!.trim());
            if (parts.isNotEmpty) locationCtrl.text = parts.join(', ');
          }
        } catch (_) {/* geocoding unavailable */}
      }
      update();
    } catch (e) {
      ShowMessage.showSnackBar('Location', 'Could not get GPS: $e');
    }
  }

  void addMeasurementRow() {
    measurements.add(VisitMeasurement());
    update();
  }

  void removeMeasurementRow(int i) {
    if (i >= 0 && i < measurements.length) {
      measurements.removeAt(i);
      update();
    }
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickFiles() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (res != null) {
      // Add to (not replace) the current selection; skip 0-byte / path-less parts.
      final more =
          res.files.where((f) => (f.size) > 0 && f.path != null).toList();
      pickedFiles = [...pickedFiles, ...more];
      update();
    }
  }

  // Capture a photo (camera) or pick one from the gallery and add it to the
  // form's pending attachment list (uploaded after save). Persist to a stable
  // path first — the scaled cache file can be purged before save runs.
  Future<void> pickImage({required bool fromCamera}) async {
    final shot = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (shot == null) return;
    final size = await shot.length();
    final path = await _persistImage(shot);
    pickedFiles = [
      ...pickedFiles,
      PlatformFile(name: shot.name, size: size, path: path),
    ];
    update();
  }

  void removePickedFile(int i) {
    if (i >= 0 && i < pickedFiles.length) {
      pickedFiles.removeAt(i);
      update();
    }
  }

  Future<void> saveVisit() async {
    if (visitToCtrl.text.trim().isEmpty) {
      ShowMessage.showSnackBar('Visit', 'Enter who/where was visited.');
      return;
    }
    if (visitDate == null) {
      ShowMessage.showSnackBar('Visit', 'Pick a visit date.');
      return;
    }
    if (checkIn != null && checkOut != null && checkOut!.isBefore(checkIn!)) {
      ShowMessage.showSnackBar('Visit', 'Check-out cannot be before check-in.');
      return;
    }

    saving = true;
    update();
    try {
      final rows = measurements.where((m) => !m.isEmpty).map((m) {
        // Convenience: default Area to L×W when the user left it blank.
        if (m.area == 0 && m.length > 0 && m.width > 0) {
          m.area = m.length * m.width;
        }
        return m.toSaveJson();
      }).toList();

      final body = <String, String>{
        'id': '$editingId',
        'compid': _compid,
        'branchid': _branchid,
        'userid': _userid,
        'yearid': _yearid,
        'visitdate': _dateFmt.format(visitDate!),
        'partyid': '$selectedPartyId',
        'visitto': visitToCtrl.text.trim(),
        'purposetype': formPurposeType,
        'purpose': purposeCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'contactperson': contactPersonCtrl.text.trim(),
        'contactno': contactNoCtrl.text.trim(),
        'checkin': checkIn != null ? _dtFmt.format(checkIn!) : '',
        'checkout': checkOut != null ? _dtFmt.format(checkOut!) : '',
        'distance': distanceCtrl.text.trim().isEmpty ? '0' : distanceCtrl.text.trim(),
        'travelmode': formTravelMode,
        'outcome': outcomeCtrl.text.trim(),
        'status': formStatus,
        'latitude': latCtrl.text.trim(),
        'longitude': lngCtrl.text.trim(),
        'leadid': '$leadId',
        'measurements': jsonEncode(rows),
      };

      final res = await api.saveVisit(body);
      if (!res.success || res.status != 200) {
        ShowMessage.showSnackBar('Not saved',
            res.message.isNotEmpty ? res.message : 'Could not save visit.');
        return;
      }

      // Upload any picked files against the saved visit id. The visit is
      // already saved, so an upload failure (e.g. S3 not configured for the
      // company) must NOT block leaving the form — just report it.
      final savedId = res.id > 0 ? res.id : editingId;
      final failures = <String>[];
      if (savedId > 0 && pickedFiles.isNotEmpty) {
        for (final f in pickedFiles) {
          if (f.path == null) continue;
          final err = await AttachmentRepo.upload(
            filePath: f.path!,
            compid: _compid,
            modulekey: AttachmentModule.visit,
            recordid: savedId,
            userid: _userid,
          );
          if (err != null) failures.add(err);
        }
      }

      // Leave the form FIRST, then show the snackbar — Get.snackbar is a route,
      // so showing it before Get.back() would pop the snackbar, not the form.
      Get.back();
      // If we edited an open detail, refresh it; always refresh the list.
      if (editingId > 0 && detail?.visit?.id == editingId) {
        await _fetchDetail(editingId);
      }
      await loadList();
      if (failures.isEmpty) {
        ShowMessage.showSnackBar('Visit', 'Visit ${res.visitNo} saved.');
      } else {
        ShowMessage.showSnackBar('Visit saved',
            'Saved, but ${failures.length} attachment(s) could not be uploaded — ${failures.first}');
      }
    } catch (e) {
      ShowMessage.showSnackBar('Not saved', '$e');
    } finally {
      saving = false;
      update();
    }
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
