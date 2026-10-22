import 'package:flutter_test/flutter_test.dart';
import 'package:newdigitalerp/production_operator/operator_models.dart';

/// Fit check (INTERIA, backend spec 14 Oct 2026).
///
/// A stage can be planned "fit together to check, then separate": its parts
/// are fitted ONLY to prove they fit, the QC department checks the fit, then
/// the set comes apart and every part travels on to its own next stage.
///
/// The fit check arrives inside `subitems` like any other row, so the risk
/// worth testing is that it is mistaken for a part: counted as incoming
/// work, given a Send button, or read as the final assembly.
void main() {
  /// The server's shape for the worked example in the spec: fit check
  /// "Raw Side Table" at CARPENTRY ASSEMBLY over three parts, each of which
  /// leaves for a different stage once the fit passes.
  Map<String, dynamic> job({
    required List<Map<String, dynamic>> subitems,
  }) => {
    'challanid': 812368,
    'stagename': 'CARPENTRY ASSEMBLY',
    'partmode': 1,
    'subitems': subitems,
  };

  Map<String, dynamic> fitRow({
    double need = 1,
    double made = 0,
    double qc = 0,
    double reject = 0,
    double canproduce = 1,
    double canqc = 0,
    double fitable = 1,
    String status = 'To fit',
  }) => {
    'kind': 'fit',
    'isfit': true,
    'partid': 9001,
    'partname': 'Raw Side Table',
    'qtyperpiece': 1,
    'needqty': need,
    'madeqty': made,
    'qcqty': qc,
    'rejectqty': reject,
    'canproduceqty': canproduce,
    'canqcqty': canqc,
    'canissueqty': 0,
    'fitableqty': fitable,
    'nextstageid': 0,
    'nextstage': '',
    'isfinal': false,
    'status': status,
  };

  Map<String, dynamic> partRow({
    required int partid,
    required String name,
    required String kind,
    required String nextstage,
    int fitid = 9001,
    double canproduce = 0,
    double canqc = 0,
    double canissue = 0,
    double fitted = 0,
    String status = 'To fit',
  }) => {
    'kind': kind,
    'partid': partid,
    'partname': name,
    'qtyperpiece': 1,
    'needqty': 1,
    'fromstage': kind == 'in' ? 'CARPENTRY' : '',
    'nextstage': nextstage,
    'nextstageid': 7000 + partid,
    'canproduceqty': canproduce,
    'canqcqty': canqc,
    'canissueqty': canissue,
    'fitid': fitid,
    'fitname': 'Raw Side Table',
    'fittedqty': fitted,
    'status': status,
  };

  test('the fit check is read as a fit, not as a part', () {
    final j = OperatorJob.fromJson(
      job(
        subitems: [
          fitRow(),
          partRow(partid: 11, name: 'Carpentry', kind: 'in', nextstage: 'Polish'),
          partRow(
            partid: 12,
            name: 'Metal Item',
            kind: 'in',
            nextstage: 'Metal Paint',
          ),
          partRow(
            partid: 13,
            name: 'Stone Component',
            kind: 'in',
            nextstage: 'Stone Polish',
          ),
        ],
      ),
    );

    expect(j.hasFitCheck, isTrue);
    expect(j.fitCheck!.partname, 'Raw Side Table');
    expect(j.fitCheck!.isfit, isTrue);
    expect(j.fitCheck!.fitableqty, 1);

    // The fit row must NOT be listed as work arriving at the stage: it is
    // `kind: "fit"`, which is neither "made" nor "in".
    expect(j.comesIn.length, 3);
    expect(j.comesIn.any((p) => p.isfit), isFalse);
    expect(j.madeHere, isEmpty);

    // Its three parts, each bound for its own stage.
    final inFit = j.partsInFit(j.fitCheck!);
    expect(inFit.map((p) => p.partname).toList(), [
      'Carpentry',
      'Metal Item',
      'Stone Component',
    ]);
    expect(inFit.map((p) => p.nextstage).toList(), [
      'Polish',
      'Metal Paint',
      'Stone Polish',
    ]);
    expect(inFit.every((p) => p.isInFit), isTrue);

    // The fit check carries no next stage by design; that must not read as
    // "every part stops here", which is how a final assembly is detected.
    expect(j.buildsFinishedItem, isFalse);
  });

  test('a fit check is never sent; its parts are, after QC', () {
    final before = OperatorJob.fromJson(
      job(
        subitems: [
          fitRow(made: 1, canproduce: 0, canqc: 1, status: 'Awaiting QC'),
          partRow(
            partid: 11,
            name: 'Carpentry',
            kind: 'in',
            nextstage: 'Polish',
            fitted: 1,
            status: 'In the fit: awaiting QC',
          ),
        ],
      ),
    );
    // Waiting for the QC department: nothing to send yet, and the fit check
    // itself can never be sent.
    expect(before.fitCheck!.canIssue, isFalse);
    expect(before.comesIn.single.canIssue, isFalse);
    expect(before.comesIn.single.fittedqty, 1);

    final after = OperatorJob.fromJson(
      job(
        subitems: [
          fitRow(made: 1, qc: 1, canproduce: 0, status: 'Fit checked'),
          partRow(
            partid: 11,
            name: 'Carpentry',
            kind: 'in',
            nextstage: 'Polish',
            fitted: 1,
            canissue: 1,
            status: 'Ready to send',
          ),
        ],
      ),
    );
    expect(after.fitCheck!.canIssue, isFalse, reason: 'canissueqty is always 0');
    expect(after.comesIn.single.canIssue, isTrue);
    expect(after.comesIn.single.nextstageid, 7011);
  });

  test('a part made at the fit stage keeps Produce but not QC', () {
    final j = OperatorJob.fromJson(
      job(
        subitems: [
          fitRow(canproduce: 0, status: 'Waiting for parts'),
          // Made here, inside the fit: produced one by one, QC'd only
          // through the fit check.
          partRow(
            partid: 21,
            name: 'Carpentry',
            kind: 'made',
            nextstage: 'Polish',
            canproduce: 2,
          ),
        ],
      ),
    );
    final part = j.madeHere.single;
    expect(part.canProduce, isTrue);
    expect(part.canQc, isFalse);
    expect(part.isInFit, isTrue);
    expect(part.fitname, 'Raw Side Table');
    expect(j.comesIn, isEmpty);
  });

  test('a job with no fit check behaves exactly as before', () {
    final j = OperatorJob.fromJson(
      job(
        subitems: [
          {
            'kind': 'in',
            'partid': 31,
            'partname': 'Sofa frame',
            'qtyperpiece': 1,
            'needqty': 1,
            'nextstage': 'ASSEMBLY',
            'nextstageid': 5270,
            'canissueqty': 1,
            'status': 'Ready to send',
          },
        ],
      ),
    );
    expect(j.hasFitCheck, isFalse);
    expect(j.fitCheck, isNull);
    expect(j.comesIn.single.isInFit, isFalse);
    expect(j.comesIn.single.fitid, 0);
    expect(j.comesIn.single.canIssue, isTrue);
  });

  test('the pre-release server sends the new fields empty', () {
    // Until the database script and the API publish land, every new field
    // comes as false / 0 / "" — the app must read that as "no fit check".
    final j = OperatorJob.fromJson(
      job(
        subitems: [
          {
            'kind': 'in',
            'partid': 41,
            'partname': 'Carpentry',
            'needqty': 1,
            'nextstage': 'Polish',
            'isfit': false,
            'fitid': 0,
            'fitname': '',
            'fittedqty': 0,
            'fitableqty': 0,
          },
        ],
      ),
    );
    expect(j.hasFitCheck, isFalse);
    expect(j.comesIn.single.isInFit, isFalse);
  });

  test('jobparts carries the stage fit check, or null', () {
    final withFit = StageParts.fromJson({
      'stageid': 5281,
      'stagename': 'CARPENTRY ASSEMBLY',
      'text': 'Make: … · Fit check: Raw Side Table, then separately',
      'made': const [],
      'comesin': const [],
      'fitcheck': fitRow(),
    });
    expect(withFit.fitcheck, isNotNull);
    expect(withFit.fitcheck!.partname, 'Raw Side Table');
    expect(withFit.fitcheck!.isfit, isTrue);

    final without = StageParts.fromJson({
      'stageid': 5270,
      'stagename': 'ASSEMBLY',
      'fitcheck': null,
    });
    expect(without.fitcheck, isNull);
  });
}
