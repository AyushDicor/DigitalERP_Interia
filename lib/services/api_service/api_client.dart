import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:newdigitalerp/services/api_Inspector/alice.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../app_routes/app_routes.dart';

class ApiClient extends GetConnect {
  static final ApiClient _apiClient = ApiClient._internal();

  factory ApiClient() {
    return _apiClient;
  }
  ApiClient._internal();
  // ── Mobile API endpoint ──────────────────────────────────────
  // Requests are built as '$baseAppUrl$method' where method has no leading
  // slash (e.g. 'purchaseorder/list'), so this MUST end with a trailing '/'.
  // Without it every call 404s on '/apipurchaseorder/list'.
  // Production (live on IIS).
   static const baseAppUrl = 'http://newcoreerp.digitalerp.biz/api/';   // <-- REVERT to this before publishing
  // TEMP local web test → local API (Production mode, prod ERPPlatform). Web runs on the host, so localhost.
 // static const baseAppUrl = 'http://localhost:5080/api/';

 // static const baseAppUrl = 'http://10.0.2.2:5080/api/';
  // LOCAL DEV (emulator -> host:5080, API on ERPPlatform_Dev): 'http://10.0.2.2:5080/api/'
  // Earlier: 'http://103.180.212.12:5080/api/'

  // Shared API key — sent as "X-Api-Key" on every request. Must match the
  // backend's Security:ApiKey in appsettings.json.
  static const apiKey = 'nd3rp-M0b!le-2026-a7F3kQ9zR2xL8vN5pT4w';

  /// Merge the API key into any per-call headers.
  static Map<String, String> withApiKey([Map<String, String>? header]) {
    return {if (header != null) ...header, 'X-Api-Key': apiKey};
  }

  /// POST a raw JSON body to the mobile API ([baseAppUrl]).
  ///
  /// The usual [postMethod] form-encodes fields, which cannot represent a
  /// nested array — the Production saveentry call sends a `rows: [ ... ]` list,
  /// so it must go as real JSON with an explicit Content-Type. Stages/batches
  /// use this too, to match the backend's documented JSON contract exactly.
  Future<String> postAppJson({
    required String method,
    required Map<String, dynamic> body,
  }) async {
    final url = '$baseAppUrl$method';
    try {
      log(url);
      log(jsonEncode(body));
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'X-Api-Key': apiKey},
        body: jsonEncode(body),
      );
      log("RES -------------> ${response.statusCode}");
      log("RES --------B-----> ${response.body}");
      AliceInterceptor.getAlice.onHttpResponse(response);
      if (response.statusCode != 200) {
        return jsonEncode({
          "success": false,
          "message": "Server error (${response.statusCode})",
          "status": response.statusCode,
          "data": null,
        });
      }
      return response.body;
    } catch (e) {
      log('______ postAppJson error ${e.toString()}');
      return '';
    }
  }

  @override
  void onInit() {
    baseUrl = baseAppUrl;
    /*httpClient.addAuthenticator<void>((request) async {
      final token = SharedPre.getStringValue(SharedPre.authToken);
      request.headers['Authorization'] =  'Bearer $token';
      return request;
    });*/

    ///Authenticator will be called 3 times if HttpStatus is
    ///HttpStatus.unauthorized
    //httpClient.maxAuthRetries = 3;
  }
  /*Future<String> getMethod({
    required String method,
    Map<String, String>? header,
  }) async {
    try {
      log('$baseAppUrl$method');
      if (header != null) {
        log(header.toString());
      }
      final response = await get('$baseAppUrl$method', headers: header);
      log(response.bodyString ?? '');
      if (response.body['code'] == 401) {
        Get.offAndToNamed(
          AppRoutes.login,
          arguments: 'Session expired!!!\nPlease login again.',
        );
        return '';
      } else {
        return response.bodyString ?? '';
      }
    } catch (e) {
      log(e.toString());
      return '';
    }
  }*/

  Future<String> getMethod({
    required String method,
    Map<String, String>? header,
  }) async {
    try {
      log('$baseAppUrl$method');
      if (header != null) {
        log(header.toString());
      }
      // final response = await get('$baseAppUrl$method', headers: header);
      final response = await http.get(
        Uri.parse('$baseAppUrl$method'),
        headers: withApiKey(header),
      );
      log(response.body);
      final json = jsonDecode(response.body);
      /*
      if (json['code'] == 403) {
        //user blocked
        Get.offAndToNamed(
          AppRoutes.authView,
          arguments: 'Your are blocked by admin.',
        );
        return '';
      } else if (json['code'] == 401) {
        //token expired
        Get.offAndToNamed(
          AppRoutes.authView,
          arguments: 'Session expired!!!\nPlease login again.',
        );
        return '';
      } else {
        return response.body;
      }
       */
      return response.body;
    } catch (e) {
      log('______ getMethode error ${e.toString()}');
      return '';
    }
  }

  Future<String> postMethod({
    required method,
    required var body,
    Map<String, String>? header,
  }) async {
    try {
      log('$baseAppUrl$method');
      if (header != null) {
        log(header.toString());
      }
      log(body.toString());
      //final response = await post(url, body, headers: header);
      final response = await http.post(
        Uri.parse('$baseAppUrl$method'),
        body: body,
        headers: withApiKey(header),
      );
      log("RES -------------> ${response.statusCode}");
      log("RES --------B-----> ${response.body}");
      AliceInterceptor.getAlice.onHttpResponse(response);
      if (response.statusCode != 200) {
        return jsonEncode({
          "success": false,
          "message": "Server error (${response.statusCode})",
          "status": response.statusCode,
          "data": null
        });
      }

      return response.body;
      final json = jsonDecode(response.body);
      log(response.body);
      /*if (json['code'].toString() == '403') {
        //user blocked
        Get.offAndToNamed(
          AppRoutes.authView,
          arguments: 'Your are blocked by admin.',
        );
        return '';
      } else if (json['code'].toString() == '401') {
        //token expired
        Get.offAndToNamed(
          AppRoutes.authView,
          arguments: 'Session expired!!!\nPlease login again.',
        );
        return '';
      } else {
        return response.body;
      }
      */

      return response.body;
    } catch (e) {
      log('______ post Method error ${e.toString()}');
      return '';
    }
  }

  Future<String> postMethodJson({
    required method,
    required var body,
    Map<String, String>? header,
  }) async {
    try {
      log('$baseAppUrl$method');
      if (header != null) {
        log(header.toString());
      }
      log(body.toString());
      //final response = await post(url, body, headers: header);
      final response = await http.post(
        Uri.parse('$baseAppUrl$method'),
        body: body,
        headers: withApiKey(header),
      );
      AliceInterceptor.getAlice.onHttpResponse(response);
      final json = jsonDecode(response.body);
      log(response.body);
      /*if (json['code'].toString() == '403') {
        //user blocked
        Get.offAndToNamed(
          AppRoutes.authView,
          arguments: 'Your are blocked by admin.',
        );
        return '';
      } else if (json['code'].toString() == '401') {
        //token expired
        Get.offAndToNamed(
          AppRoutes.authView,
          arguments: 'Session expired!!!\nPlease login again.',
        );
        return '';
      } else {
        return response.body;
      }
      */
      return response.body;
    } catch (e) {
      log('______ post Method error ${e.toString()}');
      return '';
    }
  }


  /*// Post request
  Future<String> postMethod(
      {required String method,
      required Map<String, String> body,
      Map<String, String>? header}) async {
    try {
      String url = '$baseAppUrl$method';
      log(url);
      if (header != null) {
        log(header.toString());
      }
      log(body.toString());
      final response = await post(url, body, headers: header);
      log(response.bodyString ?? '');
      if (response.body['code'].toString() == '401') {
        //token expired
        Get.offAndToNamed(
          AppRoutes.login,
          arguments: 'Session expired!!!\nPlease login again.',
        );
        return '';
      } else {
        return response.bodyString ?? '';
      }
    } catch (e) {
      log(e.toString());
      return '';
    }
  }*/

  /// Post request with File
  /// final form = FormData({
  ///   'file': MultipartFile(image, filename: 'avatar.png'),
  ///   'otherFile': MultipartFile(image, filename: 'cover.png'),
  /// });
  Future<String> postWithMultiPart({
    required method,
    required FormData formData,
    Map<String, String>? headers,
  }) async {
    try {
      String url = '$baseAppUrl$method';
      log(url);
      log(formData.files.toString());
      log(formData.fields.toString());
      if (headers?.isNotEmpty ?? false) {
        log(headers.toString());
      }
      final response = await post(
        url,
        formData,
        headers: withApiKey(headers),
      );
      log(response.bodyString.toString());
      if (response.body['code'].toString() == '401') {
        //token expired
        Get.offAndToNamed(
          AppRoutes.login,
          arguments: 'Session expired!!!\nPlease login again.',
        );
        return '';
      } else {
        return response.bodyString ?? '';
      }
    } catch (e) {
      log(e.toString());
      return '';
    }
  }

  Future<String> postMethodMultipart(http.MultipartRequest request) async {
    request.headers['X-Api-Key'] = apiKey;
    log(request.fields.toString());
    if (request.files.isNotEmpty) {
      for (var element in request.files) {
        log('___ file ${element.field.toString()} length = ${element.length}');
      }
    } else {
      log('___ file empty');
    }
    http.Response response =
    await http.Response.fromStream(await request.send());
    log(response.body.toString());
    final data = jsonDecode(response.body);
    if (data['code'].toString() == '401') {
      //token expired
      Get.offAndToNamed(
        AppRoutes.login,
        arguments: 'Session expired!!!\nPlease login acagain.',
      );
      return '';
    } else {
      return response.body;
    }
  }
}
