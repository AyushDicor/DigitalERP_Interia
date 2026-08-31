// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:newdigitalerp/app_routes/app_pages.dart';
// import 'app_routes/app_routes.dart';
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//     statusBarColor: Colors.transparent,
//     statusBarIconBrightness: Brightness.dark,
//   ));
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Digital ERP',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF6366F1),
//         ),
//         useMaterial3: true,
//       ),
//       initialRoute: AppRoutes.splash,
//       getPages: AppPages.routes,   // ← this was commented out — must be uncommented
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:newdigitalerp/services/notification/task_notification_service.dart';
import 'package:newdigitalerp/app_routes/app_pages.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/firebase_options.dart';
import 'package:newdigitalerp/home/home_contoller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connect to the Firebase project (DigitalERP Dicor). Must run before any
  // Firebase API (e.g. FCM) is used.
  // Firebase (FCM push) may not be configured for every platform (e.g. a web/desktop
  // test build has no DefaultFirebaseOptions). Don't let that crash the whole app —
  // push just won't work there; everything else runs normally.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Handles a task push that arrives while the app is backgrounded/killed.
    // Registering it is harmless until the backend starts sending pushes.
    FirebaseMessaging.onBackgroundMessage(taskPushBackgroundHandler);
  } catch (_) {}
  // MUST init local storage BEFORE anything reads the saved session, otherwise
  // a fast cold start reads it before the box loads from disk → wrong/empty user.
  await GetStorage.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Register HomeController only AFTER storage is ready, so onInit reads the
  // real logged-in user (not a stale/dummy fallback).
  Get.put(HomeController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Dicor ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
