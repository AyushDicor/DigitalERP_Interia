// import 'package:digitalerp/contactsview/contacts_view_responce.dart';
// import 'package:digitalerp/contactsview/add_contacts.dart';
// import 'package:digitalerp/screen/base/base_controller.dart';
// import 'package:digitalerp/screen/ui/home/customer_list/customer_list_controller.dart';
// import 'package:digitalerp/utils/app_constant.dart';
// import 'package:digitalerp/utils/my_app_bar_new.dart';
// import 'package:digitalerp/utils/show_message.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ViewContactsDetails extends StatefulWidget {
//   const ViewContactsDetails({Key? key, required this.partyId}) : super(key: key);
//   final String partyId;
//
//   @override
//   State<ViewContactsDetails> createState() => _ContactsDetailsViewState();
// }
//
// class _ContactsDetailsViewState extends State<ViewContactsDetails> {
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<CustomerListController>(
//       init: CustomerListController(),
//         builder: (controller) {
//       return Scaffold(
//         body: Center(
//           child: Stack(
//             children: [
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 bottom: 0,
//                 child: Container(
//                   decoration: const BoxDecoration(
//                     image: DecorationImage(
//                       image: AssetImage('assets/images/dashboard_bg.png'),
//                       fit: BoxFit.fill,
//                     ),
//                   ),
//                   child: SafeArea(
//                     child: MyAppBar(
//                       title: 'View Contacts',
//                       onBackTap: () => Get.back(),
//                     ),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: Get.height * 0.138,
//                 left: 25,
//                 right: 0,
//                 bottom: 0,
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: EdgeInsets.only(top: 15),
//                       child: Text(
//                         'Add Contacts',
//                         style: TextStyle().bold,
//                       ),
//                     ),
//                     SizedBox(
//                       width: Get.width * 0.500,
//                     ),
//                     Container(
//                         height: 35,
//                         width: 30,
//                         decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: customGradient(
//                                 topColor: orangeColor, bottomColor: red2Color)),
//                         child: InkWell(
//                           onTap: () {
//                             Navigator.push(context, MaterialPageRoute(builder: (context)=> AddContactsView(partyId: widget.partyId,)));
//                             // Get.off(AddContactsView());
//                             controller.getDesignationDropdownList(widget.partyId);
//                           },
//                           child: Icon(
//                             Icons.add,
//                             color: Colors.white,
//                           ),
//                         )),
//                   ],
//                 ),
//               ),
//               Positioned(
//                   right: 0,
//                   left: 0,
//                   bottom: 0,
//                   top: Get.height * 0.230,
//                   child: SingleChildScrollView(
//                     child: Column(children: [
//                     controller.addContactsViewList.isEmpty
//                       ? const SizedBox(child:CircularProgressIndicator())
//                      : ListView.builder(
//                           shrinkWrap: true,
//                           padding: EdgeInsets.zero,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: controller.addContactsViewList.length,
//                           itemBuilder: (context, index) => contactsDetails(controller.addContactsViewList.elementAt(index))),
//                     ]),
//                   )),
//             ],
//           ),
//         ),
//       );
//     });
//   }
//
//   contactsDetails(AddContactsData data) {
//     return Padding(
//       padding: const EdgeInsets.all(5.0),
//       child: Card(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         color: Colors.white,
//         child: InkWell(
//           onTap: () {},
//           child: Container(
//             width: Get.width,
//             // height: Get.height * 0.270,
//             decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 color: Colors.white,
//                 boxShadow: const [
//                   BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 3,
//                       offset: Offset(0, 3))
//                 ]),
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Container(
//                       width: Get.width*0.530,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Contact Person",
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.deepOrange.shade400)),
//                           Text(
//                                data.contactPerson ?? "",
//                               // 'N/A',
//
//                               style: TextStyle().xstyle),
//                           const SizedBox(
//                             height: 12,
//                           ),
//                           Text(
//                             "WhatsApp Number",
//                             style: const TextStyle().newstyle,
//                           ),
//                           Row(
//                             children: [
//                               Text(
//                                 data.whatsappno ?? '',
//                                 // 'N/A',
//                                 style: const TextStyle().xstyle,
//                               ),
//                               SizedBox(width: 10,),
//                               InkWell(
//                                   onTap: (){
//                                     openDialPad(data.whatsappno.toString());
//                                   },
//                                   child:Image.asset('assets/images/call-icon.png',scale: 27,)
//                               ),
//                               SizedBox(width: 10,),
//                               InkWell(
//                                   onTap: (){
//                                     _launchWhatsapp(data.whatsappno.toString());
//                                   },
//                                   child:Image.asset('assets/images/whatsapp.png',scale: 18,)
//                               )
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       width: Get.width*0.350,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Email",
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.deepOrange.shade400)),
//                           Text(
//                             data.emailid ?? '',
//                               // 'N/A',
//                               style: const TextStyle().xstyle),
//                           const SizedBox(
//                             height: 7,
//                           ),
//                           Text(
//                             "Designation",
//                             style: const TextStyle().newstyle,
//                           ),
//                           Text(
//                             data.designation ?? '',
//                             // 'N/A',
//                             overflow: TextOverflow.visible,
//                             style: const TextStyle().xstyle,
//                           ),
//                           const SizedBox(
//                             height: 7,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(
//                         left: 255,
//                         top: 10,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _launchWhatsapp(String whatsappNumber) async {
//     var whatsapp = whatsappNumber;
//     var whatsappAndroid =Uri.parse("whatsapp://send?phone=$whatsapp");
//     if (await canLaunchUrl(whatsappAndroid)) {
//       await launchUrl(whatsappAndroid);
//     } else {
//       ShowMessage.showSnackBar('', 'WhatsApp not installed');
//     }
//   }
//
//   Future<void> openDialPad(String phoneNumber) async {
//     Uri url = Uri(scheme: "tel", path: phoneNumber);
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url);
//     } else {
//       print("Can't open dial pad.");
//     }
//   }
//
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screen/ui/home/customer_list/customer_list_controller.dart';
import '../utils/app_constant_new.dart';
import '../utils/show_message.dart';
import 'add_contacts.dart';
import 'contacts_view_responce.dart';

class ViewContactsDetails extends StatefulWidget {
  const ViewContactsDetails({Key? key, required this.partyId}) : super(key: key);
  final String partyId;

  @override
  State<ViewContactsDetails> createState() => _ContactsDetailsViewState();
}

class _ContactsDetailsViewState extends State<ViewContactsDetails> {
  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).viewPadding.top;

    return GetBuilder<CustomerListController>(
      init: CustomerListController(),
      builder: (controller) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 40,
                          height: 40,
                          // decoration: BoxDecoration(
                          //   color: whiteBoxColor,
                          //   borderRadius: BorderRadius.circular(12),
                          //   border: Border.all(color: newBorderColor),
                          //   boxShadow: [
                          //     // BoxShadow(
                          //     //   color: Colors.black.withValues(alpha: 0.06),
                          //     //   blurRadius: 8,
                          //     //   offset: const Offset(0, 2),
                          //     // ),
                          //   ],
                          // ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: newTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Contacts',
                          style: TextStyle(
                            color: newTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      // Add button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddContactsView(partyId: widget.partyId),
                            ),
                          );
                          controller.getDesignationDropdownList(widget.partyId);
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: purpleColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: purpleColor.withValues(alpha: 0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── List ─────────────────────────────────────────────
                Expanded(
                  child: controller.addContactsViewList.isEmpty
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: purpleColor,
                      strokeWidth: 2.5,
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: controller.addContactsViewList.length,
                    itemBuilder: (context, index) =>
                        _contactCard(controller.addContactsViewList[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactCard(AddContactsData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: whiteBoxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: newBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: purpleColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: purpleColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Person',
                        style: TextStyle(
                          color: newTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.contactPerson ?? '—',
                        style: const TextStyle(
                          color: newTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: newBorderColor, height: 1),
            const SizedBox(height: 14),

            // Info grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _infoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: data.emailid ?? '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoTile(
                    icon: Icons.badge_outlined,
                    label: 'Designation',
                    value: data.designation ?? '—',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // WhatsApp row
            _infoTile(
              icon: Icons.chat_outlined,
              label: 'WhatsApp Number',
              value: data.whatsappno ?? '—',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconAction(
                    icon: Icons.call_outlined,
                    color: Colors.green,
                    onTap: () => openDialPad(data.whatsappno.toString()),
                  ),
                  const SizedBox(width: 8),
                  _iconAction(
                    assetPath: 'assets/images/whatsapp.png',
                    color: const Color(0xFF25D366),
                    onTap: () => _launchWhatsapp(data.whatsappno.toString()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData? icon,
    String? assetPath,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: newBorderColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon != null
              ? Icon(icon, size: 16, color: newTextSecondary)
              : Padding(
            padding: const EdgeInsets.all(7),
            child: Image.asset(assetPath!, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: newTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: newTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconAction({
    IconData? icon,
    String? assetPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon != null
            ? Icon(icon, size: 16, color: color)
            : Padding(
          padding: const EdgeInsets.all(7),
          child: Image.asset(assetPath!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _launchWhatsapp(String whatsappNumber) async {
    final uri = Uri.parse("whatsapp://send?phone=$whatsappNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ShowMessage.showSnackBar('', 'WhatsApp not installed');
    }
  }

  Future<void> openDialPad(String phoneNumber) async {
    final url = Uri(scheme: "tel", path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}