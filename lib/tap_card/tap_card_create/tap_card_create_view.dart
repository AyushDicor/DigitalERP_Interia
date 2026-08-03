// Tap Card — create/edit form. Serves three entry points: a blank manual entry,
// a form pre-filled from an OCR scan, and editing an existing card.
// Ported from TapCard's ConfirmCardScreen.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/app_constant_new.dart';
import 'tap_card_create_controller.dart';
import '../tap_card_models.dart';
import '../tap_card_utils/tap_card_widgets.dart';

class TapCardCreateView extends StatelessWidget {
  /// Pass a card to edit it; leave null to create.
  final TapCardModel? editing;

  /// Pass OCR results to pre-fill a new card.
  final ScannedCardData? scanned;

  const TapCardCreateView({Key? key, this.editing, this.scanned})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TapCardCreateController>(
      // Tag by entry point so editing one card then another doesn't reuse the
      // first card's controller (GetBuilder caches by type otherwise).
      tag: 'tapcard_form_${editing?.key ?? 'new'}',
      init: TapCardCreateController(editing: editing, scanned: scanned),
      builder: (c) => Scaffold(
        backgroundColor: kTapBg,
        appBar: AppBar(
          backgroundColor: kTapSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: kTapBorder,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: newTextPrimary,
              size: 20,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.isEdit ? 'Edit Card' : 'New Card',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kTapTextPrimary,
                ),
              ),
              Text(
                c.fromScan
                    ? 'Review the scanned details'
                    : 'Save a business card',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: kTapTextSecondary,
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
          children: [
            if (c.fromScan) _scanHint(),
            _sectionCard(
              'Card Photos',
              Icons.photo_camera_outlined,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _imageSlot(context, c, front: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _imageSlot(context, c, front: false)),
                ],
              ),
            ),
            _sectionCard(
              'Card Type',
              Icons.sell_outlined,
              TapCategorySelector(
                selected: c.category,
                onChanged: c.setCategory,
              ),
            ),
            _sectionCard(
              'Personal Info',
              Icons.person_outline_rounded,
              Column(
                children: [
                  _field(
                    c,
                    label: 'Full Name',
                    field: 'name',
                    controller: c.nameCtrl,
                    icon: Icons.person_outline_rounded,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    c,
                    label: 'Job Title',
                    field: 'title',
                    controller: c.titleCtrl,
                    icon: Icons.work_outline_rounded,
                  ),
                ],
              ),
            ),
            _sectionCard(
              'Contact Details',
              Icons.contact_phone_outlined,
              Column(
                children: [
                  _field(
                    c,
                    label: 'Phone Number',
                    field: 'phone',
                    controller: c.phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    c,
                    label: 'Email Address',
                    field: 'email',
                    controller: c.emailCtrl,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            _sectionCard(
              'Company Info',
              Icons.business_outlined,
              Column(
                children: [
                  _field(
                    c,
                    label: 'Company Name',
                    field: 'company',
                    controller: c.companyCtrl,
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    c,
                    label: 'Website',
                    field: 'website',
                    controller: c.websiteCtrl,
                    icon: Icons.language_outlined,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _saveButton(c),
          ],
        ),
      ),
    );
  }

  Widget _scanHint() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: purpleLightest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kTapPrimary.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: const [
        Icon(Icons.auto_fix_high_rounded, size: 18, color: kTapPrimary),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'We read these details off the card. Check them before saving.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTapPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionCard(String title, IconData icon, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kTapSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kTapBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: kTapPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTapTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _field(
    TapCardCreateController c, {
    required String label,
    required String field,
    required TextEditingController controller,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    final error = c.errors[field];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: kTapBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: error != null ? newRedColor : kTapBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (_) => c.clearError(field),
            style: const TextStyle(fontSize: 14, color: kTapTextPrimary),
            decoration: InputDecoration(
              hintText: required ? '$label *' : label,
              hintStyle: const TextStyle(fontSize: 13.5, color: kTapTextHint),
              prefixIcon: Icon(icon, size: 18, color: kTapTextSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 5),
            child: Text(
              error,
              style: const TextStyle(fontSize: 11.5, color: newRedColor),
            ),
          ),
      ],
    );
  }

  Widget _imageSlot(
    BuildContext context,
    TapCardCreateController c, {
    required bool front,
  }) {
    final path = front ? c.frontImage : c.backImage;
    final label = front ? 'Front' : 'Back';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: kTapTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _chooseSource(context, c, front: front),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: kTapBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kTapBorder,
                style: path == null ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: path == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 20,
                        color: kTapTextHint,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Add photo',
                        style: TextStyle(fontSize: 11, color: kTapTextHint),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: TapCardImage(path),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => c.removeImage(front: front),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _chooseSource(
    BuildContext context,
    TapCardCreateController c, {
    required bool front,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kTapSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: kTapPrimary,
              ),
              title: const Text(
                'Take a photo',
                style: TextStyle(fontSize: 14, color: kTapTextPrimary),
              ),
              onTap: () {
                Get.back();
                c.pickImage(front: front, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: kTapPrimary,
              ),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(fontSize: 14, color: kTapTextPrimary),
              ),
              onTap: () {
                Get.back();
                c.pickImage(front: front, source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton(TapCardCreateController c) => GestureDetector(
    onTap: c.saving
        ? null
        : () async {
            final ok = await c.save();
            // Hand the message back with the result so the LIST screen
            // shows it after the pop. Two reasons, both GetX 4.6.5:
            //  * back() starts with `if (isSnackbarOpen) { close; return; }`
            //    — so showing the message here would eat the navigation.
            //  * closeOverlays:true clears any snackbar still up from an
            //    earlier failed attempt, which would trip the same guard.
            if (ok) {
              Get.back(result: c.successMessage ?? true, closeOverlays: true);
            }
          },
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: c.saving ? kTapPrimary.withValues(alpha: 0.6) : kTapPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: c.saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Text(
              c.isEdit ? 'Update Card' : 'Save Card',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    ),
  );
}
