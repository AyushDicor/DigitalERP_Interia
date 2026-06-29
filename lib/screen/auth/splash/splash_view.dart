
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/screen/auth/splash/splash_controller.dart';

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
                'assets/images/ribbel.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 28),


              const Text(
                'Ribbel Life',
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
