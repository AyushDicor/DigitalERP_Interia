import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:newdigitalerp/services/api_service/api_client.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/utils/show_message.dart';

/// Opens the ERP-generated document (PDF) for a TransMaster record in the device
/// browser — the same "print" output as the web ERP. Works for any document type
/// (Performa Invoice, PO, Indent, MRN, GRN, …) via the generic
/// GET /api/document/print?id=&compid=&branchid= endpoint.
Future<void> openDocumentPrint(int id) async {
  try {
    final home = Get.find<HomeController>();
    final compid = home.currentUserData?.compId ?? 0;
    final branchid = home.currentUserData?.branchId ?? 0;
    if (id <= 0 || compid <= 0) {
      ShowMessage.showSnackBar('Print', 'This document is not available to print.');
      return;
    }
    final url =
        '${ApiClient.baseAppUrl}document/print?id=$id&compid=$compid&branchid=$branchid';
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok) {
      ShowMessage.showSnackBar('Print', 'Could not open the document.');
    }
  } catch (e) {
    ShowMessage.showSnackBar('Print', '$e');
  }
}

/// Reusable print icon button for a document list item or detail header.
/// Pass the document's TransMaster id.
class PrintDocButton extends StatelessWidget {
  final int id;
  final Color color;
  final double size;
  final String? tooltip;
  const PrintDocButton({
    Key? key,
    required this.id,
    this.color = const Color(0xFF5B6CF6),
    this.size = 20,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => openDocumentPrint(id),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(Icons.print_outlined, size: size, color: color),
      ),
    );
  }
}
