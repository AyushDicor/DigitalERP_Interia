
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/indian_number.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../../../utils/show_message.dart';
import '../approval_hub_controller/approval_hub_controller.dart';
import 'approval_hub_action.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ApprovalHubDetail extends StatefulWidget {
  const ApprovalHubDetail({super.key});

  @override
  State<ApprovalHubDetail> createState() => _ApprovalHubDetailState();
}

class _ApprovalHubDetailState extends State<ApprovalHubDetail> {
  @override
  void initState() {
    super.initState();
    // Wait for navigation to complete, then load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ApprovalHubController>().loadDetailData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ApprovalHubController>(
      builder: (ctrl) {
        final item = ctrl.currentItem;
        if (item == null)
          return const Scaffold(body: Center(child: Text('No item selected')));
        final color = ctrl.catColor(item.documentname);
        return PopScope(
          canPop: true, // temporarily block ALL back presses to test
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F8FC),
            body: SafeArea(
                bottom: false,
                child: Column(children: [
                  _AppBar(ctrl: ctrl, docNo: item.documentno ?? ''),
                  Expanded(
                    child: SingleChildScrollView(
                      // ✅ always scrollable, no outer gate
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                      child: Column(children: [
                        if (!ctrl.isLoadingDetail) ...[
                          // these only show after load
                          _DocumentInfoCard(ctrl: ctrl),
                          _PartyCard(ctrl: ctrl),
                        ],
                        _MasterCard(
                            // handles its own loading state
                            ctrl: ctrl,
                            color: color),
                        if (!ctrl.isLoadingDetail) ...[
                          _ItemsCard(ctrl: ctrl),
                          _DocPreview(ctrl: ctrl),
                          _ChainCard(ctrl: ctrl),
                          _RelatedCard(ctrl: ctrl),
                        ],
                      ]),
                    ),
                  ),
                  _BottomBar(
                    ctrl: ctrl,
                  ),
                ])),
          ),
        );
      },
    );
  }
}

//  App bar
class _AppBar extends StatelessWidget {
  final ApprovalHubController ctrl;
  final String docNo;
  const _AppBar({required this.ctrl, required this.docNo});
  @override
  Widget build(BuildContext context) {
    final header = ctrl.detailHeader;
    final item = ctrl.currentItem;

    // Web ERP shows the party as the page title, falling back to the doc type.
    final party = (header?.partyName ?? '').trim();
    final docType = header?.approvalType ?? item?.documentname ?? '';
    final title = party.isNotEmpty ? party : '$docType Approval';
    final date = header?.documentDate ?? item?.documentDate ?? '';
    final status = header?.status ?? item?.status ?? 'Pending';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(children: [
        Row(children: [
          GestureDetector(
              onTap: ctrl.isLoadingDetail // ← disable while loading
                  ? null
                  : () => Get.back(),
              child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: newTextPrimary))),
          Expanded(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary))),
          const SizedBox(width: 8),
          _printButton(context),
        ]),

        // Doc No  •  Date  •  Status — same meta line as the web page.
        Padding(
          padding: const EdgeInsets.only(left: 46, right: 6, top: 4),
          child: Row(children: [
            Expanded(
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Meta(Icons.description_outlined, 'Doc No: ', docNo),
                  if (date.isNotEmpty)
                    _Meta(Icons.calendar_month_outlined, '', date),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ctrl.statusBadgeBg(status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ctrl.statusBadgeFg(status))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _printButton(BuildContext context) {
    final pdf = ctrl.detailHeader?.pdfUrl?.trim() ?? '';
    if (pdf.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
              onTap: () async {
                final pdf = ctrl.detailHeader?.pdfUrl?.trim() ?? '';
                if (pdf.isEmpty) return;

                // Show downloading indicator
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(
                //     content: Row(children: [
                //       SizedBox(
                //         width: 16, height: 16,
                //         child: CircularProgressIndicator(
                //             strokeWidth: 2, color: Colors.white),
                //       ),
                //       SizedBox(width: 12),
                //       Text('Downloading...'),
                //     ]),
                //     duration: Duration(seconds: 60),
                //     backgroundColor: Colors.black87,
                //   ),
                // );

                try {
                  // Get save directory
                  Directory? dir;
                  if (Platform.isAndroid) {
                    // Request permission first
                    if (await Permission.storage.isDenied) {
                      await Permission.storage.request();
                    }
                    // For Android 11+ use MANAGE_EXTERNAL_STORAGE
                    if (await Permission.manageExternalStorage.isDenied) {
                      await Permission.manageExternalStorage.request();
                    }

                    // Use app's external storage — no permission needed on any Android version
                    dir = await getExternalStorageDirectory(); // → /sdcard/Android/data/your.app/files

                    // Try to use Downloads folder if permission granted
                    final downloadsDir = Directory('/storage/emulated/0/Download');
                    if (await Permission.storage.isGranted ||
                        await Permission.manageExternalStorage.isGranted) {
                      if (await downloadsDir.exists()) {
                        dir = downloadsDir;
                      }
                    }
                  } else {
                    dir = await getApplicationDocumentsDirectory();
                  }

                  if (dir == null) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not access storage')),
                    );
                    return;
                  }

                  // Build filename from URL
                  String fileName = pdf.split('/').last.split('?').first;
                  if (!fileName.toLowerCase().endsWith('.pdf')) {
                    fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
                  }
                  final savePath = '${dir.path}/$fileName';

                  // Download
                  await Dio().download(
                    pdf,
                    savePath,
                    options: Options(
                      headers: {
                        'Accept': 'application/pdf,*/*',
                        'Content-Type': 'application/pdf',
                      },
                      responseType: ResponseType.bytes,
                    ),
                  );

                  // Dismiss progress snackbar
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

// Open the URL after download
                  await OpenFilex.open(savePath);

// Show success snackbar
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Downloaded: $fileName'),
//                       backgroundColor: Colors.green.shade700,
//                       duration: const Duration(seconds: 3),
//                     ),
//                   );

                  // Auto open
                 // await OpenFilex.open(savePath);

                } catch (e) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Download failed: $e'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: newBorderColor),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.print_rounded, size: 16, color: newTextPrimary),
                  SizedBox(width: 6),
                  Text('Print',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: newTextPrimary)),
                ]),
              ),
            );
  }
}

/// Small "icon + label + value" chip used on the header meta line.
class _Meta extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Meta(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: newBlueColor),
        const SizedBox(width: 5),
        if (label.isNotEmpty)
          Text(label,
              style: const TextStyle(fontSize: 11, color: newTextSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: newTextPrimary)),
      ]);
}

//  Master detail card
class _MasterCard extends StatelessWidget {
  final ApprovalHubController ctrl;
  final Color color;

  const _MasterCard({
    required this.ctrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ApprovalHubController>(
      builder: (ctrl) {
        final item = ctrl.currentItem;
        final header = ctrl.detailHeader;

        //  Build tiles dynamically
        // AFTER
        final docNo = header?.documentNo ?? item?.documentno ?? '';
        final date = header?.documentDate ?? item?.documentDate ?? '';
        final requestedBy = header?.requestedBy ?? item?.requestedBy ?? '';
        final amount = header?.amount ?? 0;
        final site = header?.siteName ?? item?.siteName ?? '';
        final dueDate = header?.dueDate ?? '';
        final subType = header?.subType ?? item?.subType ?? '';
        final priority = header?.priority ?? '';
        final remarks = header?.remarks ?? item?.remarks ?? '';

        final docType =
            (header?.approvalType ?? item?.documentname ?? '').toLowerCase();
        final isPaymentRequest = docType.contains('payment');
        final isWorkOrder =
            docType.contains('work order') || docType.contains('workorder');
        final isPurchaseOrder = docType.contains('purchase');
        final isEstimate = docType.contains('estimate');

        final requestType = (header?.requestType?.isNotEmpty == true)
            ? header!.requestType!
            : (isPaymentRequest ? subType : '');
        final jobType = header?.jobType ?? '';

        if (ctrl.isLoadingDetail) {
          return _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SecHead('Approval Details', icon: Icons.verified_outlined),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: newBlueColor)),
                      SizedBox(width: 10),
                      Text('Loading details...',
                          style:
                              TextStyle(fontSize: 12, color: newTextSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecHead('Approval Details', icon: Icons.verified_outlined),
              _FieldGrid([
                _IT('Amount', amount > 0 ? '₹${inrNum(amount)}' : '', vc: color),
                _IT('Document No', docNo),
                _IT('Date', date),
                _IT('Requested By', requestedBy),
                _IT('Status', header?.status ?? item?.status ?? ''),
                if (!isPaymentRequest) _IT('Sub Type', subType),
                if (isPaymentRequest) _IT('Request Type', requestType),
                if ((isWorkOrder || isPurchaseOrder || isEstimate) &&
                    jobType.isNotEmpty)
                  _IT('Job Type', jobType),
                if (dueDate.isNotEmpty)
                  _IT('Due By', dueDate, vc: newRedColor),
                if (site.isNotEmpty) _IT('Site', site),
                if (priority.isNotEmpty) _IT('Priority', priority),
              ]),
              _FullRow(_IT('Remarks', remarks, maxLines: 4)),
            ],
          ),
        );
      },
    );
  }
}

class _PairedRow extends StatelessWidget {
  final _IT? left;
  final _IT? right;
  const _PairedRow({this.left, this.right});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (left != null) Expanded(child: _InfoTile(left!)),
            if (left != null && right != null) const SizedBox(width: 14),
            if (right != null)
              Expanded(child: _InfoTile(right!))
            else if (left != null)
              const Expanded(child: SizedBox()), // fill empty space
          ],
        ),
      );
}

class _FullRow extends StatelessWidget {
  final _IT tile;
  const _FullRow(this.tile);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _InfoTile(tile),
      );
}

/// Label-over-value grid, two fields per row — mirrors the web ERP's detail
/// sections. Empty values render as "-" (same as the web page) rather than
/// disappearing, so the field positions stay stable.
class _FieldGrid extends StatelessWidget {
  final List<_IT> tiles;
  const _FieldGrid(this.tiles);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(_PairedRow(
        left: tiles[i],
        right: i + 1 < tiles.length ? tiles[i + 1] : null,
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

/// Document header details sent by the backend (branch, series, dates, terms).
class _DocumentInfoCard extends StatelessWidget {
  final ApprovalHubController ctrl;
  const _DocumentInfoCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final h = ctrl.detailHeader;
    if (h == null) return const SizedBox.shrink();

    // Same field set and order as the web ERP's "Document Details" block.
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SecHead('Document Details', icon: Icons.info_outline_rounded),
        _FieldGrid([
          _IT('Document Name', h.documentName ?? h.approvalType ?? ''),
          _IT('Branch', h.branchName ?? ''),
          _IT('Entry Type', h.entryType ?? ''),
          _IT('Series Type', h.seriesType ?? ''),
          _IT('Document No', h.documentNo ?? ''),
          _IT('Date', h.documentDate ?? ''),
          _IT('Receipt Date', h.receiptDate ?? ''),
          _IT('Delivery Date', h.deliveryDate ?? '', vc: newGreenColor),
          _IT('Customer Order No', h.customerOrderNo ?? ''),
          _IT('Delivery Type', h.deliveryType ?? ''),
          _IT('Transport', h.transport ?? ''),
          _IT('Payment Terms', h.paymentTerms ?? ''),
        ]),
        _FullRow(_IT('Remark', h.headerRemark ?? '', maxLines: 4)),
      ]),
    );
  }
}

/// Party / customer block — GST, contact and the bill-to / ship-to addresses.
class _PartyCard extends StatelessWidget {
  final ApprovalHubController ctrl;
  const _PartyCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final h = ctrl.detailHeader;
    if (h == null) return const SizedBox.shrink();

    final billTo = h.billToAddress ?? '';
    final shipTo = h.shipToAddress ?? '';

    // Same field set and order as the web ERP's "Party Details" block.
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SecHead('Party Details', icon: Icons.person_outline_rounded),
        _FieldGrid([
          _IT('Party Name', h.partyName ?? ''),
          _IT('GST No', h.gstNo ?? ''),
          _IT('Mobile No', h.mobileNo ?? ''),
          _IT('Contact Person', h.contactPerson ?? ''),
        ]),
        _PairedRow(
          left: _IT('Bill To Address', billTo, maxLines: 6),
          right: _IT('Ship To Address', shipTo, maxLines: 6),
        ),
      ]),
    );
  }
}

class _DocPreview extends StatelessWidget {
  final ApprovalHubController ctrl;
  const _DocPreview({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final files = <_DocFile>[];
    void add(_DocFile f) {
      if (f.url.isEmpty) return;
      if (files.any((e) => e.url == f.url)) return;
      files.add(f);
    }

    // The printed ERP document itself (pdfurl) — always first when available.
    final printUrl = ctrl.detailHeader?.pdfUrl?.trim() ?? '';
    final docNo = ctrl.detailHeader?.documentNo ?? ctrl.currentItem?.documentno ?? '';
    if (printUrl.isNotEmpty) {
      add(_DocFile(
        docNo.isNotEmpty ? '$docNo.pdf' : 'Document.pdf',
        printUrl,
        label: 'Printed Document',
        isPdf: true,
      ));
    }

    // Single docUrl from the print API (legacy path).
    add(_DocFile.fromUrl(ctrl.currentDocUrl.trim(), label: 'Document'));

    // Files attached to the approval header (comma separated).
    for (final u in (ctrl.detailHeader?.attachFile ?? '').split(',')) {
      add(_DocFile.fromUrl(u.trim(), label: 'Attachment'));
    }

    // ✅ Presigned URLs of the underlying document's file(s) (view-only, from backend).
    for (final u in ctrl.documentAttachments) {
      add(_DocFile.fromUrl(u, label: 'Attachment'));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: files.isEmpty
          ? // ── No files ──────────────────────────────────────────────
          const Column(
              children: [
                Icon(Icons.insert_drive_file_outlined,
                    size: 60, color: Colors.white38),
                SizedBox(height: 12),
                Text('No File Uploaded',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70)),
                SizedBox(height: 6),
                Text(
                  'Document is not available for this approval',
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : // ── One or more files ─────────────────────────────────────
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  files.length == 1
                      ? 'Document'
                      : '${files.length} Documents',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 10),
                ...files.map((f) {
                  final url = f.url;
                  final fileName = f.name;
                  final isPdf = f.isPdf;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(children: [
                      // ── File icon ──
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isPdf
                              ? const Color(0x33FF5252)
                              : const Color(0x334CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isPdf ? '📄' : '🖼',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // ── File name + index ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.label,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              fileName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // ── View + Download buttons ──
                      const SizedBox(width: 8),
                      _DocBtn(
                        '👁 View',
                        Colors.white12,
                        Colors.white70,
                        () => _launchFile(url),
                      ),
                      const SizedBox(width: 6),
                      // _DocBtn(
                      //   '⬇',
                      //   newGreenLightColor,
                      //   newGreenColor,
                      //       () => _launchFile(url),
                      // ),
                    ]),
                  );
                }),
              ],
            ),
    );
  }

  Future<void> _launchFile(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        ShowMessage.showSnackBar('Invalid URL', 'Cannot open this file');
        return;
      }
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) ShowMessage.showSnackBar('Error', 'Could not open file');
    } catch (e) {
      ShowMessage.showSnackBar('Failed to open', 'File may not be accessible');
    }
  }
}

/// One viewable file on the detail screen — the printed ERP document (pdfurl)
/// or a file attached to the underlying document.
class _DocFile {
  final String name;
  final String url;
  final String label;
  final bool isPdf;
  const _DocFile(this.name, this.url,
      {this.label = 'Document', this.isPdf = false});

  /// Builds an entry from a bare URL, deriving the file name from the path
  /// (presigned query strings are stripped so the name reads cleanly).
  factory _DocFile.fromUrl(String url, {String label = 'Document'}) {
    final clean = url.trim();
    final name = clean.split('?').first.split('/').last.split('\\').last;
    return _DocFile(
      name.isEmpty ? 'Document' : name,
      clean,
      label: label,
      isPdf: name.toLowerCase().endsWith('.pdf'),
    );
  }
}

class _DocBtn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final VoidCallback? onTap;
  const _DocBtn(this.label, this.bg, this.fg, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ),
      );
}

//  Document items
class _ItemsCard extends StatelessWidget {
  final ApprovalHubController ctrl;
  const _ItemsCard({required this.ctrl});

  /// 30 → '30', 30.5 → '30.5'
  static String _qty(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    final items = ctrl.itemsList;
    if (items.isEmpty) return const SizedBox.shrink();

    final totalQty = items.fold<double>(0, (s, e) => s + e.quantity);
    final totalTaxable = items.fold<double>(0, (s, e) => s + e.taxableAmount);
    final totalTax = items.fold<double>(0, (s, e) => s + e.taxAmount);
    final grandTotal = totalTaxable + totalTax;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SecHead('Items (${items.length})', icon: Icons.list_alt_rounded),
        ...List.generate(items.length, (i) {
          final it = items[i];
          final name = it.itemName.isNotEmpty
              ? it.itemName
              : (it.description.isNotEmpty ? it.description : it.expenseLedger);

          // "30 PCS × ₹38.00 · GST 5%" — each part only if the API sent it.
          final meta = <String>[
            if (it.quantity > 0)
              '${_qty(it.quantity)}${it.unit.isNotEmpty ? ' ${it.unit}' : ''}'
                  '${it.rate > 0 ? ' × ₹${inrNum(it.rate, decimals: 2)}' : ''}',
            if (it.size.isNotEmpty) 'Size: ${it.size}',
            if (it.taxPercent > 0) 'GST ${_qty(it.taxPercent)}%',
          ].join('  ·  ');

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: i == items.length - 1
                      ? Colors.transparent
                      : const Color(0xFFEEF0F4),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text('${it.sno}',
                      style: const TextStyle(
                          color: newTextSecondary, fontSize: 12)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: newTextPrimary)),
                      if (meta.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(meta,
                              style: const TextStyle(
                                  fontSize: 11, color: newTextSecondary)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${inrNum(it.taxableAmount, decimals: 0)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: newBlueColor)),
                    if (it.taxAmount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('+₹${inrNum(it.taxAmount, decimals: 0)} tax',
                            style: const TextStyle(
                                fontSize: 10, color: newTextSecondary)),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),

        // Totals strip — taxable + GST + grand total for the whole document.
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: newSurfaceColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: newBorderColor),
          ),
          child: Column(children: [
            _TotalRow('Total Qty', _qty(totalQty)),
            _TotalRow('Taxable Amount', '₹${inrNum(totalTaxable, decimals: 2)}'),
            if (totalTax > 0)
              _TotalRow('GST', '₹${inrNum(totalTax, decimals: 2)}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: newBorderColor),
            ),
            _TotalRow('Grand Total', '₹${inrNum(grandTotal, decimals: 2)}',
                bold: true),
          ]),
        ),
      ]),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _TotalRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: bold ? 12 : 11,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: bold ? newTextPrimary : newTextSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 14 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  color: bold ? newBlueColor : newTextPrimary)),
        ]),
      );
}

//  Approval chain
class _ChainCard extends StatelessWidget {
  final ApprovalHubController ctrl;
  const _ChainCard({required this.ctrl});

  bool _isDone(String? status) {
    final s = (status ?? '').toLowerCase();
    return s == 'approved' ||
        s == 'approve' ||
        s == 'verified' ||
        s == 'verify';
  }

  bool _isRejected(String? status) {
    final s = (status ?? '').toLowerCase();
    return s == 'rejected' || s == 'reject';
  }

  @override
  Widget build(BuildContext context) {
    final chain = ctrl.approvalChain;
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SecHead('Approval Chain', icon: Icons.timeline_rounded),
        _TlRow(
          dotBg: newGreenLightColor,
          dotFg: newGreenColor,
          icon: Icons.check_rounded,
          label: 'Submitted',
          sub: 'Accounts Dept',
          comment: null,
          isDone: true,
        ),
        if (chain.isNotEmpty)
          ...chain.map((step) {
            final done = _isDone(step.status);
            final rejected = _isRejected(step.status);
            return _TlRow(
              dotBg: done
                  ? newGreenLightColor
                  : rejected
                      ? newRedLightColor
                      : newOrangeLightColor,
              dotFg: done
                  ? newGreenColor
                  : rejected
                      ? newRedColor
                      : newOrangeColor,
              icon: done
                  ? Icons.check_rounded
                  : rejected
                      ? Icons.close_rounded
                      : Icons.access_time_rounded,
              label: '${step.status ?? ''} — ${step.user ?? ''}',
              sub: step.date ?? '',
              comment: (step.remarks ?? '').isNotEmpty ? step.remarks : null,
              isDone: done,
            );
          })
        else
          const _TlRow(
            dotBg: newOrangeLightColor,
            dotFg: newOrangeColor,
            icon: Icons.access_time_rounded,
            label: 'Awaiting Approval',
            sub: 'No chain steps yet',
            comment: null,
            isDone: false,
          ),
      ]),
    );
  }
}

class _TlRow extends StatelessWidget {
  final Color dotBg, dotFg;
  final IconData icon;
  final String label, sub;
  final String? comment;
  final bool isDone;
  const _TlRow(
      {required this.dotBg,
      required this.dotFg,
      required this.icon,
      required this.label,
      required this.sub,
      required this.comment,
      required this.isDone});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: dotBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: 13, color: dotFg)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDone ? newTextPrimary : newOrangeColor)),
                Text(sub,
                    style:
                        const TextStyle(fontSize: 10, color: newTextSecondary)),
                if (comment != null) ...[
                  const SizedBox(height: 5),
                  Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: newSurfaceColor,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: newBorderColor)),
                      child: Text(comment!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: newTextSecondary,
                              height: 1.4))),
                ],
              ])),
        ]),
      );
}

//  Related documents
class _RelatedCard extends StatelessWidget {
  final ApprovalHubController ctrl; // ✅ only ctrl needed
  const _RelatedCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final docs = ctrl.relatedDocs;
    if (docs.isEmpty) return const SizedBox();
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SecHead('Related Documents', icon: Icons.link_rounded),
        ...docs.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                  color: newSurfaceColor,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: newBorderColor)),
              child: Row(children: [
                const Text('📄', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${d.relatedType ?? ''} — ${d.relatedDocNo ?? ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: newTextPrimary)),
                      Text(d.relatedDate ?? '',
                          style: const TextStyle(
                              fontSize: 10, color: newTextSecondary)),
                    ])),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: newBlueLightColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(d.relatedStatus ?? d.relatedType ?? '',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: newBlueColor)),
                ),
              ]),
            )),
      ]),
    );
  }
}

//  Bottom action bar
// 1. Add const + pass ctrl to _BottomBar
class _BottomBar extends StatelessWidget {
  final ApprovalHubController ctrl;
  const _BottomBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final headerStatus = (ctrl.detailHeader?.status ?? '').toLowerCase().trim();
    final listStatus = (ctrl.currentItem?.status ?? '').toLowerCase().trim();
    final status = headerStatus.isNotEmpty ? headerStatus : listStatus;

    final isApproved = status == 'approved' || status == 'approve';
    final isRejected = status == 'rejected' || status == 'reject';
    final isDisapproved = status == 'disapproved' || status == 'disapprove';

    final isReimbursement = (ctrl.currentItem?.approvalType ?? '')
        .toLowerCase()
        .contains('reimbursement');
    final isL2 = (ctrl.currentItem?.approvalTypeCode ??
            ctrl.currentItem?.approvalType ??
            '')
        .toLowerCase()
        .contains('l2');

    // ✅ Check disapprove first — overrides everything
    if (ctrl.showDisapprove) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: newBorderColor))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: ctrl.isLoadingDetail
                  ? null
                  : () {
                      ctrl.pickAction(ApprovalAction.disapprove);
                      Get.to(const ApprovalHubAction());
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: newRedColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Disapprove 🚫',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      );
    }

    final hideAction = isApproved ||
        isRejected ||
        isDisapproved || // ✅ hide action button for disapproved
        (isReimbursement && isL2 && status != 'verify' && status != 'verified');

    if (hideAction) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: newBorderColor))),
      child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: ctrl.isLoadingDetail
                  ? null
                  : () => Get.to(const ApprovalHubAction()),
              style: ElevatedButton.styleFrom(
                  backgroundColor: newBlueColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Take Action →',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          )),
    );
  }
}

//  Shared widgets
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: newBorderColor),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: child,
      );
}

/// Section heading: blue icon + uppercase blue title + hairline rule,
/// matching the web ERP's "DOCUMENT DETAILS" / "PARTY DETAILS" headers.
class _SecHead extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SecHead(this.text, {this.icon = Icons.info_outline_rounded});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: newBlueColor),
            const SizedBox(width: 7),
            Expanded(
              child: Text(text.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: newBlueColor,
                      letterSpacing: .8)),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 13),
            child: Divider(height: 1, color: newBorderColor),
          ),
        ],
      );
}

/// One "LABEL over value" field. Plain (no box), like the web ERP.
class _InfoTile extends StatelessWidget {
  final _IT t;
  const _InfoTile(this.t);

  @override
  Widget build(BuildContext context) {
    final isEmpty = t.value.trim().isEmpty;
    return SizedBox(
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9.5,
                color: newTextHint,
                fontWeight: FontWeight.w700,
                letterSpacing: .6)),
        const SizedBox(height: 4),
        Text(isEmpty ? '-' : t.value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: isEmpty ? newTextHint : (t.vc ?? newTextPrimary)),
            maxLines: t.maxLines,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _IT {
  final String label, value;
  final Color? vc;
  final int maxLines;
  const _IT(this.label, this.value, {this.vc, this.maxLines = 2});
}
