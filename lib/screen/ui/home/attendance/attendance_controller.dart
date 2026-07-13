// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:newdigitalerp/app_routes/app_routes.dart';
// import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
// import 'package:newdigitalerp/home/home_contoller.dart';
// import 'package:newdigitalerp/screen/ui/home/attendance/attendance_model/attendance_model.dart';
// import 'package:newdigitalerp/services/api_service/request_keys.dart';
// import 'package:newdigitalerp/utils/app_constant_new.dart';
// import 'package:newdigitalerp/utils/shared_pre.dart';
// import 'package:newdigitalerp/utils/show_message.dart';
//
// class AttendanceController extends AppBaseController {
//   HomeController homeController = Get.find<HomeController>();
//   bool isAttendanceMarked = false;
//   List<AttendanceSummaryData>? attendanceSummaryData;
//   Position? currentPosition;
//   bool enableBtn = true;
//   bool isBtnShow = true;
//   String exeId = '';
//   final picker = ImagePicker();
//   var selectedImage = ''.obs;
//   var selectedImageBase64 = ''.obs;
//   var selectedImageFileName = ''.obs;
//   void setBtnShow() {
//     isBtnShow = !isBtnShow;
//     update();
//   }
//
//   @override
//   void onInit() {
//     // TODO: implement onInit
//     getAttendanceDetails(true);
//     super.onInit();
//   }
//
//   void setSelectedImage(String value) {
//     selectedImage.value = value;
//     update();
//   }
//
//   void tapOnApplyLeave() {
//     Get.toNamed(AppRoutes.leaveHistory);
//   }
//
//   void tapOnApprovedLeave() {
//     Get.toNamed(AppRoutes.approvedOrLeaveView, arguments: true);
//   }
//
//   void tapOnRejectedLeave() {
//     Get.toNamed(AppRoutes.approvedOrLeaveView, arguments: false);
//   }
//
//   void tapOnSeeMore() {
//     Get.toNamed(AppRoutes.attendanceList,
//         arguments: homeController.currentUserData?.userid.toString());
//   }
//
//   void getAttendanceDetails(bool isBusy) async {
//     setBusy(isBusy);
//     try {
//       Map<String, String> body = {};
//       body[RequestKeys.userId] =
//           homeController.currentUserData?.userid.toString() ?? '0';
//       body[RequestKeys.compId] =
//           homeController.currentUserData?.compId.toString() ?? '0';
//       body[RequestKeys.month] = DateTime.now().month.toString();
//       body[RequestKeys.fromDate] = getStartDateOfMonth(DateTime.now());
//       body[RequestKeys.toDate] = formatDate(DateTime.now().toString(),
//           AppString.dateTimeFormat, AppString.yyyyMMdd);
//       body[RequestKeys.filter] = 'yes';
//       var res = await api.getAttendanceSummary(body);
//       if (res.status == 200) {
//         attendanceSummaryData = res.data;
//
//         enableBtn = (attendanceSummaryData?[0].details?.last.date.toString() ==
//                     formatDate(DateTime.now().toString(),
//                         AppString.dateTimeFormat, AppString.ddMMyyyy) &&
//                 attendanceSummaryData?[0].details?.last.outTime != null)
//             ? false
//             : true;
//
//         isAttendanceMarked =
//             (attendanceSummaryData?[0].details?.last.date.toString() ==
//                         formatDate(DateTime.now().toString(),
//                             AppString.dateTimeFormat, AppString.ddMMyyyy) &&
//                     attendanceSummaryData?[0].details?.last.outTime == null)
//                 ? true
//                 : false;
//
//         /// for location route save API
//         homeController.setLocationSending(isAttendanceMarked);
//         SharedPre.setValue(SharedPre.isLocationSend, isAttendanceMarked);
//
//         /// For sorting date wise List
//         attendanceSummaryData?[0].details?.sort((a, b) {
//           if (DateTime.parse(formatDate(
//                   a.date.toString(), AppString.ddMMyyyy, AppString.yyyyMMdd))
//               .isBefore(DateTime.parse(formatDate(b.date.toString(),
//                   AppString.ddMMyyyy, AppString.yyyyMMdd)))) {
//             return 1;
//           }
//           return 0;
//         });
//
//         update();
//       } else {
//         //ShowMessage.showSnackBar('Server Res', res.message.toString());
//       }
//     } catch (e) {
//       ShowMessage.showSnackBar('Server Res catch', '$e');
//     } finally {
//       setBusy(false);
//     }
//   }
//
//   void tapOnMarkAttendance() async {
//     setBtnShow();
//     try {
//       print("Base64=>${selectedImageBase64.value}");
//       currentPosition = await getUserCurrentPosition();
//       String currentAddress = await getUserCurrentAddress();
//       String battery = await getBatteryPercent();
//       Map<String, String> body = {
//         RequestKeys.compId:
//             homeController.currentUserData?.compId.toString() ?? '',
//         RequestKeys.branchId:
//             homeController.currentUserData?.branchId.toString() ?? '',
//         RequestKeys.userId:
//             homeController.currentUserData?.userid.toString() ?? '',
//         RequestKeys.yearId:
//             homeController.currentUserData?.yearId.toString() ?? '',
//         RequestKeys.latitude: currentPosition?.latitude.toString() ?? '0',
//         RequestKeys.longitude: currentPosition?.longitude.toString() ?? '0',
//         RequestKeys.location: currentAddress.toString(),
//         RequestKeys.attendanceType: isAttendanceMarked ? 'close' : 'mark',
//         RequestKeys.batteryLevel: battery.toString(),
//         RequestKeys.filename: selectedImageFileName.value,
//         RequestKeys.photo: selectedImageBase64.value,
//       };
//       debugPrint("body=>${jsonEncode(body)}");
//
//       // body[RequestKeys.compId] = homeController.currentUserData?.compId.toString() ?? '';
//       // body[RequestKeys.branchId] = homeController.currentUserData?.branchId.toString() ?? '';
//       // body[RequestKeys.userId] = homeController.currentUserData?.userid.toString() ?? '';
//       // body[RequestKeys.yearId] = homeController.currentUserData?.yearId.toString() ?? '';
//       // body[RequestKeys.latitude] = currentPosition?.latitude.toString() ?? '0';
//       // body[RequestKeys.longitude] = currentPosition?.longitude.toString() ?? '0';
//       // body[RequestKeys.location] = currentAddress.toString();
//       // body[RequestKeys.attendanceType] = isAttendanceMarked ? 'close' : 'mark';
//       // body[RequestKeys.batteryLevel] = battery.toString();
//       // body[RequestKeys.filename] = "";
//       // body[RequestKeys.photo]="";
//       var res = await api.markAttendance(body);
//       if (res.status == 200) {
//         isAttendanceMarked = !(isAttendanceMarked);
//         getAttendanceDetails(false);
//       } else {
//         ShowMessage.showSnackBar('Server Res', res.message.toString());
//       }
//     } catch (e) {
//       ShowMessage.showSnackBar('catch Server Res', '$e');
//     } finally {
//       setBtnShow();
//     }
//   }
//
//   Future<void> getExecutiveDropDownList({String? executiveId}) async {
//     try {
//       Map<String, String> body = {};
//       body[RequestKeys.userId] =
//           homeController.currentUserData?.userid.toString() ?? '342613';
//       body[RequestKeys.compId] =
//           homeController.currentUserData?.compId.toString() ?? '39';
//       body[RequestKeys.executiveId] = executiveId ?? '0';
//       var res = await api.getExecutiveDropdown(body);
//       if (res.status == 200) {
//         // executiveList = res.data ?? [];
//         update();
//       } else {
//         ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
//       }
//     } catch (e) {
//       ShowMessage.showSnackBar('catch Server Res', '$e');
//     }
//   }
// }



import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/repo/reimbursement_repo.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/response/attendance_summary_response.dart';

class AttendanceController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  bool isAttendanceMarked = false;
  List<AttendanceSummaryData>? attendanceSummaryData;
  bool enableBtn = true;
  bool isBtnShow = true;
  var selectedImage = ''.obs;
  var selectedImageBase64 = ''.obs;
  var selectedImageFileName = ''.obs;

  void setBtnShow() {
    isBtnShow = !isBtnShow;
    update();
  }

  @override
  void onInit() {
    // Ask for location up-front when the screen opens, so the OS permission
    // dialog appears immediately instead of only during a punch (and only if
    // location services happened to be on). Non-blocking.
    _ensureLocationPermission();
    loadAttendanceSummary();
    super.onInit();
  }

  /// Prompt for location permission (and nudge the user to turn on location
  /// services) as soon as the Attendance screen is shown.
  Future<void> _ensureLocationPermission() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        // User previously blocked it — send them to settings to re-enable.
        await Geolocator.openAppSettings();
        return;
      }
      // Permission granted but the device's location toggle may still be off.
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        await Geolocator.openLocationSettings();
      }
    } catch (_) {/* best-effort — punching still works, just without GPS */}
  }

  Future<void> loadAttendanceSummary() async {
    setBusy(true);
    try {
      final u = homeController.currentUserData;
      final body = <String, String>{
        'compid': u?.compId?.toString() ?? '',
        'branchid': u?.branchId?.toString() ?? '',
        'userid': u?.userid?.toString() ?? '',
      };
      final res = await api.getAttendanceSummary(body);
      attendanceSummaryData =
          (res.status == 200) ? (res.data ?? <AttendanceSummaryData>[]) : <AttendanceSummaryData>[];
      _applyPunchState();
    } catch (e) {
      attendanceSummaryData = <AttendanceSummaryData>[];
    } finally {
      isBusy = false;
      update();
    }
  }

  /// Decide the button state from TODAY's record:
  ///   • no record            → Check In      (isAttendanceMarked = false)
  ///   • in-time, no out-time  → Check Out      (isAttendanceMarked = true)
  ///   • in-time AND out-time  → done for today  (button disabled)
  /// Without this the flag stayed false forever, so the button always said
  /// "Check In" even after punching in (and could never punch out).
  void _applyPunchState() {
    final now = DateTime.now();
    final today = '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.year}';

    final details = (attendanceSummaryData?.isNotEmpty ?? false)
        ? (attendanceSummaryData![0].details ?? const <DayDetails>[])
        : const <DayDetails>[];

    DayDetails? todayRec;
    for (final d in details) {
      if (d.date == today) {
        todayRec = d;
        break;
      }
    }

    final hasIn = (todayRec?.inTime ?? '').isNotEmpty;
    final hasOut = (todayRec?.outTime ?? '').isNotEmpty;
    isAttendanceMarked = hasIn && !hasOut; // checked in, awaiting check-out
    enableBtn = !(hasIn && hasOut); // both done → nothing more to punch today
  }

  void _loadDummyData() {
    attendanceSummaryData = [
      AttendanceSummaryData(
        month: 'May 2026',
        present: 18,
        absent: 3,
        totalcl: 1.0,
        totalel: 2.0,
        totalLeave: 12.0,
        remainingTotalLeave: 8.0,
        approveLeave: 3.0,
        rejectLeave: 1.0,
        details: [
          DayDetails(
            date: '21 May 2026',
            inTime: '09:05 AM',
            outTime: '06:10 PM',
            batterylevel: '87',
            photo: null,
            location: 'Delhi Office',
          ),
          DayDetails(
            date: '20 May 2026',
            inTime: '09:15 AM',
            outTime: null,
            batterylevel: '45',
            photo: null,
            location: 'Delhi Office',
          ),
          DayDetails(
            date: '19 May 2026',
            inTime: '09:00 AM',
            outTime: '05:55 PM',
            batterylevel: '72',
            photo: null,
            location: 'Delhi Office',
          ),
        ],
      ),
    ];
    isAttendanceMarked = false;
    enableBtn = true;
    isBtnShow = true;
    isBusy = false;
    update();
  }

  void setSelectedImage(String value) {
    selectedImage.value = value;
    update();
  }

  void tapOnApplyLeave() => Get.toNamed(AppRoutes.leaveHistory);
  void tapOnApprovedLeave() =>
      Get.toNamed(AppRoutes.approvedOrLeaveView, arguments: true);
  void tapOnRejectedLeave() =>
      Get.toNamed(AppRoutes.approvedOrLeaveView, arguments: false);
  void tapOnSeeMore() => Get.toNamed(AppRoutes.attendanceList,
      arguments: homeController.currentUserData?.userid.toString());

  Future<void> tapOnMarkAttendance() async {
    setBusy(true);
    try {
      final u = homeController.currentUserData;

      // Upload the captured selfie (if any) and send only its filename as `photo`
      // (the photo column is varchar(500); the file is served back as a URL by the API).
      String photoName = await _uploadSelfie();

      // Capture the device's current GPS + address for both mark (check-in) and
      // close (check-out). The proc stores latitudein/out + location/locationout.
      // Best-effort: if location is unavailable, fall back so attendance still marks.
      String lat = '0', lng = '0', loc = 'Mobile App';
      try {
        final pos = await getUserCurrentPosition();
        lat = pos.latitude.toString();
        lng = pos.longitude.toString();
        // Default the readable location to the coordinates so it is NEVER lost when
        // reverse-geocoding is unavailable on the device (the old code kept
        // 'Mobile App' even with valid coords).
        loc = '$lat, $lng';
        try {
          final marks =
              await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (marks.isNotEmpty) {
            final m = marks.first;
            final parts = <String?>[
              m.name, m.street, m.subLocality, m.locality,
              m.administrativeArea, m.postalCode, m.country,
            ].where((s) => (s ?? '').trim().isNotEmpty).map((s) => s!.trim());
            if (parts.isNotEmpty) loc = parts.join(', ');
          }
        } catch (_) {/* geocoding unavailable — keep the lat,lng string */}
      } catch (_) {/* location off/denied — proceed with defaults */}

      // Real device battery level (was previously hard-coded to 100).
      String battery = '100';
      try {
        final b = (await getBatteryPercent()).trim();
        if (b.isNotEmpty) battery = b;
      } catch (_) {/* battery read failed — keep default */}

      final body = <String, String>{
        'compid': u?.compId?.toString() ?? '',
        'branchid': u?.branchId?.toString() ?? '',
        'userid': u?.userid?.toString() ?? '',
        'yearid': u?.yearId?.toString() ?? '',
        'latitude': lat,
        'longitude': lng,
        'location': loc,
        'attendancetype': isAttendanceMarked ? 'close' : 'mark',
        'batterylevel': battery,
        'photo': photoName,
      };
      final res = await api.markAttendance(body);
      Get.snackbar('Attendance', res.message ?? '');
      if (res.status == 200) {
        isAttendanceMarked = !isAttendanceMarked;
        // Clear the captured selfie so the next punch doesn't reuse it.
        selectedImage.value = '';
        selectedImageBase64.value = '';
        selectedImageFileName.value = '';
        await loadAttendanceSummary();
      }
    } catch (e) {
      Get.snackbar('Attendance', '$e');
    } finally {
      isBusy = false;
      update();
    }
  }

  /// Uploads the captured selfie file and returns the stored filename (empty if none).
  /// Reuses the shared file-upload endpoint (wwwroot/ReimbursementFiles); the API turns
  /// the filename back into an image URL on the attendance detail/list.
  Future<String> _uploadSelfie() async {
    final path = selectedImage.value;
    if (path.isEmpty) return '';
    try {
      final res = await ReimbursementRepo.uploadReimbursementFile(path);
      if (res.status == true && res.statusCode == 200) {
        final jsonData = res.data as Map<String, dynamic>?;
        String fn = jsonData?['data']?['filename'] as String? ??
            jsonData?['data']?['file_name'] as String? ??
            jsonData?['filename'] as String? ??
            jsonData?['file_name'] as String? ??
            '';
        if (fn.contains('/')) fn = fn.split('/').last;
        return fn;
      }
    } catch (_) {/* non-blocking: mark attendance even if photo upload fails */}
    return '';
  }

  void getAttendanceDetails(bool isBusy) {
    loadAttendanceSummary();
  }
}