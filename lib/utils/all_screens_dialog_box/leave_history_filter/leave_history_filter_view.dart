
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart' hide formatDate;
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/custom_dialogbox.dart';
import '../../../screen/base/base_controller.dart';

import 'leave_history_filter_controller.dart';

class LeaveHistoryFilterView extends StatelessWidget {
  const LeaveHistoryFilterView({super.key});

  static const Color _navy = Color(0xFF0A1628);
  static const Color _bg = Color(0xFFF7F9FC);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _neutral = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveHistoryFilterController>(
      init: LeaveHistoryFilterController(),
      builder: (controller) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: _sheet(context, controller),
      ),
    );
  }

  Widget _sheet(BuildContext context, LeaveHistoryFilterController controller) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      width: Get.width,
      height: Get.height,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: Get.width,
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: purpleLightest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.filter_list_sharp,
                          color: purpleColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text('Filter Leave History',
                        style: TextStyle(
                            color: _navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: _neutral),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => _toggleRow(
                          'Filter by Month',
                          Icons.calendar_view_month_rounded,
                          controller.isFilterByMonth.value,
                          () => controller.tapOnMonthSwitch(),
                        )),
                    const SizedBox(height: 12),
                    Obx(() => _toggleRow(
                          'Filter by Date Range',
                          Icons.date_range_rounded,
                          controller.isFilterByDate.value,
                          () => controller.tapOnDateSwitch(),
                        )),
                    const SizedBox(height: 20),
                    Obx(() => AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: controller.isFilterByMonth.value
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: _monthDropdownCard(controller),
                          secondChild: const SizedBox.shrink(),
                        )),
                    Obx(() => AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: controller.isFilterByDate.value
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: _dateRangeCard(controller, context),
                          secondChild: const SizedBox.shrink(),
                        )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () => controller.onApplyFilter(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: purpleColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: _navy.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5)),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Apply Filter',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).viewPadding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(String label, IconData icon, bool val, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: val ? _navy.withValues(alpha: 0.05) : _bg,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: val ? _navy.withValues(alpha: 0.3) : _border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    val ? _navy.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: val ? _navy : _neutral, size: 16),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: val ? _navy : _neutral,
                    fontSize: 13,
                    fontWeight: val ? FontWeight.w600 : FontWeight.w400)),
            const Spacer(),
            _neatSwitch(val),
          ],
        ),
      ),
    );
  }

  Widget _neatSwitch(bool val) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: val ? _navy : Colors.grey.shade300,
      ),
      child: Align(
        alignment: val ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
        ),
      ),
    );
  }

  Widget _monthDropdownCard(LeaveHistoryFilterController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Month',
              style: TextStyle(
                  color: _neutral,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          DropdownButtonHideUnderline(
            child: DropdownButton2<MonthData?>(
              isExpanded: true,
              hint: Text('Select month',
                  style: TextStyle(
                      color: _neutral.withValues(alpha: 0.6), fontSize: 13)),
              value: controller.selectedMonthDropdownValue,
              iconStyleData: const IconStyleData(
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: _navy, size: 20),
              ),
              buttonStyleData: ButtonStyleData(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: _surface,
                ),
              ),
              items: controller.monthDropdownList.map((items) {
                return DropdownMenuItem<MonthData?>(
                  value: items,
                  child: Text(items.name,
                      style: const TextStyle(
                          color: _navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (MonthData? newValue) =>
                  controller.setSelectedMonthValue(newValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRangeCard(
      LeaveHistoryFilterController controller, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Date Range',
              style: TextStyle(
                  color: _neutral,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _dateTile(
                      controller.firstDate, true, controller, context)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(width: 20, height: 1, color: _border),
              ),
              Expanded(
                  child: _dateTile(
                      controller.lastDate, false, controller, context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateTile(String value, bool isFirst,
      LeaveHistoryFilterController controller, BuildContext context) {
    int currentYear = int.parse(
        '${controller.homeController.currentUserData?.yearId?.split('-').first}');
    String date = isFirst ? controller.firstDate : controller.lastDate;
    DateTime initDate = date != AppString.dateTimeEmpty
        ? DateTime.parse(
            formatDate(date, AppString.ddMMyyyy, AppString.yyyyMMdd))
        : DateTime.now();

    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initDate,
          firstDate: AppConst.calenderFirstDate ?? DateTime(currentYear, 4, 1),
          lastDate:
              AppConst.calenderLastDate ?? DateTime(currentYear + 1, 3, 31),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: _navy, onPrimary: Colors.white),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          controller.setDate(
              DateFormat(AppString.ddMMyyyy).format(picked), isFirst);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 14, color: _navy),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value.isEmpty || value == AppString.dateTimeEmpty
                    ? (isFirst ? 'From' : 'To')
                    : value,
                style: TextStyle(
                    color: value.isEmpty || value == AppString.dateTimeEmpty
                        ? _neutral
                        : _navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
