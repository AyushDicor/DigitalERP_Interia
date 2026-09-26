// Order Production Tracking — data access. All five endpoints are read-only.
//
// POST interia/track/{kpis|orders|items|detail} go through the shared JSON
// client. `export` is the odd one out: it answers with a raw CSV file rather
// than the usual envelope, so it uses http directly.

import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:newdigitalerp/services/api_service/api_client.dart';

import 'tracking_models.dart';

class TrackingRepo {
  static const _kpis = 'interia/track/kpis';
  static const _orders = 'interia/track/orders';
  static const _items = 'interia/track/items';
  static const _detail = 'interia/track/detail';
  static const _export = 'interia/track/export';

  /// Not a `track/*` endpoint — the operator app writes downtime and
  /// bottleneck events here and the supervisor screen reads the same rows.
  static const _stoppages = 'interia/stoppages';

  Future<Map<String, dynamic>> _post(
    String method,
    Map<String, dynamic> body,
  ) async {
    final raw = await ApiClient().postAppJson(method: method, body: body);
    if (raw.isEmpty) {
      return {'success': false, 'message': 'No response from server.'};
    }
    try {
      final j = jsonDecode(raw);
      return j is Map ? Map<String, dynamic>.from(j) : {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Bad response: $e'};
    }
  }

  TrackResult<List<T>> _list<T>(
    Map<String, dynamic> env,
    T Function(Map<String, dynamic>) f,
  ) => TrackResult(
    ok: env['success'] == true,
    message: (env['message'] ?? '').toString(),
    data: env['data'] is List
        ? (env['data'] as List)
              .whereType<Map>()
              .map((e) => f(Map<String, dynamic>.from(e)))
              .toList()
        : <T>[],
  );

  /// The five KPI cards. [branchid] 0 = all branches.
  Future<TrackResult<TrackKpis>> kpis(int compid, {int branchid = 0}) async {
    final env = await _post(_kpis, {'compid': compid, 'branchid': branchid});
    final d = env['data'];
    return TrackResult(
      ok: env['success'] == true,
      message: (env['message'] ?? '').toString(),
      data: d is Map ? TrackKpis.fromJson(Map<String, dynamic>.from(d)) : null,
    );
  }

  Future<TrackResult<List<TrackOrder>>> orders(
    int compid, {
    int branchid = 0,
  }) async => _list(
    await _post(_orders, {'compid': compid, 'branchid': branchid}),
    TrackOrder.fromJson,
  );

  Future<TrackResult<List<TrackItem>>> items(int compid, int orderid) async =>
      _list(
        await _post(_items, {'compid': compid, 'orderid': orderid}),
        TrackItem.fromJson,
      );

  /// Everything for one item. [stage] / [person] / [search] filter the trail
  /// only — the dropdown lists always come back unfiltered.
  Future<TrackResult<TrackDetail>> detail(
    int compid, {
    required int orderid,
    required int challanid,
    required int itemid,
    String stage = '',
    String person = '',
    String search = '',
  }) async {
    final env = await _post(_detail, {
      'compid': compid,
      'orderid': orderid,
      'challanid': challanid,
      'itemid': itemid,
      'stage': stage,
      'person': person,
      'search': search,
    });
    final d = env['data'];
    return TrackResult(
      ok: env['success'] == true,
      message: (env['message'] ?? '').toString(),
      data: d is Map
          ? TrackDetail.fromJson(Map<String, dynamic>.from(d))
          : null,
    );
  }

  /// Downtime + bottleneck events. [challanid] 0 = every order.
  Future<TrackResult<List<TrackStoppage>>> stoppages(
    int compid, {
    int challanid = 0,
  }) async => _list(
    await _post(_stoppages, {'compid': compid, 'challanid': challanid}),
    TrackStoppage.fromJson,
  );

  /// The trail as CSV, with the same filters. Returns the file's bytes, or
  /// null with the server's message when it refused.
  Future<({List<int>? bytes, String error})> exportCsv(
    int compid, {
    required int challanid,
    required int itemid,
    String stage = '',
    String person = '',
    String search = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiClient.baseAppUrl}$_export'),
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': ApiClient.apiKey,
        },
        body: jsonEncode({
          'compid': compid,
          'challanid': challanid,
          'itemid': itemid,
          'stage': stage,
          'person': person,
          'search': search,
        }),
      );
      if (res.statusCode != 200) {
        return (bytes: null, error: 'Server error (${res.statusCode})');
      }
      // Errors still come back as the JSON envelope, not a file.
      final type = res.headers['content-type'] ?? '';
      if (type.contains('json')) {
        try {
          final j = jsonDecode(utf8.decode(res.bodyBytes));
          return (
            bytes: null,
            error:
                (j is Map ? j['message'] : null)?.toString() ??
                'Export failed.',
          );
        } catch (_) {
          return (bytes: null, error: 'Export failed.');
        }
      }
      return (bytes: res.bodyBytes, error: '');
    } catch (e) {
      log('track/export error $e');
      return (bytes: null, error: '$e');
    }
  }
}
