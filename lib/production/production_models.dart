// Models for the Production "Bulk Stage Entry" module.
//
// Three endpoints back this module (all POST, JSON body, X-Api-Key):
//   production/stages    -> list of stages for a company (which is "first")
//   production/batches   -> batches sitting at a chosen stage (+ the sub-stage
//                           the entry books against and the next stage it flows to)
//   production/saveentry -> bulk-save Produced + QC OK for the edited batches
//
// The batches response carries substage/tostage ids that saveentry must echo
// back verbatim, so we keep them on the controller between the two calls.

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

int _int(dynamic v) => _num(v).toInt();

bool _bool(dynamic v) {
  if (v is bool) return v;
  final s = (v ?? '').toString().toLowerCase();
  return s == 'true' || s == '1';
}

String _str(dynamic v) => (v ?? '').toString();

/// One stage chip on the picker (e.g. Heat-Treatment). [isfirst] gets the "1st"
/// badge — it is the entry point of the production line.
class ProductionStage {
  final int stageid;
  final String stagename;
  final bool isfirst;

  ProductionStage({
    required this.stageid,
    required this.stagename,
    required this.isfirst,
  });

  factory ProductionStage.fromJson(Map<String, dynamic> j) => ProductionStage(
        stageid: _int(j['stageid']),
        stagename: _str(j['stagename']),
        isfirst: _bool(j['isfirst']),
      );
}

class ProductionStagesResponse {
  final bool success;
  final int status;
  final String message;
  final List<ProductionStage> data;

  ProductionStagesResponse({
    required this.success,
    required this.status,
    required this.message,
    required this.data,
  });

  factory ProductionStagesResponse.fromJson(Map<String, dynamic> j) =>
      ProductionStagesResponse(
        success: _bool(j['success']),
        status: _int(j['status']),
        message: _str(j['message']),
        data: ((j['data'] as List?) ?? [])
            .map((e) => ProductionStage.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// One batch card. Quantities are doubles because the ERP tracks fractional
/// units for some items. [availableqty] is the balance shown as "Bal: N".
class ProductionBatchRow {
  final int challanid;
  final String batchno;
  final int orderrefid;
  final int itemid;
  final String itemname;
  final String unit;
  final double planqty;
  final double availableqty;
  final double producedsofar;
  final double qcsofar;

  ProductionBatchRow({
    required this.challanid,
    required this.batchno,
    required this.orderrefid,
    required this.itemid,
    required this.itemname,
    required this.unit,
    required this.planqty,
    required this.availableqty,
    required this.producedsofar,
    required this.qcsofar,
  });

  factory ProductionBatchRow.fromJson(Map<String, dynamic> j) =>
      ProductionBatchRow(
        challanid: _int(j['challanid']),
        batchno: _str(j['batchno']),
        orderrefid: _int(j['orderrefid']),
        itemid: _int(j['itemid']),
        itemname: _str(j['itemname']),
        unit: _str(j['unit']),
        planqty: _num(j['planqty']).toDouble(),
        availableqty: _num(j['availableqty']).toDouble(),
        producedsofar: _num(j['producedsofar']).toDouble(),
        qcsofar: _num(j['qcsofar']).toDouble(),
      );
}

/// Batches payload: the rows plus the sub-stage the entry books against and the
/// next stage batches flow to. saveentry must send substage*/tostage* back
/// unchanged, so this whole object is retained by the controller.
class ProductionBatchesData {
  final List<ProductionBatchRow> rows;
  final int substageid;
  final String substagename;
  final int tostageid;
  final String tostagename;
  final bool isfirst;

  ProductionBatchesData({
    required this.rows,
    required this.substageid,
    required this.substagename,
    required this.tostageid,
    required this.tostagename,
    required this.isfirst,
  });

  factory ProductionBatchesData.fromJson(Map<String, dynamic> j) =>
      ProductionBatchesData(
        rows: ((j['rows'] as List?) ?? [])
            .map((e) => ProductionBatchRow.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        substageid: _int(j['substageid']),
        substagename: _str(j['substagename']),
        tostageid: _int(j['tostageid']),
        tostagename: _str(j['tostagename']),
        isfirst: _bool(j['isfirst']),
      );
}

class ProductionBatchesResponse {
  final bool success;
  final int status;
  final String message;
  final ProductionBatchesData? data;

  ProductionBatchesResponse({
    required this.success,
    required this.status,
    required this.message,
    required this.data,
  });

  factory ProductionBatchesResponse.fromJson(Map<String, dynamic> j) =>
      ProductionBatchesResponse(
        success: _bool(j['success']),
        status: _int(j['status']),
        message: _str(j['message']),
        data: j['data'] is Map
            ? ProductionBatchesData.fromJson(
                Map<String, dynamic>.from(j['data'] as Map))
            : null,
      );
}

/// A per-batch rejection from saveentry (e.g. "QC qty exceeds the quantity
/// produced at this stage."). Shown back to the user against its batch.
class SaveEntryError {
  final String batchno;
  final String reason;

  SaveEntryError({required this.batchno, required this.reason});

  factory SaveEntryError.fromJson(Map<String, dynamic> j) => SaveEntryError(
        batchno: _str(j['batchno']),
        reason: _str(j['reason']),
      );
}

class SaveEntryResult {
  final bool success;
  final int status;
  final String message;
  final int saved;
  final int failed;
  final List<SaveEntryError> errors;

  SaveEntryResult({
    required this.success,
    required this.status,
    required this.message,
    required this.saved,
    required this.failed,
    required this.errors,
  });

  factory SaveEntryResult.fromJson(Map<String, dynamic> j) {
    final d = (j['data'] is Map)
        ? Map<String, dynamic>.from(j['data'] as Map)
        : <String, dynamic>{};
    return SaveEntryResult(
      success: _bool(j['success']),
      status: _int(j['status']),
      message: _str(j['message']),
      saved: _int(d['saved']),
      failed: _int(d['failed']),
      errors: ((d['errors'] as List?) ?? [])
          .map((e) =>
              SaveEntryError.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
