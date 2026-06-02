import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:newdigitalerp/auth/fotgot_password/forgot_pass_otp/forgot_pass_otp_view.dart';
import 'package:newdigitalerp/auth/fotgot_password/forgot_pass_otp/reset_password/reset_password_view.dart';
import 'package:newdigitalerp/auth/fotgot_password/forgot_password_view.dart';
import 'package:newdigitalerp/change_company/change_company_view.dart';
import 'package:newdigitalerp/home_view_new.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_hub_screens/approval_hub_dashboard.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/approved_or_rejected_leave_view/approve_or_rejected_leaves_view.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_list/attendance_list_view.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_view.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/leave_apply_view/leave_apply_view.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/leave_history_view/leave_history_view.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/dashboard_view.dart';
import 'package:newdigitalerp/screen/ui/home/drawer/profile/profile_view.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_attendance/approved_or_rejected_leave_view/approve_or_rejected_leaves_view.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_attendance/executive_attendance_list/executive_attendance_list_view.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_attendance/executive_attendance_view.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_list_view.dart';

import '../auth/login/login_screen.dart';
import '../auth/otp/otp_view.dart';
import '../auth/splash/splash_view.dart';

import '../home/home_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static List<GetPage> routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      //transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      // transition: Transition.fade,
    ),
    GetPage(name: AppRoutes.otp, page: () => const OtpView()),
    GetPage(name: AppRoutes.home, page: () => HomeView()),


    // GetPage(
    //   name: AppRoutes.setupProfile,
    //   page: () => const SetupView(),
    // ),
    // GetPage(
    //   name: AppRoutes.map,
    //   page: () => const MapView(),
    // ),
    GetPage(
      name: AppRoutes.attendance,
      page: () => AttendanceView(),
    ),
    //
    GetPage(
      name: AppRoutes.leaveApply,
      page: () => LeaveApplyView(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.forgotPassOtp,
      page: () => const ForgotPassOtpView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordView(),
      transition: Transition.rightToLeft,
    ),
    // GetPage(
    //   name: AppRoutes.visitPlanDetail,
    //   page: () => const VisitPlanDetailView(),
    // ),
    // GetPage(
    //   name: AppRoutes.visitPlan,
    //   page: () => const VisitPlanView(),
    // ),
    GetPage(
      name: AppRoutes.approvedOrLeaveView,
      page: () => const ApprovedOrRejectedLeaveView(),
    ),
    GetPage(
      name: AppRoutes.executiveApprovedOrLeaveView,
      page: () => const ExecutiveApprovedOrRejectedLeaveView(),
    ),
    // GetPage(
    //   name: AppRoutes.stockTakingView,
    //   page: () => const StockTakingView(),
    // ),
    // GetPage(
    //   name: AppRoutes.newVisitPlaning,
    //   page: () => const NewVisitPlaningView(),
    // ),
    // GetPage(
    //   name: AppRoutes.preview,
    //   page: () => const PreviewView(),
    // ),
    // GetPage(
    //   name: AppRoutes.partyList,
    //   page: () => const CustomerListView(),
    // ),
    // GetPage(
    //   name: AppRoutes.orderDetail,
    //   page: () => const OrderDetailView(),
    // ),
    // GetPage(
    //   name: AppRoutes.imageDetail,
    //   page: () => const ImageDetailView(),
    // ),
    // GetPage(
    //   name: AppRoutes.paymentEntry,
    //   page: () =>
    //   const PaymentEntryView(isPayment: true, title: 'Payment Entry'),
    // ),
    // GetPage(
    //   name: AppRoutes.receiptEntry,
    //   page: () => const ReceiptEntryView(),
    // ),
    // GetPage(
    //   name: AppRoutes.collection,
    //   page: () => const CollectionView(),
    // ),
    // GetPage(
    //   name: AppRoutes.expense,
    //   page: () => const ExpensesView(),
    // ),
    // GetPage(
    //   name: AppRoutes.outstanding,
    //   page: () => OutstandingView(),
    // ),
    // GetPage(
    //   name: AppRoutes.contra,
    //   page: () => const ContraView(),
    // ),
    // GetPage(
    //   name: AppRoutes.journalEntry,
    //   page: () => const JournalEntryView(),
    // ),
    // GetPage(
    //   name: AppRoutes.partyTransactions,
    //   page: () => const PartyTransactionsView(),
    // ),
    GetPage(
      name: AppRoutes.attendanceList,
      page: () => const AttendanceListView(),
    ),
    GetPage(
      name: AppRoutes.executiveAttendanceList,
      page: () => const ExecutiveAttendanceListView(),
    ),
    // GetPage(
    //   name: AppRoutes.orderList,
    //   page: () => const OrderListView(),
    // ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
    ),
    // GetPage(
    //   name: AppRoutes.addCompany,
    //   page: () => const AddCompanyView(),
    // ),
    // GetPage(
    //   name: AppRoutes.imagePreview,
    //   page: () => const ImagePreviewView(),
    // ),
    // GetPage(
    //   name: AppRoutes.imagePreviewCam,
    //   page: () => const ImagePreviewCamView(),
    // ),
    // GetPage(
    //   name: AppRoutes.orderPlaced,
    //   page: () => const OrderPlacedView(),
    // ),
    // GetPage(
    //   name: AppRoutes.selectCompany,
    //   page: () => const SelectCompanyView(),
    // ),
    // GetPage(
    //   name: AppRoutes.yourOrder,
    //   page: () => const YourOrderView(),
    // ),
    // GetPage(
    //   name: AppRoutes.cart,
    //   page: () => const CartView(),
    // ),
    // GetPage(
    //   name: AppRoutes.productDetails,
    //   page: () => const ProductDetailsView(),
    // ),
    // GetPage(
    //   name: AppRoutes.productList,
    //   page: () => const ProductListView(),
    // ),
    // GetPage(
    //   name: AppRoutes.selectBrand,
    //   page: () => const SelectBrandView(),
    // ),
    // GetPage(
    //   name: AppRoutes.selectCategory,
    //   page: () => const SelectCategoryView(),
    // ),
    GetPage(
      name: AppRoutes.leaveHistory,
      page: () => const LeaveHistoryView(),
    ),
    GetPage(
      name: AppRoutes.executiveAttendance,
      page: () => const ExecutiveAttendanceView(),
    ),
    GetPage(
      name: AppRoutes.executiveListView,
      page: () => const ExecutiveListView(),
    ),
    // GetPage(
    //   name: AppRoutes.accountModule,
    //   page: () => const AccountModuleView(),
    // ),
    // GetPage(
    //   name: AppRoutes.entry,
    //   page: () => const ListWithFilterView(),
    // ),
    // GetPage(
    //   name: AppRoutes.misOutstanding,
    //   page: () => const MisOutstandingView(),
    // ),
    // GetPage(
    //     name: AppRoutes.misDayBook,
    //     page: () => const PrintReportView(
    //       reportType: ReportType.dayBook,
    //     )),
    // GetPage(
    //   name: AppRoutes.misAccountRegister,
    //   page: () => const PrintReportView(reportType: ReportType.accountRegister),
    // ),
    // GetPage(
    //   name: AppRoutes.misBalanceSheet,
    //   page: () => const PrintReportView(
    //     reportType: ReportType.balanceSheet,
    //   ),
    // ),
    // GetPage(
    //   name: AppRoutes.misProfitLoss,
    //   page: () => const PrintReportView(
    //     reportType: ReportType.profitAndLoss,
    //   ),
    // ),
    // GetPage(
    //   name: AppRoutes.misTrialBalance,
    //   page: () => const PrintReportView(
    //     reportType: ReportType.trialBalance,
    //   ),
    // ),
    // GetPage(
    //   name: AppRoutes.misPendingShipping,
    //   page: () => const PendingShippingView(),
    // ),
    // GetPage(
    //   name: AppRoutes.misAttendanceReport,
    //   page: () => const AttendanceReportView(),
    // ),
    // GetPage(
    //   name: AppRoutes.misOrderReport,
    //   page: () => const MisOrderView(),
    // ),
    // GetPage(
    //   name: AppRoutes.misStockReport,
    //   page: () => const StockReportView(),
    // ),
    // GetPage(
    //   name: AppRoutes.misModule,
    //   page: () => const MisModuleView(),
    // ),
    GetPage(
      name: AppRoutes.changeCompany,
      page: () => const ChangeCompanyView(),
    ),
    // GetPage(
    //   name: AppRoutes.performance,
    //   page: () => const PerformanceView(),
    // ),
    // GetPage(
    //   name: AppRoutes.catalougeListView,
    //   page: () => const CatalougeListView(),
    // ),
    GetPage(
      name: AppRoutes.homeNew,
      page: () => const HomeViewNew(),
    ),
    GetPage(
      name: AppRoutes.approvalHub,
      page: () => const ApprovalHubDashboard(),
    ),
    // GetPage(
    //   name: AppRoutes.taskManagement,
    //   page: () => const TaskListView(),
    // ),
    // GetPage(
    //   name: AppRoutes.documentDownload,
    //   page: () => DownloadDocumentsView(),
    // ),
    // GetPage(
    //   name: AppRoutes.orderFollowup,
    //   page: () => const OrderFollowupView(),
    // ),
    // GetPage(
    //   name: AppRoutes.orderView,
    //   page: () => const OrderView(),
    // ),
    // GetPage(
    //   name: AppRoutes.imageView,
    //   page: () => const ImageView(),
    // ),
    // GetPage(
    //   name: AppRoutes.leadManagement,
    //   page: () => const LeadManagementView(),
    // ),
    // GetPage(
    //   name: AppRoutes.stockReconcillation,
    //   page: () => StockReconciliation(),
    // ),
    // GetPage(
    //   name: AppRoutes.paymentRequestListScreen,
    //   page: () => PaymentRequestListScreen(),
    //   binding: PaymentRequestListBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.paymentRequestDetailScreen,
    //   page: () => const PaymentRequestDetailScreen(),
    //   // no binding — controller manually put before navigation
    // ),
    // GetPage(
    //   name: AppRoutes.mrnScreen,
    //   page: () => MrnListScreen(),
    // ),
    // // GetPage(
    // //   name: AppRoutes.addMRN,
    // //   page: () => AddMRNScreen(),
    // // ),
    // // GetPage(
    // //   name: AppRoutes.materialReceiptScreen,
    // //   page: () => const MaterialReceiptListScreen(),
    // // ),
    // GetPage(
    //   name: AppRoutes.grnScreen,
    //   page: () => GrnListScreen(),
    // ),
    // GetPage(
    //   name: AppRoutes.paymentRequestScreen,
    //   page: () => PaymentRequestScreen(),
    //   binding: PaymentRequestBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.reimbursement,
    //   page: () => ReimbursementListScreen(),
    // ),
  ];
}
