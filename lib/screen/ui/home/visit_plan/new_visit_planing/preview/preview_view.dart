// import 'package:newdigitalerp/screen/base/base_controller.dart';
// import 'package:newdigitalerp/screen/ui/home/visit_plan/new_visit_planing/preview/preview_controller.dart';
// import 'package:newdigitalerp/utils/app_assets.dart';
// import 'package:newdigitalerp/utils/app_bottom_button.dart';
// import 'package:newdigitalerp/utils/app_constant.dart';
// import 'package:newdigitalerp/utils/gradient_icon_app_button.dart';
// import 'package:newdigitalerp/utils/my_app_bar_new.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class PreviewView extends StatelessWidget {
//   const PreviewView({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<PreviewController>(
//       init: PreviewController(),
//       builder: (controller) => Scaffold(
//         resizeToAvoidBottomInset: false,
//         body: Center(
//           child: Stack(
//             children: [
//               Positioned(
//                 top: 0,
//                 bottom: 0,
//                 right: 0,
//                 left: 0,
//                 child: Container(
//                   decoration: const BoxDecoration(
//                       image: DecorationImage(image: AssetImage(AppAssets.dashboardBg), fit: BoxFit.fill)),
//                   child: SafeArea(
//                       child: MyAppBar(
//                     title: 'Preview',
//                     onBackTap: () => controller
//                         .backTap(), /*onFilterTap: ()=>Get.dialog(
//                          CustomDialogBox(type: previewFilter),
//                       )*/
//                   )),
//                 ),
//               ),
//               Positioned(
//                 right: 0,
//                 left: 0,
//                 bottom: 0,
//                 top: Get.height * 0.135,
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: controller.isBusy
//                       ? SizedBox(height: Get.height * 0.6, child: const Center(child: CircularProgressIndicator()))
//                       : controller.previewVisitDataList.isEmpty
//                           ? SizedBox(
//                               height: Get.height * 0.6,
//                               child: Text(
//                                 'No Data Available',
//                                 style: const TextStyle().bold,
//                               ),
//                             )
//                           : Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   controller.previewVisitDataList.first.visitdate ?? '',
//                                   style: const TextStyle().bold.copyWith(color: red2Color),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 ListView.builder(
//                                   shrinkWrap: true,
//                                   padding: const EdgeInsets.only(top: 10),
//                                   physics: const NeverScrollableScrollPhysics(),
//                                   itemCount: controller.previewVisitDataList.length,
//                                   itemBuilder: (context, index) {
//                                     return planCard(controller, index);
//                                   },
//                                 ),
//                                 const SizedBox(height: 50),
//                               ],
//                             ),
//                 ),
//               ),
//               Align(
//                 alignment: Alignment.bottomCenter,
//                 child: AppBottomButton(onPressed: () => controller.tapOnSubmit(), name: 'Submit'),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   planCard(PreviewController controller, int index) {
//     var item = controller.previewVisitDataList[index];
//     return SizedBox(
//       height: 180,
//       child: Stack(
//         alignment: Alignment.centerRight,
//         children: [
//           Positioned(
//             left: 0,
//             top: 0,
//             right: 20,
//             bottom: 0,
//             child: Container(
//               decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.white),
//               margin: const EdgeInsets.symmetric(vertical: 10),
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Customer name',
//                     style: const TextStyle().bold.copyWith(fontSize: 12, color: purpleColor),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     item.clientname ?? '',
//                     style: const TextStyle().bold.copyWith(fontSize: 12, color: Colors.black),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     'Area',
//                     style: const TextStyle().bold.copyWith(fontSize: 12, color: purpleColor),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     item.areaname ?? '',
//                     style: const TextStyle().bold.copyWith(fontSize: 12, color: Colors.black),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     'Distance',
//                     style: const TextStyle().bold.copyWith(fontSize: 12, color: purpleColor),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     item.distance ?? '',
//                     style: const TextStyle().bold.copyWith(fontSize: 12, color: Colors.black),
//                   )
//                 ],
//               ),
//             ),
//           ),
//           GradientIconButton(
//             topColor: redColor,
//             bottomColor: redColor,
//             radius: 8,
//             vPadding: 12.5,
//             hPadding: 12.5,
//             onPressed: () => _showDialog(controller, index),
//             icon: AppAssets.deleteIcon,
//           )
//         ],
//       ),
//     );
//   }
//
//   void _showDialog(PreviewController controller, int index) {
//     Get.defaultDialog(
//       title: 'Warning',
//       backgroundColor: Colors.white,
//       radius: 12,
//       textCancel: 'Cancel',
//       textConfirm: 'Delete',
//       middleText: 'Are you sure you want to delete ?',
//       buttonColor: purpleColor,
//       confirmTextColor: Colors.white,
//       cancelTextColor: purpleColor,
//       onConfirm: () async {
//         Get.back();
//         controller.tapOnDelete(index);
//       },
//       onCancel: () {
//         //Get.back();
//       },
//     );
//   }
// }


// ══
//  preview_view.dart
// ══
import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/screen/ui/home/visit_plan/new_visit_planing/preview/preview_controller.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PreviewView extends StatelessWidget {
  const PreviewView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PreviewController>(
      init: PreviewController(),
      builder: (controller) => Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        resizeToAvoidBottomInset: false,

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x12000000),
          surfaceTintColor: Colors.white,
          centerTitle: false,
          leading: GestureDetector(
            onTap: () => controller.backTap(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: newTextPrimary, size: 20),
          ),
          title: const Text('Preview',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: newTextPrimary)),
        ),

        // ✅ Submit button as proper bottom bar
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => controller.tapOnSubmit(),
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                label: const Text('Submit',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: newBlueColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ),
        ),

        body: controller.isBusy
            ? showLoader(color: newBlueColor)
            : controller.previewVisitDataList.isEmpty
            ? Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(40)),
                child: const Icon(Icons.preview_outlined,
                    size: 38, color: Color(0xFF5B5FC7)),
              ),
              const SizedBox(height: 16),
              const Text('No Data Available',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: newTextPrimary)),
            ]))
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFD0D4F5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Color(0xFF5B5FC7)),
                    const SizedBox(width: 8),
                    Text(
                      controller.previewVisitDataList.first
                          .visitdate ??
                          '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: newTextPrimary),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount:
                  controller.previewVisitDataList.length,
                  itemBuilder: (ctx, i) =>
                      _planCard(controller, i),
                ),

                const SizedBox(height: 4),
                _visitDetailsSection(controller, context),
              ]),
        ),
      ),
    );
  }

  /// Visit details — the same field set as the web ERP's New Visit form.
  /// Captured here and submitted along with the plan.
  Widget _visitDetailsSection(PreviewController c, BuildContext context) {
    const border = Color(0xFFE8ECF0);
    const primary = Color(0xFF5B5FC7);

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 7, top: 14),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: newTextPrimary)),
        );

    Widget input(TextEditingController ctl, String hint,
            {int maxLines = 1, TextInputType? keyboard}) =>
        TextField(
          controller: ctl,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 13.5, color: newTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primary)),
          ),
        );

    // Options come from /api/visit/dropdowns, so the values always match what
    // the ERP accepts.
    Widget dropdown({
      required String? value,
      required String hint,
      required List<String> options,
      required void Function(String?) onChanged,
    }) =>
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(hint,
                  style: const TextStyle(
                      fontSize: 13.5, color: Color(0xFF94A3B8))),
              items: options
                  .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o,
                          style: const TextStyle(
                              fontSize: 13.5, color: newTextPrimary))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        );

    Future<void> pickDateTime({required bool isCheckIn}) async {
      final now = DateTime.now();
      final base = (isCheckIn ? c.checkIn : c.checkOut) ?? now;
      final date = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 2),
      );
      if (date == null) return;
      if (!context.mounted) return;
      final time = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(base));
      final picked = DateTime(date.year, date.month, date.day,
          time?.hour ?? 0, time?.minute ?? 0);
      isCheckIn ? c.setCheckIn(picked) : c.setCheckOut(picked);
    }

    Widget dateField(String hint, DateTime? value, bool isCheckIn) => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => pickDateTime(isCheckIn: isCheckIn),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.event_outlined, size: 17, color: Color(0xFF64748B)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(value == null ? hint : c.dtLabel(value),
                    style: TextStyle(
                        fontSize: 13,
                        color: value == null
                            ? const Color(0xFF94A3B8)
                            : newTextPrimary)),
              ),
              if (value != null)
                InkWell(
                  onTap: () =>
                      isCheckIn ? c.setCheckIn(null) : c.setCheckOut(null),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFF64748B)),
                ),
            ]),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label('Status'),
          dropdown(
            value: c.statuses.contains(c.status) ? c.status : null,
            hint: '-- Select --',
            options: c.statuses,
            onChanged: c.setStatus,
          ),

          label('Visited (party / place / person) *'),
          input(c.visitedCtrl, 'e.g. City Hospital'),

          label('Purpose Type'),
          dropdown(
            value: c.purposeType.isEmpty ? null : c.purposeType,
            hint: '-- Select --',
            options: c.purposeTypes,
            onChanged: c.setPurposeType,
          ),

          label('Location / City'),
          input(c.locationCtrl, 'Where is the visit'),

          label('Contact Person'),
          input(c.contactPersonCtrl, 'Who you are meeting'),

          label('Contact No'),
          input(c.contactNoCtrl, 'Phone number',
              keyboard: TextInputType.phone),

          label('Check-in'),
          dateField('dd-mm-yyyy --:--', c.checkIn, true),

          label('Check-out'),
          dateField('dd-mm-yyyy --:--', c.checkOut, false),

          label('Distance (km)'),
          input(c.distanceCtrl, 'e.g. 15',
              keyboard: const TextInputType.numberWithOptions(decimal: true)),

          label('Travel Mode'),
          dropdown(
            value: c.travelMode.isEmpty ? null : c.travelMode,
            hint: '-- Select --',
            options: c.travelModes,
            onChanged: c.setTravelMode,
          ),

          label('Purpose / Details'),
          input(c.purposeCtrl, 'What is this visit about', maxLines: 3),

          label('Outcome / Remarks'),
          input(c.outcomeCtrl, 'How did it go', maxLines: 3),

          label('Attachment (optional)'),
          ...c.pendingAttachments.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 18, color: primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.value.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: newTextPrimary)),
                  ),
                  IconButton(
                    onPressed: () => c.removeAttachment(e.key),
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF64748B)),
                    visualDensity: VisualDensity.compact,
                  ),
                ]),
              )),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: c.pickVisitAttachments,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.attach_file_rounded,
                    size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Text(
                  c.pendingAttachments.isEmpty
                      ? 'Choose file'
                      : 'Add another file',
                  style: const TextStyle(
                      fontSize: 13.5, color: Color(0xFF64748B)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(PreviewController controller, int index) {
    final item = controller.previewVisitDataList[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cardRow(Icons.person_outline_rounded,
                  'Customer Name', item.clientname ?? 'N/A'),
              const SizedBox(height: 10),
              _cardRow(Icons.place_outlined,
                  'Area', item.areaname ?? 'N/A'),
              const SizedBox(height: 10),
              _cardRow(Icons.straighten_outlined,
                  'Distance', item.distance ?? 'N/A'),
            ]),
          ),
          const SizedBox(width: 12),
          // Delete button
          GestureDetector(
            onTap: () => _showDeleteDialog(controller, index),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFE74C3C), size: 20),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _cardRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: newTextSecondary),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: newTextSecondary,
                fontWeight: FontWeight.w400)),
        const SizedBox(height: 1),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: newTextPrimary)),
      ]),
    ]);
  }

  void _showDeleteDialog(PreviewController controller, int index) {
    Get.defaultDialog(
      title: 'Delete Entry',
      titleStyle: const TextStyle(
          color: newTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      radius: 12,
      middleText: 'Are you sure you want to delete this entry?',
      middleTextStyle:
      const TextStyle(fontSize: 13, color: newTextSecondary),
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      buttonColor: const Color(0xFFE74C3C),
      confirmTextColor: Colors.white,
      cancelTextColor: newTextSecondary,
      onConfirm: () {
        Get.back();
        controller.tapOnDelete(index);
      },
    );
  }
}
