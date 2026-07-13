import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../indent_controller/indent_controller.dart';
import 'package:newdigitalerp/screen/ui/home/indent/indent_response/indent_model.dart';
import '../indent_widgets.dart';

class IndentReviewScreen extends StatelessWidget {
  const IndentReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<IndentController>(
        id: 'indentReview',
        builder: (ctrl) {
          return Scaffold(
            backgroundColor: indSurfaceColor,
            body: Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                  child: Column(children: [
                    // ── Summary banner ────────────────────────────────────────
                    _summaryBanner(ctrl),
                    const SizedBox(height: 12),

                    // ── Header summary card ───────────────────────────────────
                    IndentCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const IndentSectionHead('Indent Header'),
                            _reviewRow('Indent No.', ctrl.indentNumber),
                            _reviewRow('Indent Date', ctrl.indentDateCtrl.text),
                            _reviewRow('Request By',
                                ctrl.selectedApprover?.label ?? ctrl.requestByCtrl.text),
                            if (ctrl.selectedDepartment != null)
                              _reviewRow(
                                  'Department', ctrl.selectedDepartment!.label),
                            if (ctrl.selectedGodown != null)
                              _reviewRow(
                                  'Request To (Godown)', ctrl.selectedGodown!.label),
                            _reviewRowWidget(
                              'Priority',
                              PriorityBadge(ctrl.selectedPriority),
                            ),
                            if (ctrl.siteInchargeCtrl.text.isNotEmpty)
                              _reviewRow(
                                  'Site Incharge', ctrl.siteInchargeCtrl.text),
                            if (ctrl.remarksCtrl.text.isNotEmpty)
                              _reviewRow('Remarks', ctrl.remarksCtrl.text),
                          ]),
                    ),

                    // ── Items card ────────────────────────────────────────────
                    IndentCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Expanded(
                                child: IndentSectionHead('Items'),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: indBlueLightColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${ctrl.itemLines.length} item(s)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: indBlueColor)),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            // Table header
                            _tableHeader(),
                            const SizedBox(height: 4),
                            ...ctrl.itemLines
                                .asMap()
                                .entries
                                .map((e) => _itemRow(e.key + 1, e.value)),
                            const Divider(height: 16, color: indBorderColor),
                            // Totals
                            _totalRow(
                                'Total Qty', ctrl.totalQty.toStringAsFixed(0)),
                            if (ctrl.totalAmount > 0)
                              _totalRow(
                                  'Total Amount', '₹${_inr(ctrl.totalAmount)}'),
                          ]),
                    ),

                    // ── Final remarks ─────────────────────────────────────────
                    IndentCard(
                      child: Column(children: [
                        const IndentSectionHead('Final Remarks'),
                        IndentField(
                          label: 'Additional Remarks (optional)',
                          controller: ctrl.reviewRemarksCtrl,
                          hint: 'Any final notes before submission…',
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ]),
                    ),

                    // ── Attachments (nested builder so update() refreshes it) ──
                    _attachmentsCard(),
                  ]),
                ),
              ),

              // ── Bottom actions ────────────────────────────────────────────
              _bottomActions(ctrl),
            ]),
          );
        });
  }

  // ── Attachments (S3): add on create, view on edit ──
  Widget _attachmentsCard() {
    return GetBuilder<IndentController>(builder: (ctrl) {
      return IndentCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const IndentSectionHead('Attachments'),
          const SizedBox(height: 10),
          ...List.generate(ctrl.attachmentNames.length, (i) {
            final hasPreview = i < ctrl.attachmentPreviews.length &&
                ctrl.attachmentPreviews[i].isNotEmpty;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: indSurfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: indBorderColor),
              ),
              child: Row(children: [
                const Icon(Icons.insert_drive_file_outlined,
                    size: 18, color: indBlueColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ctrl.attachmentNames[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: indTextPrimary)),
                ),
                if (hasPreview)
                  InkWell(
                    onTap: () => _openUrl(ctrl.attachmentPreviews[i]),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.open_in_new,
                          size: 16, color: indTextSecondary),
                    ),
                  ),
                InkWell(
                  onTap: () => ctrl.removeAttachmentAt(i),
                  child:
                      const Icon(Icons.close, size: 18, color: Colors.redAccent),
                ),
              ]),
            );
          }),
          if (ctrl.uploadingAttachment)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: indBlueColor)),
                SizedBox(width: 10),
                Text('Uploading…',
                    style: TextStyle(fontSize: 12, color: indTextSecondary)),
              ]),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: ctrl.uploadingAttachment
                  ? null
                  : () => ctrl.pickAndUploadAttachment(),
              icon: const Icon(Icons.attach_file, size: 18, color: indBlueColor),
              label: const Text('Add Attachment',
                  style: TextStyle(
                      color: indBlueColor, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: indBlueColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ]),
      );
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _summaryBanner(IndentController ctrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            indBlueColor,
            indBlueColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.assignment_turned_in_outlined,
            color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ready to Submit',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              '${ctrl.itemLines.length} item(s) · ${ctrl.selectedGodown?.label ?? "—"}',
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ]),
        ),
        PriorityBadge(ctrl.selectedPriority),
      ]),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: indBlueLightColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indBlueColor.withValues(alpha: 0.25)),
      ),
      child: const Row(children: [
        SizedBox(
            width: 24,
            child: Text('#',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: indBlueColor))),
        SizedBox(width: 6),
        Expanded(
            child: Text('Item',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: indBlueColor))),
        SizedBox(
            width: 50,
            child: Text('Unit',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: indBlueColor))),
        SizedBox(
            width: 44,
            child: Text('Qty',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: indBlueColor))),
        SizedBox(
            width: 64,
            child: Text('Amount',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: indBlueColor))),
      ]),
    );
  }

  Widget _itemRow(int idx, IndentItemLine item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: indBorderColor),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          width: 24,
          child: Text('$idx',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: indTextSecondary)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.itemName,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: indTextPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (item.itemDescription.isNotEmpty)
              Text(item.itemDescription,
                  style: const TextStyle(fontSize: 10, color: indTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        SizedBox(
          width: 50,
          child: Text(item.unit,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: indTextSecondary)),
        ),
        SizedBox(
          width: 44,
          child: Text(item.indentQty.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: indTextPrimary)),
        ),
        SizedBox(
          width: 64,
          child: Text(item.amount > 0 ? '₹${_inr(item.amount)}' : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: indGreenColor)),
        ),
      ]),
    );
  }

  Widget _totalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: indTextSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: indTextPrimary)),
      ]),
    );
  }

  Widget _reviewRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: indTextSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: indTextPrimary)),
        ),
      ]),
    );
  }

  Widget _reviewRowWidget(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: indTextSecondary)),
        ),
        child,
      ]),
    );
  }

  Widget _bottomActions(IndentController ctrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: indBorderColor))),
      child: SafeArea(
        top: false,
        child: Column(children: [
          // Edit button
          GestureDetector(
            onTap: ctrl.prevStep,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: indSurfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: indBorderColor),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      size: 15, color: indTextSecondary),
                  SizedBox(width: 6),
                  Text('Back to Edit',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: indTextSecondary)),
                ],
              ),
            ),
          ),
          // Submit button
          ctrl.isSubmitting
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: indBlueColor,
                      borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IndentPrimaryBtn(
                  label: ctrl.isEditMode ? 'Update Indent' : 'Submit Indent',
                  icon: Icons.check_circle_outline_rounded,
                  onTap: ctrl.submitIndent,
                  color: indGreenColor,
                ),
        ]),
      ),
    );
  }

  static String _inr(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)} L';
    final parts = v.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    if (whole.length <= 3) return '$whole.$decimal';
    final last3 = whole.substring(whole.length - 3);
    final rest = whole.substring(0, whole.length - 3);
    final buf = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    return '$buf,$last3.$decimal';
  }
}
