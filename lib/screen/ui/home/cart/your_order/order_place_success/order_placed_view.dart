import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/utils/app_assets.dart';
import 'package:newdigitalerp/utils/app_bottom_button.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                            .copyWith(fontSize: 20, color: Colors.white),
                      ),
                      SizedBox(height: Get.height * .05),
                      Image.asset(
                        AppAssets.appLogo,
                        height: Get.height * .12,
                        fit: BoxFit.fill,
                      ),
                      SizedBox(height: Get.height * .04),
                      Image.asset(
                        AppAssets.successCenterImage,
                        height: Get.height * .35,
                        width: Get.width,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: Get.height * .04),
                      Image.asset(
                        AppAssets.successImage,
                        fit: BoxFit.fill,
                      ),
                      SizedBox(height: Get.height * .02),
                      Text(
                        'Congratulations',
                        style: const TextStyle()
                            .bold
                            .copyWith(fontSize: 20, color: green5Color),
                      ),
                      SizedBox(height: Get.height * .02),
                      Text(
                        'Your Order Placed Successfully',
                        style: const TextStyle().medium,
                      ),
                      const SizedBox(height: 60)
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
