import 'package:flutter/foundation.dart';

void debugPrintData({required dynamic tittle, dynamic val}) {
  if (kDebugMode) {
    debugPrint("$tittle:-$val");
  }
}

String errorText = "Something went wrong";
String statusText = "Success";

Map<String, String> requestHeader() {
  return {
    "Content-Type": "application/json",
    // Required by the mobile API's X-Api-Key gate (Program.cs / Security:ApiKey).
    // The repo-stack baseUrl now points at our mobile API, so every call must carry it.
    "X-Api-Key": "nd3rp-M0b!le-2026-a7F3kQ9zR2xL8vN5pT4w",
  };
}
// TODO Implement this library.