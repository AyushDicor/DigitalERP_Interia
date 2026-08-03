// Diagnostic: does the save response the API actually returns parse into a
// non-null TapCardModel? If `data` comes back null, _pushCard treats a
// successful save as a failure and the form never pops.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:newdigitalerp/tap_card/tap_card_models.dart';

void main() {
  // Captured verbatim from POST /api/tapcard/save against the running API.
  const createBody =
      '{"success":true,"data":{"id":3,"name":"Diag Test","phone":"9876543210",'
      '"email":null,"company":null,"title":null,"website":null,"imageUrl":null,'
      '"backImageUrl":null,"category":"Business",'
      '"createdAt":"2026-07-29T11:34:52.03"},"message":"Card saved.","status":200}';

  test('save response parses with non-null data', () {
    final res = TapCardSaveResponse.fromJson(
        jsonDecode(createBody) as Map<String, dynamic>);
    expect(res.status, 200);
    expect(res.data, isNotNull, reason: 'null data => treated as save failure');
    expect(res.data!.id, 3);
    expect(res.data!.name, 'Diag Test');
    expect(res.data!.createdAt, isNotNull);
  });

  test('server row replaces the optimistic local row', () {
    // Mirrors saveCard/_pushCard: an optimistic row is inserted under a local
    // key, then must be found and replaced by the server row.
    const typed = TapCardModel(name: 'Diag Test', phone: '9876543210');
    final optimistic =
        typed.copyWith(localId: 'local_123', pendingSync: true);
    expect(optimistic.key, 'local_123');

    final server = TapCardSaveResponse.fromJson(
            jsonDecode(createBody) as Map<String, dynamic>)
        .data!
        .copyWith(pendingSync: false);

    // pendingSync must actually clear, or the row shows "Not synced" forever.
    expect(server.pendingSync, isFalse);

    final all = <TapCardModel>[optimistic];
    final i = all.indexWhere((c) => c.key == optimistic.key);
    expect(i, 0, reason: 'optimistic row must be locatable by its key');
    all[i] = server;
    expect(all.single.id, 3);
  });

  test('edit sends the id and keeps the server key stable', () {
    const existing = TapCardModel(id: 2, name: 'Test');
    expect(existing.key, 'srv_2');

    final body = existing
        .copyWith(name: 'Test 2', title: 'App Tester')
        .toFormBody(compid: '2', branchid: '4', userid: '6');

    expect(body['id'], '2', reason: 'without id the API would insert, not update');
    expect(body['name'], 'Test 2');
    expect(body['title'], 'App Tester');
  });
}
