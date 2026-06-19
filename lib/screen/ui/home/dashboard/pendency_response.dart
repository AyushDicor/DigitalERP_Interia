import 'dart:convert';

PendencyResponse pendencyResponseFromJson(String str) =>
    PendencyResponse.fromJson(json.decode(str));

class PendencyResponse {
  bool? success;
  PendencyData? data;
  String? message;
  int? status;

  PendencyResponse({this.success, this.data, this.message, this.status});

  factory PendencyResponse.fromJson(Map<String, dynamic> json) =>
      PendencyResponse(
        success: json['success'],
        data: json['data'] == null ? null : PendencyData.fromJson(json['data']),
        message: json['message'],
        status: json['status'],
      );
}

class PendencyData {
  int pendingApprovals;
  int pendingSaleOrders;
  int pendingPO;
  int pendingMRN;
  int pendingTasks;
  int customers;

  PendencyData({
    this.pendingApprovals = 0,
    this.pendingSaleOrders = 0,
    this.pendingPO = 0,
    this.pendingMRN = 0,
    this.pendingTasks = 0,
    this.customers = 0,
  });

  factory PendencyData.fromJson(Map<String, dynamic> json) => PendencyData(
        pendingApprovals: (json['pendingApprovals'] as num?)?.toInt() ?? 0,
        pendingSaleOrders: (json['pendingSaleOrders'] as num?)?.toInt() ?? 0,
        pendingPO: (json['pendingPO'] as num?)?.toInt() ?? 0,
        pendingMRN: (json['pendingMRN'] as num?)?.toInt() ?? 0,
        pendingTasks: (json['pendingTasks'] as num?)?.toInt() ?? 0,
        customers: (json['customers'] as num?)?.toInt() ?? 0,
      );
}
