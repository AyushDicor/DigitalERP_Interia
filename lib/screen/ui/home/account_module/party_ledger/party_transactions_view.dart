import 'package:newdigitalerp/fab/menu_fab.dart';
import 'package:newdigitalerp/response/collection_customer_list_response.dart';
import 'package:newdigitalerp/response/transaction_list_response.dart';

import 'package:newdigitalerp/screen/ui/home/account_module/party_ledger/party_transactions_controller.dart';
import 'package:newdigitalerp/utils/app_assets.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/app_loader.dart';
import 'package:newdigitalerp/utils/gradient_icon_app_button.dart';
import 'package:newdigitalerp/utils/my_app_bar_new.dart';
import 'package:newdigitalerp/utils/solid_app_button.dart';
import 'package:newdigitalerp/utils/table_widget.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

final Color _kBg     = backgroundColor;
const Color _kWhite  = Colors.white;
const Color _kBorder = Color(0xFFE4E7EF);
const Color _kText   = newTextPrimary;
const Color _kSub    = newTextSecondary;

class PartyTransactionsView extends StatelessWidget {
  const PartyTransactionsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PartyLedgerController>(
      init: PartyLedgerController(),
      builder: (controller) => Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar('Party Transactions'),
        floatingActionButton: MenuFab(parentMenuId: 2382),
        body: controller.isBusy
            ? const AppLoader()
            : SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 200 : 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(children: [
                _label('Party Name'),
                _dropdownWrap(_partyDropdown(controller)),
              ]),
              const SizedBox(height: 16),
              _card(children: [
                _label('Date Range'),
                Row(children: [
                  Expanded(
                      child: _dateField(context, controller.selectFromDate,
                          'From Date', controller)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('to',
                        style: TextStyle(fontSize: 13, color: _kSub)),
                  ),
                  Expanded(
                      child: _dateField(context, controller.selectToDate,
                          'To Date', controller)),
                ]),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.showTransaction,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Show Transaction',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purpleColor,
                    foregroundColor: _kWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              if (controller.transactionList.isNotEmpty) ...[
                const SizedBox(height: 20),
                _card(children: [
                  _label('Transaction'),
                  _dropdownWrap(_transactionDropdown(controller)),
                ]),
              ],
              const SizedBox(height: 24),
              Center(
                child: GradientIconButton(
                  onPressed: controller.onShare,
                  iconSize: 18,
                  radius: 30,
                  vPadding: 18,
                  hPadding: 18,
                  topColor: purpleColor,
                  bottomColor: blueColor,
                  icon: AppAssets.shareIcon,
                  shadowRadius: 15,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _partyDropdown(PartyLedgerController controller) =>
      DropdownButtonHideUnderline(
        child: DropdownButton2<CustomerData>(
          isExpanded: true,
          value: controller.selectedPartyValue,
          hint: const Text('Party Name', style: TextStyle(fontSize: 14, color: _kSub)),
          items: controller.partyList.map((items) {
            return DropdownMenuItem<CustomerData>(value: items, child: Text(items.partyname ?? '', style: const TextStyle(fontSize: 14, color: _kText)));
          }).toList(),
          onChanged: controller.setSelectedPartyValue,
          buttonStyleData: ButtonStyleData(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.transparent),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _kWhite),
          ),
          iconStyleData: const IconStyleData(icon: Icon(Icons.keyboard_arrow_down_rounded, color: _kSub, size: 22)),
        ),
      );

  Widget _transactionDropdown(PartyLedgerController controller) =>
      DropdownButtonHideUnderline(
        child: DropdownButton2<TransactionData>(
          isExpanded: true,
          value: controller.selectedTransactionValue,
          hint: const Text('List of Transaction', style: TextStyle(fontSize: 14, color: _kSub)),
          items: controller.transactionList.map((items) {
            return DropdownMenuItem<TransactionData>(value: items, child: Text(items.perticular ?? '', style: const TextStyle(fontSize: 14, color: _kText)));
          }).toList(),
          onChanged: controller.setSelectedTransactionValue,
          buttonStyleData: ButtonStyleData(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.transparent),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _kWhite),
          ),
          iconStyleData: const IconStyleData(icon: Icon(Icons.keyboard_arrow_down_rounded, color: _kSub, size: 22)),
        ),
      );

  Widget _dateField(BuildContext context, String value, String title,
      PartyLedgerController ctrl) {
    return GestureDetector(
      onTap: () async {
        DateTime selectDate;
        try {
          selectDate = DateFormat(AppString.ddMMyyyy).parse(
              title == 'To Date' ? ctrl.selectToDate : ctrl.selectFromDate);
        } catch (e) {
          selectDate = DateTime.now();
        }
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectDate,
          firstDate: AppConst.calenderFirstDate ??
              DateTime(
                  int.parse(ctrl.homeController.currentUserData!.yearId!
                      .split('-')
                      .first),
                  4,
                  1),
          lastDate: AppConst.calenderLastDate ??
              DateTime(DateTime.now().year + 1, 3, 31),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: purpleColor, onPrimary: Colors.white)),
            child: child!,
          ),
        );
        if (pickedDate != null) {
          final fmt = DateFormat(AppString.ddMMyyyy).format(pickedDate);
          if (title == 'To Date') {
            ctrl.setSelectedToDate(fmt);
          } else {
            ctrl.setSelectedFromDate(fmt);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: _kText),
            ),
          ),
          const Icon(Icons.calendar_today_outlined, size: 14, color: _kSub),
        ]),
      ),
    );
  }
}

//  Shared 
AppBar _buildAppBar(String title, {List<Widget>? actions}) => AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  surfaceTintColor: Colors.white,
  leading: GestureDetector(
    onTap: () => Get.back(),
    child: const Icon(Icons.arrow_back_ios_new_rounded,
        color: Color(0xFF111827), size: 20),
  ),
  title: Text(title,
      style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
  actions: actions,
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(color: const Color(0xFFE4E7EF), height: 1),
  ),
);

Widget _card({required List<Widget> children}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withValues(alpha:0.06),
          blurRadius: 12,
          offset: const Offset(0, 4))
    ],
  ),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
);

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
);

Widget _dropdownWrap(Widget child) => Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE4E7EF)),
  ),
  child: child,
);