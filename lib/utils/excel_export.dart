import 'dart:developer';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;

/// Result of an export so the caller can tell the user what actually happened
/// rather than guessing. [opened] is false when the file was written fine but
/// no app on the device can open .xlsx — common on emulators and on phones
/// without a spreadsheet app, where a silent no-op looks like a broken button.
typedef ExcelResult = ({String? path, String? error, bool opened});

/// Writes any list of rows to an .xlsx — the same approach the Sales Invoice
/// screen uses, generalised so screens with server-defined columns (MIS
/// reports) can export without knowing their shape in advance.
class ExcelExport {
  const ExcelExport._();

  /// [columns] are the keys to write, in order. [headerFor] turns a key into a
  /// display heading; defaults to the key itself.
  static Future<ExcelResult> export({
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
    required String fileNameBase,
    String Function(String column)? headerFor,
    bool open = true,
  }) async {
    if (columns.isEmpty) {
      return (path: null, error: 'Nothing to export', opened: false);
    }

    final workbook = excel.Workbook();
    try {
      final sheet = workbook.worksheets[0];

      // Header row.
      for (var c = 0; c < columns.length; c++) {
        final label = headerFor?.call(columns[c]) ?? columns[c];
        final cell = sheet.getRangeByIndex(1, c + 1);
        cell.setText(label);
        // Roughly fit the heading; long text columns get more room.
        cell.columnWidth = (label.length + 6).clamp(12, 42).toDouble();
      }
      sheet.getRangeByIndex(1, 1, 1, columns.length).cellStyle
        ..bold = true
        ..fontSize = 10;

      // Data rows. Numbers stay numbers so Excel can total them; dates become
      // dd-MM-yyyy text, matching how the app displays them.
      for (var r = 0; r < rows.length; r++) {
        final row = rows[r];
        for (var c = 0; c < columns.length; c++) {
          final value = row[columns[c]];
          final cell = sheet.getRangeByIndex(r + 2, c + 1);
          if (value == null) {
            cell.setText('');
          } else if (value is num) {
            cell.setNumber(value.toDouble());
          } else {
            final s = value.toString();
            final dt = DateTime.tryParse(s);
            cell.setText(dt != null && s.contains('T')
                ? DateFormat('dd-MM-yyyy').format(dt)
                : s);
          }
        }
      }

      final bytes = workbook.saveAsStream();

      // App-private storage: needs no runtime permission on any Android
      // version, and OpenFilex/Share can both still reach it.
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final stamp = DateFormat('ddMMMyyyy_HHmm').format(DateTime.now());
      final safeName = fileNameBase.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final path = '${dir.path}/$safeName-$stamp.xlsx';

      await File(path).writeAsBytes(bytes, flush: true);
      log('Excel written: $path (${bytes.length} bytes)');

      if (!open) return (path: path, error: null, opened: false);

      final result = await OpenFilex.open(path);
      log('OpenFilex: ${result.type} ${result.message}');
      final opened = result.type == ResultType.done;
      return (path: path, error: null, opened: opened);
    } catch (e, s) {
      log('Excel export failed: $e', stackTrace: s);
      return (path: null, error: e.toString(), opened: false);
    } finally {
      workbook.dispose();
    }
  }

  /// Hands the saved file to the share sheet — the fallback when the device
  /// has no app that opens spreadsheets.
  static Future<void> share(String path, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], subject: subject),
      );
    } catch (e) {
      log('Excel share failed: $e');
    }
  }
}
