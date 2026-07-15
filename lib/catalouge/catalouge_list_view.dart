import 'package:newdigitalerp/catalouge/catalogue_list_response.dart';
import 'package:newdigitalerp/catalouge/catalouge_controller.dart';

import 'package:newdigitalerp/utils/app_assets.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class CatalougeListView extends StatelessWidget {
  const CatalougeListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CatalougeController>(
      init: CatalougeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: Column(
              children: [
                //  App Bar 
                _AppBar(),

                //  Search bar (dropdown + button) 
                _SearchBar(controller: controller),

                //  Results list 
                Expanded(
                  child: controller.catalougeData.isEmpty
                      ? const Center(
                          child: Text(
                            'No results found',
                            style: TextStyle(
                              fontSize: 16,
                              color: grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: controller.catalougeData.length,
                          itemBuilder: (context, index) => _CatalogueCard(
                            data: controller.catalougeData.elementAt(index),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 
// App Bar
// 
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: blackColor),
            onPressed: () => Get.back(),
          ),
          const Text(
            'Category Catalogue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: newTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// 
// Search Bar (dropdown + search button)
// 
class _SearchBar extends StatelessWidget {
  final CatalougeController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Category dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton2<int>(
              isExpanded: true,
              hint: const Text(
                'Select Category',
                style: TextStyle(fontSize: 14, color: newTextHint),
              ),
              items: controller.categoryList.map((items) {
                return DropdownMenuItem<int>(
                  value: items.categoryid,
                  child: Text(
                    items.categoryname.toString(),
                    style: const TextStyle(fontSize: 14, color: blackColor),
                  ),
                );
              }).toList(),
              value: controller.selectCategory?.categoryid,
              onChanged: (newValue) => controller.setSelectedCategoryDropDown(
                controller.categoryList
                    .firstWhere((e) => e.categoryid == newValue),
              ),
              buttonStyleData: ButtonStyleData(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8E9EF)),
                ),
              ),
              iconStyleData: const IconStyleData(
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: newTextHint, size: 22),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE8E9EF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 40,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (controller.selectCategory == null ||
                    (controller.selectCategory?.categoryname?.isEmpty ??
                        true)) {
                  ShowMessage.showSnackBar('', 'Please Select a Category');
                } else {
                  controller.getCatalougeListApi(
                      controller.selectCategory?.categoryid.toString() ?? '');
                }
              },
              icon: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 20),
              label: const Text(
                'Search',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: purpleColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 
// Catalogue Card
// 
class _CatalogueCard extends StatelessWidget {
  final CatalougeData data;

  const _CatalogueCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category icon placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: purpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: purpleColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Category name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category Name',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: newTextHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.categoryname?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: newTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          // PDF download button
          GestureDetector(
            onTap: () async {
              if (data.catalouhefile != null) {
                await launchUrl(
                  Uri.parse(data.catalouhefile.toString()),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: newRedLightColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/iconsnew/pdfIcon.png',
                    height: 20,
                    width: 20,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'PDF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: newRedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
