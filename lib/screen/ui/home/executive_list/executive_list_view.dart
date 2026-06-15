
import 'package:newdigitalerp/screen/ui/home/executive_list/executetive_list_controller.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/app_profile_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../fab/menu_fab.dart';


//  Color tokens matching Figma
const Color _bgPage = Color(0xFFF4F6FA);
const Color _white = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1A1A2E);
const Color _textSub = Color(0xFF7B8CAA);
const Color _borderColor = Color(0xFFE8ECF4);
const Color _dividerColor = Color(0xFFF0F2F7);
const Color _presentColor = newGreenColor;
const Color _presentBg = newGreenLightColor;
const Color _absentColor = newRedColor;
const Color _absentBg = newRedLightColor;
const Color _blueAccent = purpleColor;

class ExecutiveListView extends StatelessWidget {
  const ExecutiveListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExecutiveListController>(
      init: ExecutiveListController(),
      builder: (controller) => Scaffold(
        backgroundColor: _bgPage,
        body: Column(
          children: [
            _AppBar(),
            Expanded(
              child: controller.isBusy
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  _SearchDropdown(controller: controller),
                  const SizedBox(height: 4),
                  ...List.generate(
                    controller.executiveList.length,
                        (i) => _ExecutiveCard(
                      controller: controller,
                      index: i,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: MenuFab(parentMenuId: 2377),
      ),
    );
  }
}

//  App Bar
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 14,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Get.back(),
            child: SizedBox(
              width: 34,
              height: 34,
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: _textPrimary),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Executive List',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
          // Location target button
          // Container(
          //   width: 34, height: 34,
          //   decoration: BoxDecoration(
          //     shape: BoxShape.circle,
          //     border: Border.all(color: _blueAccent, width: 1.5),
          //   ),
          //   child: const Icon(Icons.my_location_rounded,
          //       size: 16, color: _blueAccent),
          // ),
        ],
      ),
    );
  }
}

//  Search / Dropdown
class _SearchDropdown extends StatelessWidget {
  final ExecutiveListController controller;
  const _SearchDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: controller.selectedDropdownValue,
          hint: const Text(
            'Search Executive',
            style: TextStyle(fontSize: 14, color: _textSub, fontWeight: FontWeight.w500),
          ),
          buttonStyleData: const ButtonStyleData(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              color: Colors.transparent,
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _white,
              border: Border.all(color: _borderColor),
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _textPrimary),
          ),
          items: controller.executiveDropdownList!.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item.executiveName.toString(),
                style: const TextStyle(fontSize: 14, color: _textPrimary, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: controller.setSelectDropdownValue,
        ),
      ),
    );
  }
}

//  Executive Card 
class _ExecutiveCard extends StatelessWidget {
  final ExecutiveListController controller;
  final int index;
  const _ExecutiveCard({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final item = controller.executiveList[index];
    final bool isPresent = item.attendence.toString() != AppString.absent;
    final Color statusColor = isPresent ? _presentColor : _absentColor;
    final Color borderColor = isPresent ? _presentBg : _absentBg;
    final bool hasLocation = item.location != null && item.location!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: GestureDetector(
        onTap: () => controller.tapOnCalender(index),
        child: Column(
          children: [
            //  Top row 
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: ClipOval(
                      child: ProfileImageView(
                        size: 44,
                        imageUrl: item.photo,
                        borderSize: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.executivename.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isPresent && item.date != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.date!.split('-').last.trim(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status badge
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.attendence.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //  Location section (only if present + has address) 
            if (hasLocation) ...[
              Container(
                  height: 1,
                  color: _dividerColor,
                  margin: const EdgeInsets.symmetric(horizontal: 14)),
              InkWell(
                onTap: () {
                  if (isPresent) controller.tapOnLiveLocation(index);
                },
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: _textSub),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.location.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSub,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: purpleColor, width: 1.5),
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            size: 16, color: purpleColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
