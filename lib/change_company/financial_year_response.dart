import 'dart:convert';

FinancialYearResponse financialYearResponseFromJson(String str) =>
    FinancialYearResponse.fromJson(json.decode(str));

class FinancialYearResponse {
  bool? success;
  List<FinancialYearData>? data;
  String? message;
  int? status;

  FinancialYearResponse({this.success, this.data, this.message, this.status});

  factory FinancialYearResponse.fromJson(Map<String, dynamic> json) =>
      FinancialYearResponse(
        success: json['success'],
        data: json['data'] == null
            ? []
            : List<FinancialYearData>.from(
                json['data'].map((x) => FinancialYearData.fromJson(x))),
        message: json['message'],
        status: json['status'],
      );
}

class FinancialYearData {
  int? fyid;
  String? financialyear;

  FinancialYearData({this.fyid, this.financialyear});

  factory FinancialYearData.fromJson(Map<String, dynamic> json) =>
      FinancialYearData(
        fyid: json['fyid'],
        financialyear: json['financialyear'],
      );
}
