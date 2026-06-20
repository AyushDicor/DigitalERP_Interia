// import 'package:newdigitalerp/app_routes/app_routes.dart';
// import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
// import 'package:newdigitalerp/utils/app_assets.dart';
// import 'package:newdigitalerp/utils/app_bottom_button.dart';
// import 'package:newdigitalerp/utils/app_constant_new.dart';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class OrderPlacedView extends StatefulWidget {
//   const OrderPlacedView({Key? key}) : super(key: key);
//
//   @override
//   State<OrderPlacedView> createState() => _OrderPlacedViewState();
// }
//
// class _OrderPlacedViewState extends State<OrderPlacedView> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       body: Center(
//         child: Container(
//           decoration: const BoxDecoration(
//               image: DecorationImage(
//                   image: AssetImage(AppAssets.successBg), fit: BoxFit.fill)),
//           child: SafeArea(
//             child: Stack(
//               children: [
//                 SingleChildScrollView(
//                   physics: const NeverScrollableScrollPhysics(),
//                   padding: const EdgeInsets.only(top: 10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         'Success',
//                         style: const TextStyle()
//                             .bold
//                             .copyWith(fontSize: 20, color: Colors.white),
//                       ),
//                       SizedBox(height: Get.height * .05),
//                       Image.asset(
//                         AppAssets.appLogo,
//                         height: Get.height * .12,
//                         fit: BoxFit.fill,
//                         errorBuilder: (_, __, ___) => Icon(
//                             Icons.check_circle_outline,
//                             size: Get.height * .12,
//                             color: Colors.white),
//                       ),
//                       SizedBox(height: Get.height * .04),
//                       Image.asset(
//                         AppAssets.successCenterImage,
//                         height: Get.height * .35,
//                         width: Get.width,
//                         fit: BoxFit.contain,
//                       ),
//                       SizedBox(height: Get.height * .04),
//                       Image.asset(
//                         AppAssets.successImage,
//                         fit: BoxFit.fill,
//                       ),
//                       SizedBox(height: Get.height * .02),
//                       Text(
//                         'Congratulations',
//                         style: const TextStyle()
//                             .bold
//                             .copyWith(fontSize: 20, color: green5Color),
//                       ),
//                       SizedBox(height: Get.height * .02),
//                       Text(
//                         'Your Order Placed Successfully',
//                         style: const TextStyle().medium,
//                       ),
//                       const SizedBox(height: 60)
//                     ],
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: AppBottomButton(
//                     onPressed: () => tapOnBottomButton(),
//                     name: 'Go To Orders' /*'More Logo. Let\'s do again'*/,
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   tapOnBottomButton() {
//     Get.offAndToNamed(AppRoutes.home, arguments: 4);
//   }
// }


import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/utils/app_assets.dart';
import 'package:newdigitalerp/utils/app_bottom_button.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../auth/base/base_contoller.dart';

// ── Local style tokens, matching the rest of the revamped flow ───────────────
const Color successBlueColor = Color(0xFF2A5BFF);
const Color successTextSecondary = Color(0xFF7A8195);

class OrderPlacedView extends StatefulWidget {
  const OrderPlacedView({Key? key}) : super(key: key);

  @override
  State<OrderPlacedView> createState() => _OrderPlacedViewState();
}

class _OrderPlacedViewState extends State<OrderPlacedView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar:  AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text('Place Order',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(AppAssets.successBg), fit: BoxFit.fill)),
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Success',
                        style: const TextStyle()
                            .bold
                            .copyWith(
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 0.2),
                      ),
                      SizedBox(height: Get.height * .045),
                      Image.asset(
                        AppAssets.appLogo,
                        height: Get.height * .12,
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.check_circle_outline,
                            size: Get.height * .12,
                            color: Colors.white),
                      ),
                      SizedBox(height: Get.height * .03),
                      // Image.asset(
                      //   AppAssets.successCenterImage,
                      //   height: Get.height * .32,
                      //   width: Get.width,
                      //   fit: BoxFit.contain,
                      // ),
                      // SizedBox(height: Get.height * .03),

                      // ── Result card ───────────────────────────────────
                      Container(
                        margin:
                        const EdgeInsets.symmetric(horizontal: 50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              offset: const Offset(0, 6),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: green5Color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                AppAssets.successImage,
                                height: 36,
                                width: 36,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.check_circle_rounded,
                                    size: 36,
                                    color: green5Color),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Congratulations',
                              textAlign: TextAlign.center,
                              style: const TextStyle()
                                  .bold
                                  .copyWith(
                                  fontSize: 19, color: green5Color),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your order has been placed successfully',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: successTextSecondary,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AppBottomButton(
                    onPressed: () => tapOnBottomButton(),
                    name: 'Go To Orders' /*'More Logo. Let\'s do again'*/,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  tapOnBottomButton() {
    Get.offAndToNamed(AppRoutes.home, arguments: 4);
  }
}