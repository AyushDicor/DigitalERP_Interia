
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/screen/auth/splash/splash_controller.dart';
import 'package:newdigitalerp/utils/app_assets.dart';

class SplashView extends StatelessWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      init: SplashController(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //  Stacked layers logo
              Image.asset(
                AppAssets.appLogo,
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 28),


              const Text(
                'Interia',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
