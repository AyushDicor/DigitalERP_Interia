// ignore_for_file: prefer_typing_uninitialized_variables, duplicate_ignore

import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/handler_animation.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';

import 'package:newdigitalerp/screen/ui/home/attendance/attendance_list/attendance_list_controller.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/leave_history_view/leave_history_controller.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_attendance/executive_attendance_controller.dart';

import 'package:newdigitalerp/utils/app_assets.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/custom_dialogbox.dart' as prefix0;
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'filter_variable.dart';

class CustomDialogBox extends StatefulWidget {
  final int type;

  const CustomDialogBox({Key? key, required this.type}) : super(key: key);

  @override
  _CustomDialogBoxState createState() => _CustomDialogBoxState();
}

// ignore: duplicate_ignore
// ignore: prefer_typing_uninitialized_variables
class _CustomDialogBoxState extends State<CustomDialogBox>
    with TickerProviderStateMixin {
  var brandId;
  var indexOfSelectedValue;
  var selectedDropdown1Value;
  var selectedDropdown2Value;
  var selectedDropdown3Value;
  String firstDate = AppString.dateTimeEmpty;
  String lastDate = AppString.dateTimeEmpty;
  final HomeController homeController = Get.find<HomeController>();

  // OrderController? orderController;
  // VisitPlanController? visitPlanController;
  // NewVisitPlaningController? newVisitPlaningController;
  // PreviewController? previewController;
  // OrderDetailController? orderDetailController;
  // LeaveHistoryController? leaveHistoryController;
  // ProductListController? productListController;
  // ManagerLeaveHistoryController? managerLeaveHistoryController;

  AttendanceListController? attendanceListController;
  ExecutiveAttendanceController? executiveAttendanceController;

  int dialogType = 0;
  var dropdown1List = [];
  var dropdown2List = [];
  var dropdown3List = [];
  MonthData? selectedMonthDropdownValue;
  List<MonthData> monthDropdownList = [
    MonthData('April', 4),
    MonthData('May', 5),
    MonthData('June', 6),
    MonthData('July', 7),
    MonthData('August', 8),
    MonthData('September', 9),
    MonthData('October', 10),
    MonthData('November', 11),
    MonthData('December', 12),
    MonthData('January', 1),
    MonthData('February', 2),
    MonthData('March', 3),
  ];

  final double _lowerValue = 250;
  final double _upperValue = 10000;

  /*bool?isSwitched1 ;
  bool? isSwitched2 ;*/
  /*isSwitched2 = true;
   bool isSwitched1 = false;
   * */
  bool isFilterByDate = true;
  bool isFilterByMonth = false;

  RangeValues? currentRangeValues;

  void setDate(String value, bool isFirstDate) {
    setState(() {
      if (isFirstDate) {
        firstDate = value;
        debugPrint("--------fdate--------------$firstDate");
      } else {
        lastDate = value;
      }
    });
  }

  late AnimationController _animationController;

  @override
  void initState() {
    FilterScreanVariable.lowerLimit ?? _lowerValue;
    FilterScreanVariable.upperLimit ?? _upperValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 60));
    dialogType = widget.type;
    if (dialogType == attendanceListFilter) {
      attendanceListController = Get.find<AttendanceListController>();
    } else if (dialogType == executiveAttendanceFilter) {
      executiveAttendanceController = Get.find<ExecutiveAttendanceController>();
    }
    // orderDetailEdit, productListFilter, orderFilter not yet implemented
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: _contentBox(context),
    );
  }

  Widget _contentBox(context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: Get.height,
          width: Get.width,
          decoration: BoxDecoration(
            // image: DecorationImage(
            //   image: AssetImage(AppAssets.dialogBg),
            //   fit: BoxFit.fill,
            // ),
            gradient: customGradient(
              topColor: purpleColor,
              bottomColor: blueColor,
              opacity: 0.20,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          alignment: Alignment.center,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(top: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter',
                      style: const TextStyle().bold.copyWith(color: Colors.black),
                    ),
                    if (dialogType == attendanceListFilter ||
                        dialogType == executiveAttendanceFilter)
                      _monthColumn(),
                    if (dialogType == attendanceListFilter ||
                        dialogType == executiveAttendanceFilter)
                      _dateColumn(),
                    const SizedBox(height: 35),
                    _btn(context),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 8,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Image.asset(
                    AppAssets.coloredCloseIcon,
                    height: 50,
                    width: 50,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  FlutterSliderHandler customHandler() {
    return FlutterSliderHandler(
      child: Container(
        height: 26,
        width: 26,
        decoration: BoxDecoration(
          gradient: gr2,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: purpleColor, spreadRadius: 0.05, blurRadius: 10),
          ],
        ),
      ),
    );
  }

  Widget _productFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          'Price Range',
          style: const TextStyle().medium.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 45),
        FlutterSlider(
          values: [
            FilterScreanVariable.lowerLimit ?? 250,
            FilterScreanVariable.upperLimit ?? 10000,
          ],
          rangeSlider: true,
          max: 10000,
          min: 50,
          visibleTouchArea: false,
          trackBar: FlutterSliderTrackBar(
            inactiveTrackBarHeight: 3,
            activeTrackBarHeight: 4,
            inactiveTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.black12,
            ),
            activeTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: gr2,
            ),
          ),
          handler: customHandler(),
          rightHandler: customHandler(),
          handlerWidth: 20,
          handlerAnimation: const FlutterSliderHandlerAnimation(
            curve: Curves.ease,
            duration: Duration(milliseconds: 1000),
            scale: 1,
          ),
          tooltip: FlutterSliderTooltip(
            alwaysShowTooltip: true,
            disableAnimation: true,
            custom: (value) {
              return Text(
                '\u{20B9}${value.toInt().toString()}',
                style: const TextStyle().bold.copyWith(fontSize: 14),
              );
            },
          ),
          onDragging: (handlerIndex, lowerValue, upperValue) {
            /*_lowerValue = lowerValue;
            _upperValue = upperValue;*/
            setState(() {
              FilterScreanVariable.lowerLimit = lowerValue; //_lowerValue
              FilterScreanVariable.upperLimit = upperValue; //_upperValue
            });
          },
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'High to Low',
              style: const TextStyle().medium.copyWith(fontSize: 14),
            ),
            _switch(
              context: context,
              value: FilterScreanVariable.highToLow ?? false,
              onChanged: (val) {
                setState(() {
                  FilterScreanVariable.lowToHigh =
                      !(FilterScreanVariable.lowToHigh ?? true);
                  FilterScreanVariable.highToLow =
                      !(FilterScreanVariable.highToLow ?? false);
                });

                debugPrint(
                  "-----3----lowToHigh---------${FilterScreanVariable.lowToHigh}",
                );
                debugPrint(
                  "------3---HighlowTo--------${FilterScreanVariable.highToLow}",
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low to High',
              style: const TextStyle().medium.copyWith(fontSize: 14),
            ),
            _switch(
              context: context,
              value: FilterScreanVariable.lowToHigh ?? true,
              onChanged: (val) {
                setState(() {
                  FilterScreanVariable.lowToHigh =
                      !(FilterScreanVariable.lowToHigh!);
                  FilterScreanVariable.highToLow =
                      !(FilterScreanVariable.highToLow!);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ── _dropdown1 ─────────────────────────────────────────────────────────────
  Widget _dropdown1(int type) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 25),
        DropdownButtonHideUnderline(
          child: DropdownButton2(
            isExpanded: true,
            hint: Text(
              dialogType == orderFilter || dialogType == visitPlanFilter
                  ? 'Select Executive Name'
                  : dialogType == orderDetailEdit
                  ? 'Select status'
                  : dialogType == newVisitPlanFilter || dialogType == previewFilter
                  ? 'Select Nearby'
                  : dialogType == productListFilter
                  ? 'Select Brand'
                  : 'Select value',
              style: const TextStyle()
                  .normal
                  .copyWith(fontSize: 11, fontWeight: FontWeight.normal, color: msgTextColor),
              overflow: TextOverflow.ellipsis,
            ),
            value: selectedDropdown1Value,
            buttonStyleData: ButtonStyleData(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: dropdownBoxColor,
                gradient: LinearGradient(
                  colors: [grBottomColor.withValues(alpha: 0.2), grTopColor.withValues(alpha: 0.2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: dropdownBoxColor,
              ),
            ),
            items: dropdown1List.map((items) {
              if (dialogType == orderFilter) {
                return DropdownMenuItem(
                  value: items,
                  child: Text(items.executiveName.toString()),
                );
              } else if (dialogType == orderDetailEdit) {
                return DropdownMenuItem(
                  value: items,
                  child: Text(items.toString()),
                );
              } else if (dialogType == productListFilter) {
                return DropdownMenuItem(
                  value: items,
                  child: Text(items.subcategoryname.toString()),
                );
              } else {
                return DropdownMenuItem(
                  value: items,
                  child: Text(items),
                );
              }
            }).toList(),
            onChanged: (newValue) {
              indexOfSelectedValue = dropdown1List.indexOf(newValue);
              setSelectDropdownValue(newValue, type);
            },
          ),
        ),
      ],
    );
  }

  // ── _dropdown2 ─────────────────────────────────────────────────────────────
  Widget _dropdown2(int type) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 25),
        DropdownButtonHideUnderline(
          child: DropdownButton2(
            isExpanded: true,
            hint: Text(
              dialogType == orderFilter
                  ? 'Select Party Name'
                  : dialogType == visitPlanFilter || dialogType == newVisitPlanFilter
                  ? 'Select Area'
                  : 'Select value',
              style: const TextStyle()
                  .normal
                  .copyWith(fontSize: 11, fontWeight: FontWeight.normal, color: msgTextColor),
              overflow: TextOverflow.ellipsis,
            ),
            value: selectedDropdown2Value,
            iconStyleData: IconStyleData(
              icon: Image.asset(AppAssets.dropdownIcon, width: 15, height: 15),
            ),
            buttonStyleData: ButtonStyleData(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: dropdownBoxColor,
                gradient: LinearGradient(
                  colors: [orangeColor.withValues(alpha: 0.2), red2Color.withValues(alpha: 0.2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: dropdownBoxColor,
              ),
            ),
            items: dropdown2List.map((items) {
              if (dialogType == orderFilter) {
                return DropdownMenuItem(value: items, child: Text(items.partyname.toString()));
              } else {
                return DropdownMenuItem(value: items, child: Text(items.name.toString()));
              }
            }).toList(),
            onChanged: (newValue) => setSelectDropdownValue(newValue, type),
          ),
        ),
      ],
    );
  }

  // ── _dropdown3 ─────────────────────────────────────────────────────────────
  Widget _dropdown3(int type) {
    final currentValue = type == 0
        ? selectedDropdown1Value
        : type == 1
        ? selectedDropdown2Value
        : selectedDropdown3Value;

    final gradientColors = type == 0
        ? [grBottomColor.withValues(alpha: 0.2), grTopColor.withValues(alpha: 0.2)]
        : type == 1
        ? [orangeColor.withValues(alpha: 0.2), red2Color.withValues(alpha: 0.2)]
        : [yellowColor.withValues(alpha: 0.2), yellowColor.withValues(alpha: 0.2)];

    final List<DropdownMenuItem<dynamic>> dropItems = (type == 0
        ? dropdown1List.map((items) {
      if (dialogType == orderFilter) {
        return DropdownMenuItem(value: items, child: Text(items.executiveName.toString()));
      } else {
        return DropdownMenuItem(value: items, child: Text(items.name.toString()));
      }
    })
        : type == 1
        ? dropdown2List.map((items) {
      if (dialogType == orderFilter) {
        return DropdownMenuItem(value: items, child: Text(items.partyname.toString()));
      } else {
        return DropdownMenuItem(value: items, child: Text(items.name.toString()));
      }
    })
        : dropdown3List.map((items) {
      return DropdownMenuItem(value: items, child: Text(items.name.toString()));
    }))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 25),
        DropdownButtonHideUnderline(
          child: DropdownButton2(
            isExpanded: true,
            hint: Text(
              dialogType == orderFilter
                  ? 'Select Order'
                  : dialogType == visitPlanFilter
                  ? 'Select City'
                  : dialogType == newVisitPlanFilter
                  ? 'Select Status'
                  : 'Select value',
              style: const TextStyle()
                  .normal
                  .copyWith(fontSize: 11, fontWeight: FontWeight.normal, color: msgTextColor),
              overflow: TextOverflow.ellipsis,
            ),
            value: selectedMonthDropdownValue,
            iconStyleData: IconStyleData(
              icon: Image.asset(AppAssets.dropdownIcon, width: 15, height: 15),
            ),
            buttonStyleData: ButtonStyleData(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: dropdownBoxColor,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: dropdownBoxColor,
              ),
            ),
            items: dropItems,
            onChanged: (newValue) => setSelectDropdownValue(newValue, type),
          ),
        ),
      ],
    );
  }

  // ── _monthDropdown ─────────────────────────────────────────────────────────
  Widget _monthDropdown() {
    return DropdownButton2<MonthData?>(
      isExpanded: true,
      underline: const Divider(color: purpleColor, height: 2, thickness: 1),
      hint: Text(
        'Select month',
        style: const TextStyle()
            .normal
            .copyWith(fontSize: 11, fontWeight: FontWeight.normal, color: msgTextColor),
        overflow: TextOverflow.ellipsis,
      ),
      value: selectedMonthDropdownValue,
      iconStyleData: IconStyleData(
        icon: Image.asset(AppAssets.dropdownIcon, width: 15, height: 15),
      ),
      buttonStyleData: ButtonStyleData(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: dropdownBoxColor,
        ),
      ),
      items: monthDropdownList.map((items) {
        return DropdownMenuItem<MonthData?>(
          value: items,
          child: Text(items.name),
        );
      }).toList(),
      onChanged: (MonthData? newValue) => setSelectDropdownValue(newValue, 4),
    );
  }

  // ── _btn ───────────────────────────────────────────────────────────────────
  Widget _btn(BuildContext context) => Align(
    alignment: Alignment.center,
    child: Container(
      height: 40,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        gradient: customGradient(topColor: orangeColor, bottomColor: red2Color),
      ),
      child: MaterialButton(
        onPressed: () {
          if (!_dateValidate()) return;

          int currentYear =
          (int.tryParse('${homeController.currentUserData?.yearId?.split('-').first}') ?? DateTime.now().year);

          String monthFirstDate = formatDate(
              DateTime(
                  (selectedMonthDropdownValue != null &&
                      selectedMonthDropdownValue!.id < 4)
                      ? currentYear + 1
                      : currentYear,
                  selectedMonthDropdownValue?.id ?? 4,
                  1)
                  .toString(),
              AppString.dateTimeFormat,
              AppString.ddMMyyyy);

          String monthLastDate = formatDate(
              DateTime(
                  selectedMonthDropdownValue == null
                      ? currentYear + 1
                      : (selectedMonthDropdownValue!.id < 4)
                      ? currentYear + 1
                      : currentYear,
                  (selectedMonthDropdownValue?.id ?? 3) + 1)
                  .subtract(const Duration(days: 1))
                  .toString(),
              AppString.dateTimeFormat,
              AppString.ddMMyyyy);

          final String fromDate = formatDate(
            firstDate == AppString.dateTimeEmpty ? monthFirstDate : firstDate,
            AppString.ddMMyyyy,
            AppString.yyyyMMdd,
          );
          final String toDate = formatDate(
            lastDate == AppString.dateTimeEmpty ? monthLastDate : lastDate,
            AppString.ddMMyyyy,
            AppString.yyyyMMdd,
          );

          if (dialogType == attendanceListFilter) {
            attendanceListController?.getAttendanceList(
              month: selectedMonthDropdownValue?.id.toString(),
              fromDate: fromDate,
              toDate: toDate,
            );
          } else if (dialogType == executiveAttendanceFilter) {
            executiveAttendanceController?.getAttendanceDetails(
              true,
              month: selectedMonthDropdownValue?.id.toString(),
              fromDate: fromDate,
              toDate: toDate,
            );
          }

          Navigator.of(context).pop();
        },
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 10),
        child: const Text(
          'Apply',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );

  /*
  Widget _dateView2(String value, double width, bool isFirst) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: dialogType == attendanceListFilter || dialogType == leaveHistoryFilter
                  ? DateTime(
                  int.parse(
                      '${homeController.currentUserData?.yearId
                          ?.split('-')
                          .first
                          .toString()}'),
                  selectedMonthDropdownValue?.id ?? 1)
                  : DateTime.now(),
              firstDate: DateTime(dialogType == attendanceListFilter ? 2022 : 2000,
                  selectedMonthDropdownValue?.id ?? 1, 1),
              lastDate: DateTime(dialogType == attendanceListFilter ? DateTime
                  .now()
                  .year : 2101,
                  (selectedMonthDropdownValue?.id ?? 1) + 1)
                  .subtract(const Duration(days: 1)));

          if (pickedDate != null) {
            String formattedDate = DateFormat(ddMMyyyy).format(pickedDate);
            if (isFirst) {
              setDate(formattedDate, true);
            } else {
              setDate(formattedDate, false);
            }
          } else {
            print('Date is not selected');
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle().normal),
                const SizedBox(width: 10),
                Image.asset(
                  AppAssets.calendarIcon,
                  width: 18,
                  height: 18,
                )
              ],
            ),
            const SizedBox(height: 5),
            const Divider(
              color: purpleColor,
              height: 2,
            ),
          ],
        ),
      ),
    );
  }

   */

  DateTime initialDateOfPicker(int currentYear, String date) {
    // print("----------------------${DateTime.parse(firstDate)}");
    // print("----------------------${DateTime.now()}");
    return selectedMonthDropdownValue == null
        ? date != AppString.dateTimeEmpty
              ? DateTime.parse(
                  formatDate(date, AppString.ddMMyyyy, AppString.yyyyMMdd),
                )
              : DateTime.now()
        : DateTime(
            (selectedMonthDropdownValue != null &&
                    selectedMonthDropdownValue!.id < 4)
                ? currentYear + 1
                : currentYear,
            selectedMonthDropdownValue?.id ?? 4,
            1,
          );
  }

  DateTime firstDateOfPicker(int currentYear) {
    return DateTime(
      (selectedMonthDropdownValue != null && selectedMonthDropdownValue!.id < 4)
          ? currentYear + 1
          : currentYear,
      selectedMonthDropdownValue?.id ?? 4,
      1,
    );
  }

  DateTime lastDateOfPicker(int currentYear) {
    return DateTime(
      selectedMonthDropdownValue == null
          ? currentYear + 1
          : (selectedMonthDropdownValue!.id < 4)
          ? currentYear + 1
          : currentYear,
      (selectedMonthDropdownValue?.id ?? 3) + 1,
    ).subtract(const Duration(days: 1));
  }

  Widget _dateView(String value, double width, bool isFirst) {
    int currentYear = int.parse(
      '${homeController.currentUserData?.yearId?.split('-').first}',
    );
    String date = isFirst ? firstDate : lastDate;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: initialDateOfPicker(currentYear, date),
            firstDate:
                AppConst.calenderFirstDate ?? firstDateOfPicker(currentYear),
            lastDate:
                AppConst.calenderLastDate ?? lastDateOfPicker(currentYear),
          );

          if (pickedDate != null) {
            String formattedDate = DateFormat(
              AppString.ddMMyyyy,
            ).format(pickedDate);
            if (isFirst) {
              debugPrint("---------------------$formattedDate--");
              setDate(formattedDate, true);
            } else {
              setDate(formattedDate, false);
            }
          } else {
            if (kDebugMode) {
              debugPrint('Date is not selected');
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle().medium),
                  const SizedBox(width: 10),
                  Image.asset(AppAssets.calendarIcon, width: 18, height: 18),
                ],
              ),
            ),
            const Divider(color: purpleColor, thickness: 1),
          ],
        ),
      ),
    );
  }

  Widget _dateColumn() {
    return IgnorePointer(
      ignoring: !isFilterByDate,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          isFilterByDate ? Colors.transparent : lightGreyColor,
          BlendMode.saturation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Date',
              style: const TextStyle().bold.copyWith(
                fontSize: 10,
                color: red2Color,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dateView(firstDate, Get.width * .31, true),
                _dateView(lastDate, Get.width * .31, false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void tapOnDateOrMonthSwitch() {
    setState(() {
      isFilterByDate = !isFilterByDate;
      isFilterByMonth = !isFilterByMonth;
      if (isFilterByDate) {
        selectedMonthDropdownValue = null;
      }
      if (isFilterByMonth) {
        firstDate = AppString.dateTimeEmpty;
        lastDate = AppString.dateTimeEmpty;
      }
    });
  }

  Widget _monthColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter by Date',
              style: const TextStyle().medium.copyWith(fontSize: 14),
            ),
            _switch(
              context: context,
              value: isFilterByDate,
              onChanged: (val) => tapOnDateOrMonthSwitch(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter by Month',
              style: const TextStyle().medium.copyWith(fontSize: 14),
            ),
            _switch(
              context: context,
              value: isFilterByMonth,
              onChanged: (val) => tapOnDateOrMonthSwitch(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        IgnorePointer(
          ignoring: !isFilterByMonth,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              isFilterByMonth ? Colors.transparent : lightGreyColor,
              BlendMode.saturation,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Month',
                  style: const TextStyle().bold.copyWith(
                    fontSize: 10,
                    color: red2Color,
                  ),
                ),
                _monthDropdown(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _txt({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          title,
          style: const TextStyle().normal.copyWith(
            fontSize: 12,
            color: red2Color,
          ),
        ),
        const SizedBox(height: 10),
        Text(subtitle, style: const TextStyle().normal),
      ],
    );
  }

  // Widget _btn(BuildContext context) => Align(
  //       alignment: Alignment.center,
  //       child: Container(
  //         height: 40,
  //         decoration: ShapeDecoration(
  //           shape: const StadiumBorder(),
  //           gradient: customGradient(topColor: orangeColor, bottomColor: red2Color),
  //         ),
  //         child: MaterialButton(
  //           onPressed: () {
  //             /*int currentYear  = int.parse(DateFormat('yyyy').format(DateTime.now()));*/
  //
  //             int currentYear = (int.tryParse('${homeController.currentUserData?.yearId?.split('-').first}') ?? DateTime.now().year);
  //
  //             String monthFirstDate = formatDate(
  //                 DateTime(
  //                         (selectedMonthDropdownValue != null && selectedMonthDropdownValue!.id < 4)
  //                             ? currentYear + 1
  //                             : currentYear,
  //                         selectedMonthDropdownValue?.id ?? 4,
  //                         1)
  //                     .toString(),
  //                 AppString.dateTimeFormat,
  //                 AppString.ddMMyyyy);
  //             String monthLastDate = formatDate(
  //                 DateTime(
  //                         selectedMonthDropdownValue == null
  //                             ? currentYear + 1
  //                             : (selectedMonthDropdownValue!.id < 4)
  //                                 ? currentYear + 1
  //                                 : currentYear,
  //                         (selectedMonthDropdownValue?.id ?? 3) + 1)
  //                     .subtract(const Duration(days: 1))
  //                     .toString(),
  //                 AppString.dateTimeFormat,
  //                 AppString.ddMMyyyy);
  //             if (dialogType == attendanceListFilter) {
  //               if (_dateValidate()) {
  //                 attendanceListController?.getAttendanceList(
  //                   month: selectedMonthDropdownValue?.id.toString(),
  //                   fromDate: formatDate(firstDate == AppString.dateTimeEmpty ? monthFirstDate : firstDate,
  //                       AppString.ddMMyyyy, AppString.yyyyMMdd),
  //                   toDate: formatDate(lastDate == AppString.dateTimeEmpty ? monthLastDate : lastDate,
  //                       AppString.ddMMyyyy, AppString.yyyyMMdd),
  //                 );
  //                 Navigator.of(context).pop();
  //               }
  //             } else if (dialogType == executiveAttendanceFilter) {
  //               if (_dateValidate()) {
  //                 executiveAttendanceController?.getAttendanceDetails(
  //                   true,
  //                   month: selectedMonthDropdownValue?.id.toString(),
  //                   fromDate: formatDate(firstDate == AppString.dateTimeEmpty ? monthFirstDate : firstDate,
  //                       AppString.ddMMyyyy, AppString.yyyyMMdd),
  //                   toDate: formatDate(lastDate == AppString.dateTimeEmpty ? monthLastDate : lastDate,
  //                       AppString.ddMMyyyy, AppString.yyyyMMdd),
  //                 );
  //                 Navigator.of(context).pop();
  //               }
  //             } else if (dialogType == leaveHistoryFilter) {
  //               if (_dateValidate()) {
  //                 leaveHistoryController?.getDetails(
  //                   fromDate: formatDate(firstDate == AppString.dateTimeEmpty ? monthFirstDate : firstDate,
  //                       AppString.ddMMyyyy, AppString.yyyyMMdd),
  //                   toDate: formatDate(lastDate == AppString.dateTimeEmpty ? monthLastDate : lastDate,
  //                       AppString.ddMMyyyy, AppString.yyyyMMdd),
  //                 );
  //                 leaveHistoryController!.selectedMonth = selectedMonthDropdownValue as prefix0.MonthData?;
  //                 Navigator.of(context).pop();
  //               }
  //             } else if (dialogType == managerLeaveHistoryFilter) {
  //               if (_dateValidate()) {
  //                 managerLeaveHistoryController?.fromDate = formatDate(
  //                     firstDate == AppString.dateTimeEmpty ? monthFirstDate : firstDate,
  //                     AppString.ddMMyyyy,
  //                     AppString.yyyyMMdd);
  //                 managerLeaveHistoryController?.toDate = formatDate(
  //                     lastDate == AppString.dateTimeEmpty ? monthLastDate : lastDate,
  //                     AppString.ddMMyyyy,
  //                     AppString.yyyyMMdd);
  //                 managerLeaveHistoryController?.getPendingLeaveList();
  //                 managerLeaveHistoryController!.selectedMonth = selectedMonthDropdownValue as prefix0.MonthData?;
  //                 Navigator.of(context).pop();
  //               }
  //             } else if (dialogType == productListFilter) {
  //               //productListController!.brandId = brandId ?? 0;
  //               //productListController!.brandListIndex =
  //               //indexOfSelectedValue ?? 0;
  //
  //               /*FilterScreanVariable.highToLow =
  //                   !(FilterScreanVariable.highToLow ?? true);
  //
  //               FilterScreanVariable.lowToHigh =
  //                   !(FilterScreanVariable.lowToHigh ?? false);*/
  //
  //               productListController!.getFilterdProduct();
  //               Navigator.of(context).pop();
  //             } else if (dialogType == orderFilter) {
  //               if (_dateValidate()) {
  //                 orderController?.fromDate = formatDate(
  //                   firstDate == AppString.dateTimeEmpty ? monthFirstDate : firstDate,
  //                   AppString.ddMMyyyy,
  //                   AppString.yyyyMMdd,
  //                 );
  //                 orderController?.todate = formatDate(
  //                   lastDate == AppString.dateTimeEmpty ? monthLastDate : lastDate,
  //                   AppString.ddMMyyyy,
  //                   AppString.yyyyMMdd,
  //                 );
  //                 orderController?.selectedExecutiveDropdownValue = selectedDropdown1Value;
  //                 orderController?.selectedPartyDropdownValue = selectedDropdown2Value;
  //                 orderController?.getOrderList();
  //                 Navigator.of(context).pop();
  //               }
  //             } else if (dialogType == orderDetailEdit) {
  //               if (selectedDropdown1Value != null) {
  //                 orderDetailController?.updateOrderStatusApi(selectedDropdown1Value);
  //                 Navigator.of(context).pop();
  //               } else {
  //                 ShowMessage.showSnackBar(AppString.pleaseCheckTxt, AppString.selectStatusTxt);
  //               }
  //             } else {
  //               Navigator.of(context).pop();
  //             }
  //           },
  //           shape: const StadiumBorder(),
  //           padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 10),
  //           child: Text(
  //             dialogType == orderDetailEdit ? 'Done' : 'Apply',
  //             style: const TextStyle().bold.copyWith(color: Colors.white),
  //           ),
  //         ),
  //       ),
  //     );

  bool _dateValidate() {
    if (firstDate == AppString.dateTimeEmpty) {
      if (dialogType == leaveHistoryFilter ||
          dialogType == attendanceListFilter ||
          dialogType == managerLeaveHistoryFilter ||
          dialogType == executiveAttendanceFilter ||
          dialogType == orderFilter) {
      } else {
        ShowMessage.showSnackBar(
          AppString.pleaseCheckTxt,
          AppString.selectFromDateTxt,
        );
        return false;
      }
    } else if (lastDate == AppString.dateTimeEmpty) {
      if (dialogType == leaveHistoryFilter ||
          dialogType == attendanceListFilter ||
          dialogType == managerLeaveHistoryFilter ||
          dialogType == executiveAttendanceFilter ||
          dialogType == orderFilter) {
      } else {
        ShowMessage.showSnackBar(
          AppString.pleaseCheckTxt,
          AppString.selectToDateTxt,
        );
        return false;
      }
    } else if (DateFormat(AppString.ddMMyyyy)
        .parse(lastDate)
        .isBefore(DateFormat(AppString.ddMMyyyy).parse(firstDate))) {
      ShowMessage.showSnackBar(
        AppString.pleaseCheckTxt,
        AppString.dateGreaterThanFromTxt,
      );
      return false;
    } /*else if (DateFormat(ddMMyyyy).parse(lastDate).isAfter(DateTime.now())) {
      ShowMessage.showSnackBar(pleaseCheckTxt, dateGreaterThanTodayTxt);
      return false;
    }*/
    return true;
  }

  Widget _switch({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    Animation _circleAnimation =
        AlignmentTween(
          begin: value ? Alignment.centerRight : Alignment.centerLeft,
          end: value ? Alignment.centerLeft : Alignment.centerRight,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.linear),
        );
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            if (_animationController.isCompleted) {
              _animationController.reverse();
            } else {
              _animationController.forward();
            }
            value ? onChanged(true) : onChanged(false);
          },
          child: Container(
            width: 53.0,
            height: 28.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              gradient: _circleAnimation.value == Alignment.centerLeft
                  ? customGradient(
                      topColor: const Color(0xFFEEEEEE),
                      bottomColor: const Color(0xFFEEEEEE),
                    )
                  : customGradient(
                      topColor: purpleColor,
                      bottomColor: blueColor,
                      opacity: 0.48,
                    ),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleAnimation.value == Alignment.centerRight
                    ? const Padding(
                        padding: EdgeInsets.only(left: 24.0, right: 0),
                        // child: Text(
                        //   '',
                        //   style: TextStyle(
                        //       color: Colors.transparent,
                        //       fontWeight: FontWeight.w900,
                        //       fontSize: 16.0),
                        // ),
                      )
                    : Container(),
                Align(
                  alignment: _circleAnimation.value,
                  child: Container(
                    width: 22.0,
                    height: 22.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: customGradient(
                        topColor: purpleColor,
                        bottomColor: blueColor,
                      ),
                    ),
                  ),
                ),
                _circleAnimation.value == Alignment.centerLeft
                    ? const Padding(
                        padding: EdgeInsets.only(left: 0, right: 24.0),
                        child: Text(
                          '',
                          style: TextStyle(
                            color: Colors.transparent,
                            fontWeight: FontWeight.w900,
                            fontSize: 16.0,
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        );
      },
    );
  }

  void setSelectDropdownValue(var value, int type) {
    if (type == 0) {
      setState(() {
        selectedDropdown1Value = value;
        // productListController not yet implemented
      });
    } else if (type == 1) {
      setState(() {
        selectedDropdown2Value = value;
      });
    } else if (type == 4) {
      setState(() {
        selectedMonthDropdownValue = value;
      });
    } else {
      setState(() {
        selectedDropdown3Value = value;
      });
    }
  }
}

class MonthData {
  String name;
  int id;

  MonthData(this.name, this.id);

  @override
  String toString() {
    return 'MonthData{name: $name, id: $id}';
  }
}
