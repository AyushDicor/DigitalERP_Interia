// Shared attachment source picker used by every document-upload module
// (Performa Invoice, Purchase Order, Indent, MRN, …). Shows a bottom sheet with
// Camera / Gallery / Files and returns the picked files as [PickedAttachment]s
// (path + display name). Camera → 1 photo, Gallery → many images, Files → many
// docs. Returns an empty list if the user cancels/dismisses.
//
// Modules keep their existing upload loop unchanged — they just swap their
// direct `FilePicker.platform.pickFiles(...)` call for `await pickAttachments()`
// and iterate the returned list (`pf.path`, `pf.name`).

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

class PickedAttachment {
  final String path;
  final String name;
  const PickedAttachment(this.path, this.name);
}

/// Opens a Camera / Gallery / Files chooser and returns the selected files.
/// Empty list = user cancelled or picked nothing.
Future<List<PickedAttachment>> pickAttachments({
  List<String> allowedExtensions = const [
    'jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx',
  ],
}) async {
  final completer = Completer<List<PickedAttachment>>();
  var chose = false;

  void finish(List<PickedAttachment> r) {
    if (!completer.isCompleted) completer.complete(r);
  }

  Widget option(IconData icon, String label,
      Future<List<PickedAttachment>> Function() action) {
    return GestureDetector(
      onTap: () async {
        chose = true;
        Get.back();
        try {
          finish(await action());
        } catch (_) {
          finish(const []);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: newBlueLightColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: newBlueColor),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: newBlueColor)),
        ]),
      ),
    );
  }

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 18),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Add Attachment',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        option(Icons.camera_alt_outlined, 'Take a Photo', _fromCamera),
        option(Icons.photo_library_outlined, 'Choose from Gallery', _fromGallery),
        option(Icons.insert_drive_file_outlined, 'Choose Files',
            () => _fromFiles(allowedExtensions)),
      ]),
    ),
    isScrollControlled: false,
  ).then((_) {
    // Sheet dismissed by tap-outside/back without choosing an option.
    if (!chose) finish(const []);
  });

  return completer.future;
}

Future<List<PickedAttachment>> _fromCamera() async {
  final x = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 70,
  );
  if (x == null) return const [];
  return [PickedAttachment(x.path, x.name)];
}

Future<List<PickedAttachment>> _fromGallery() async {
  final xs = await ImagePicker().pickMultiImage(imageQuality: 70);
  return xs.map((x) => PickedAttachment(x.path, x.name)).toList();
}

Future<List<PickedAttachment>> _fromFiles(List<String> allowedExtensions) async {
  final r = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    allowMultiple: true,
  );
  if (r == null) return const [];
  return r.files
      .where((f) => f.path != null)
      .map((f) => PickedAttachment(f.path!, f.name))
      .toList();
}
