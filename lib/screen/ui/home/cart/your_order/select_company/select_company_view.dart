// import 'package:newdigitalerp/response/get_executive_dropdown_response.dart';
// import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
// import 'package:newdigitalerp/screen/ui/home/cart/your_order/select_company/select_company_controller.dart';
// import 'package:newdigitalerp/utils/app_assets.dart';
// import 'package:newdigitalerp/utils/app_constant_new.dart';
// import 'package:newdigitalerp/utils/app_profile_image.dart';
// import 'package:newdigitalerp/utils/gradient_icon_app_button.dart';
// import 'package:newdigitalerp/utils/my_app_bar_new.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class SelectCompanyView extends StatelessWidget {
//   const SelectCompanyView({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<SelectCompanyController>(
//       init: SelectCompanyController(),
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
//                       image: DecorationImage(
//                           image: AssetImage(AppAssets.dashboardBg),
//                           fit: BoxFit.fill)),
//                   child: SafeArea(
//                       child: MyAppBar(
//                           title: 'Select Customer',
//                           onBackTap: () => controller.backTap())),
//                 ),
//               ),
//               Positioned(
//                 right: 0,
//                 left: 0,
//                 bottom: 0,
//                 top: Get.height * 0.135,
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: Get.height * 0.02),
//                       if (controller.isManager) _dropdown(controller),
//                       if (controller.isManager) const SizedBox(height: 20),
//                       TextFormField(
//                         decoration:
//                             const InputDecoration().searchTxtFieldStyle(),
//                         controller: controller.searchController,
//                         focusNode: controller.searchFocus,
//                         keyboardType: TextInputType.text,
//                         textInputAction: TextInputAction.search,
//                         onChanged: (value) => controller.searchCompany(value),
//                       ),
//                       controller.isListLoading
//                           ? Padding(
//                               padding: EdgeInsets.only(top: Get.height * 0.28),
//                               child: const Center(
//                                   child: CircularProgressIndicator()))
//                           : controller.companyList.isNotEmpty
//                               ? ListView.builder(
//                                   shrinkWrap: true,
//                                   padding: EdgeInsets.zero,
//                                   physics: const NeverScrollableScrollPhysics(),
//                                   itemCount: controller.companyList.length,
//                                   itemBuilder: (context, index) {
//                                     return companyCard(controller, index);
//                                   },
//                                 )
//                               : SizedBox(
//                                   height: Get.height * .2,
//                                   child: centerText(
//                                     'Party list Not Available',
//                                   ),
//                                 ),
//                       const SizedBox(height: 50),
//                     ],
//                   ),
//                 ),
//               ),
//               Positioned(
//                 right: 18,
//                 bottom: 35,
//                 child: GradientIconButton(
//                     onPressed: () => controller.tapOnAdd(),
//                     radius: 15,
//                     vPadding: 20),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget companyCard(SelectCompanyController controller, int index) {
//     var item = controller.companyList[index];
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 5),
//       constraints: const BoxConstraints(maxHeight: 160),
//       child: InkWell(
//         onTap: () => controller.tapOnCard(index),
//         child: Stack(
//           alignment: Alignment.topLeft,
//           fit: StackFit.loose,
//           children: [
//             Positioned(
//               left: 0,
//               top: 35,
//               right: 0,
//               child: Container(
//                 // height: 100,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(10),
//                   gradient: const LinearGradient(
//                       colors: /*item.isPending ? [orangeColor, orangeColor] :*/ grad1,
//                       stops: [0, 0.35],
//                       begin: Alignment.bottomCenter,
//                       end: Alignment.topCenter),
//                 ),
//                 // margin: const EdgeInsets.only(top: 20),
//                 alignment: Alignment.center,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       width: Get.width,
//                       decoration: const BoxDecoration(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(10),
//                           bottom: Radius.circular(25),
//                         ),
//                         color: Colors.white,
//                       ),
//                       padding:
//                           const EdgeInsets.only(left: 25, bottom: 10, top: 45),
//                       alignment: Alignment.bottomLeft,
//                       child: Text(
//                         item.partyname ?? '',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle().bold.copyWith(fontSize: 14),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       /*item.isPending ? 'Pending' : */
//                       'Select',
//                       style: const TextStyle()
//                           .bold
//                           .copyWith(color: whiteColor, fontSize: 14),
//                     ),
//                     const SizedBox(
//                       height: 8,
//                     )
//                   ],
//                 ),
//               ),
//             ),
//             const Positioned(
//               top: 0,
//               left: 20,
//               child: ProfileImageView(
//                 size: 65,
//                 imageUrl: dummyImageUrlTxt,
//                 borderSize: 2,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _dropdown(SelectCompanyController controller) {
//     return DropdownButtonHideUnderline(
//       child: DropdownButton2<ExecutiveDropdownData>(
//         isExpanded: true,
//         value: controller.selectedDropdownValue,
//         hint: Text(
//           'Select Executive user name',
//           style: const TextStyle().normal.copyWith(fontSize: 14),
//           overflow: TextOverflow.ellipsis,
//         ),
//         buttonStyleData: ButtonStyleData(
//           height: 40,
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(9),
//             color: dropdownBoxColor,
//           ),
//         ),
//         dropdownStyleData: DropdownStyleData(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(9),
//             color: dropdownBoxColor,
//           ),
//         ),
//         iconStyleData: IconStyleData(
//           icon: Image.asset(
//             AppAssets.dropdownIcon,
//             width: 15,
//             height: 15,
//           ),
//         ),
//         items: controller.yourOrderController.orderController.executiveList
//             .map((ExecutiveDropdownData items) {
//           return DropdownMenuItem(
//             value: items,
//             child: Text(items.executiveName.toString()),
//           );
//         }).toList(),
//         onChanged: (ExecutiveDropdownData? newValue) {
//           controller.setDropdownValue(newValue!);
//         },
//       ),
//     );
//   }
// }


import 'package:newdigitalerp/response/get_executive_dropdown_response.dart';
import 'package:newdigitalerp/screen/ui/home/cart/your_order/select_company/select_company_controller.dart';
import 'package:newdigitalerp/utils/app_assets.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/app_profile_image.dart';
import 'package:newdigitalerp/utils/gradient_icon_app_button.dart';
import 'package:newdigitalerp/utils/my_app_bar_new.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../auth/base/base_contoller.dart';

// ── Local style tokens, matching the YourOrderView / IndentReviewScreen look ─
const Color selCoBorderColor = Color(0xFFE3E7EF);
const Color selCoBlueColor = Color(0xFF2A5BFF);
const Color selCoBlueLightColor = Color(0xFFE9EEFF);
const Color selCoTextPrimary = Color(0xFF1C2233);
const Color selCoTextSecondary = Color(0xFF7A8195);

class SelectCompanyView extends StatelessWidget {
  const SelectCompanyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SelectCompanyController>(
      init: SelectCompanyController(),
      builder: (controller) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar:  AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: const Text('Select company',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ),
        body: Center(
          child: Stack(
            children: [
              // Positioned(
              //   top: 0,
              //   bottom: 0,
              //   right: 0,
              //   left: 0,
              //   child: Container(
              //     decoration: const BoxDecoration(
              //         image: DecorationImage(
              //             image: AssetImage(AppAssets.dashboardBg),
              //             fit: BoxFit.fill)),
              //     child: SafeArea(
              //         child: MyAppBar(
              //             title: 'Select Customer',
              //             onBackTap: () => controller.backTap())),
              //   ),
              // ),
              Positioned(
                right: 0,
                left: 0,
                bottom: 0,
                top: Get.height * 0.015,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: Get.height * 0.02),

                      // ── Filter card ─────────────────────────────────────
                      _SelectCoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (controller.isManager) ...[
                              const _SectionHead('Executive'),
                              const SizedBox(height: 10),
                              _dropdown(controller),
                              const SizedBox(height: 16),
                            ],
                            const _SectionHead('Search'),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: selCoBlueLightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextFormField(
                                decoration: const InputDecoration()
                                    .searchTxtFieldStyle(),
                                controller: controller.searchController,
                                focusNode: controller.searchFocus,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.search,
                                onChanged: (value) =>
                                    controller.searchCompany(value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Results ──────────────────────────────────────────
                      controller.isListLoading
                          ? Padding(
                          padding: EdgeInsets.only(top: Get.height * 0.2),
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: selCoBlueColor)))
                          : controller.companyList.isNotEmpty
                          ? Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                  child: _SectionHead('Customers')),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selCoBlueLightColor,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${controller.companyList.length} found',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: selCoBlueColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: controller.companyList.length,
                            itemBuilder: (context, index) {
                              return companyCard(controller, index);
                            },
                          ),
                        ],
                      )
                          : SizedBox(
                        height: Get.height * .2,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  size: 48,
                                  color: selCoTextSecondary),
                              SizedBox(height: 10),
                              Text(
                                'Party list not available',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selCoTextSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 35,
                child: GradientIconButton(
                    onPressed: () => controller.tapOnAdd(),
                    radius: 15,
                    vPadding: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget companyCard(SelectCompanyController controller, int index) {
    var item = controller.companyList[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => controller.tapOnCard(index),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selCoBorderColor),
          ),
          child: Row(
            children: [
              const ProfileImageView(
                size: 48,
                imageUrl: dummyImageUrlTxt,
                borderSize: 2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.partyname ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selCoTextPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selCoBlueColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(SelectCompanyController controller) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<ExecutiveDropdownData>(
        isExpanded: true,
        value: controller.selectedDropdownValue,
        hint: Text(
          'Select Executive user name',
          style: const TextStyle(fontSize: 14, color: selCoTextSecondary),
          overflow: TextOverflow.ellipsis,
        ),
        buttonStyleData: ButtonStyleData(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selCoBlueLightColor,
            border: Border.all(color: selCoBorderColor),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            border: Border.all(color: selCoBorderColor),
          ),
        ),
        iconStyleData: IconStyleData(
          icon: Image.asset(
            AppAssets.dropdownIcon,
            width: 15,
            height: 15,
          ),
        ),
        items: controller.yourOrderController.orderController.executiveList
            .map((ExecutiveDropdownData items) {
          return DropdownMenuItem(
            value: items,
            child: Text(
              items.executiveName.toString(),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selCoTextPrimary),
            ),
          );
        }).toList(),
        onChanged: (ExecutiveDropdownData? newValue) {
          controller.setDropdownValue(newValue!);
        },
      ),
    );
  }
}

// ── Reusable card + section head widgets ──────────────────────────────────
class _SelectCoCard extends StatelessWidget {
  final Widget child;
  const _SelectCoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, offset: Offset(0, 3), blurRadius: 5)
        ],
      ),
      child: child,
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  const _SectionHead(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: selCoTextPrimary),
    );
  }
}