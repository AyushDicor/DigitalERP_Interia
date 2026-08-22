import 'package:flutter_test/flutter_test.dart';
import 'package:newdigitalerp/repo/mis_repo.dart';

/// The live "Daily Orders" graph comes back ordered by VALUE, not by date —
/// PointOrder 1 is "25 Jul", PointOrder 11 is "20 Jul". The chart must still
/// draw left-to-right in date order.
void main() {
  List<Map<String, dynamic>> pts(List<(String, double, int)> raw,
          {String dimFormat = 'dayMonth'}) =>
      raw
          .map((e) => {
                'GraphOrdinal': 3,
                'Title': 'Daily Orders',
                'Type': 'line',
                'DimFormat': dimFormat,
                'SortOrder': 3,
                'Label': e.$1,
                'Value': e.$2,
                'PointOrder': e.$3,
              })
          .toList();

  test('dayMonth points are ordered by date, not by the server PointOrder', () {
    final graphs = MisGraph.groupPoints(
      pts([
        ('25 Jul', 2, 1),
        ('30 Jul', 2, 2),
        ('07 Aug', 4, 6),
        ('20 Jul', 5, 11),
        ('17 Aug', 10, 21),
      ]),
      rangeStart: DateTime(2026, 7, 20),
      rangeEnd: DateTime(2026, 8, 19),
    );

    expect(graphs.single.points.map((p) => p.label).toList(),
        ['20 Jul', '25 Jul', '30 Jul', '07 Aug', '17 Aug']);
  });

  test('a range crossing new year resolves the right year per label', () {
    final graphs = MisGraph.groupPoints(
      pts([
        ('05 Jan', 1, 1),
        ('28 Dec', 2, 2),
        ('31 Dec', 3, 3),
      ]),
      rangeStart: DateTime(2025, 12, 20),
      rangeEnd: DateTime(2026, 1, 19),
    );

    expect(graphs.single.points.map((p) => p.label).toList(),
        ['28 Dec', '31 Dec', '05 Jan']);
  });

  test('monthYear points sort chronologically', () {
    final graphs = MisGraph.groupPoints(
      pts([
        ('Jan 26', 1, 1),
        ('Aug 25', 2, 2),
        ('Dec 25', 3, 3),
      ], dimFormat: 'monthYear'),
    );

    expect(graphs.single.points.map((p) => p.label).toList(),
        ['Aug 25', 'Dec 25', 'Jan 26']);
  });

  test('raw dimensions keep the server ranking untouched', () {
    final graphs = MisGraph.groupPoints(
      pts([
        ('LEEFORD', 2550000, 1),
        ('PHARMA CARE', 1574400, 3),
        ('GWS', 1445400, 2),
      ], dimFormat: 'raw'),
    );

    expect(graphs.single.points.map((p) => p.label).toList(),
        ['LEEFORD', 'GWS', 'PHARMA CARE']);
  });

  test('unparseable labels keep their original order', () {
    final graphs = MisGraph.groupPoints(
      pts([('Week 1', 1, 1), ('Week 2', 2, 2)]),
      rangeStart: DateTime(2026, 7, 20),
      rangeEnd: DateTime(2026, 8, 19),
    );

    expect(graphs.single.points.map((p) => p.label).toList(),
        ['Week 1', 'Week 2']);
  });
}
