
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/response/executive_list_with_lat_long_response.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_list_model/executive_list_model.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/show_message.dart';

class ExecutiveListController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();
  ExecutiveDropdownData? selectedDropdownValue;
  List<ExecutiveLatLongData> executiveList = [];
  List<ExecutiveDropdownData>? executiveDropdownList = [];

  @override
  void onInit() async {
    // TODO: implement onInit
    await getDropdownList();
    super.onInit();
  }

  void setSelectDropdownValue(value) {
    selectedDropdownValue = value;
    getExecutiveListWithLatLong();
    update();
  }

  Future<void> getDropdownList() async {
    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] =
          homeController.currentUserData?.userid.toString() ?? '';
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      var res = await api.getExecutiveDropdown(body);
      if (res.status == 200) {
        // api.getExecutiveDropdown returns the response/ ExecutiveDropdownData type,
        // but this controller uses the executive_list_model one (same shape, different
        // class) — map across to avoid a runtime "is not a subtype" cast error.
        executiveDropdownList?.addAll((res.data ?? []).map(
          (e) => ExecutiveDropdownData(
            executiveId: e.executiveId,
            executiveName: e.executiveName,
          ),
        ));
        // if (dropdownList?.length == 1) {
        //   setSelectDropdownValue(dropdownList?[0]);
        // }
        // else{
        await getExecutiveListWithLatLong();
        // }
      } else {
        final msg = res.message ?? 'Executive dropdown unavailable';
        ShowMessage.showSnackBar('Server Res', msg);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> getExecutiveListWithLatLong() async {
    executiveList.clear();
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] =
          homeController.currentUserData?.userid.toString() ?? '';
      body[RequestKeys.compId] =
          homeController.currentUserData?.compId.toString() ?? '';
      body[RequestKeys.executiveId] =
          selectedDropdownValue?.executiveId.toString() ?? '';
      var res = await api.getExecutiveListWithLatLong(body);
      if (res.status == 200) {
        executiveList.addAll(res.data ?? []);
        update();
      } else {
        //ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('catch Server Res', '$e');
    } finally {}
  }

  // Open the executive's location in the phone's Google Maps app (or browser).
  // Prefers exact coordinates; falls back to searching the address text.
  Future<void> tapOnLiveLocation(int index) async {
    final e = executiveList[index];
    final lat = e.latitude ?? 0;
    final lng = e.longitude ?? 0;

    Uri uri;
    if (lat != 0 || lng != 0) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else if ((e.location ?? '').trim().isNotEmpty) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query='
          '${Uri.encodeComponent(e.location!.trim())}');
    } else {
      ShowMessage.showSnackBar('Location', 'No location available for this executive.');
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) ShowMessage.showSnackBar('Location', 'Could not open the map.');
    } catch (e) {
      ShowMessage.showSnackBar('Location', 'Could not open the map: $e');
    }
  }

  void tapOnCalender(int index) {
    // Get.toNamed(AppRoutes.executiveAttendance,
    //     arguments: executiveList[index].userid.toString());
    Get.toNamed(AppRoutes.executiveAttendance,
        arguments: executiveList[index]); // ← full ExecutiveLatLongData
  }
}
