class ApiMethods {
  static final ApiMethods _apiMethods = ApiMethods._internal();

  factory ApiMethods() {
    return _apiMethods;
  }

  ApiMethods._internal();

  String login                = 'Login';
  String updateProfile        = 'UserProfile/userProfile';
  String executiveDropDown    = 'ExecutiveReportPerson/ExecutiveReportPersonList';
  String mobileOtpVerify      = 'MobileVerify/mobileOtpVerify';
  String updateToken          = 'updatetoken/usercurrenttoken';
  String menuDetails          = 'Menu/menuDetails';
  String menuUserNew          = 'Userwisemenu/usermenu';
  //String dashboardDetails = 'Dashboard/dashboardDetails';
  String dashboardDetails     = 'dashboardnew/dashboardDetailsnew';
  String dashboardPendency    = 'dashboardnew/dashboardpendency';
  String dashboardGraphs      = 'dashboardnew/dashboardgraphs';
  // String attendanceSummary = 'AttendanceSummery/attendanceDetails';
  String attendanceSummary    = 'AttendanceSummerynew/attendanceDetailsnew';
  String attendanceList       = 'AttendanceList/attendanceList';
  // String markAttendance = 'MarkAttendance/markAttendance';
  String markAttendance       = 'MarkAttendancenew/markAttendancenew';
  String logout               = 'Logout/userLogout';
  // String applyLeave = 'Applyleave/leavapply';
  String applyLeave           = 'Applyleavenew/leavapplynew';
  String getLeaveData =
      'appandreject/listofleav'; // Approved and Rejected manage by status in param
  // String leaveHistory = 'leavehistory/getleavhistory';
  String leaveHistory         = 'leavehistorynew/getleavhistorynew';
  String pendingLeaveList     = 'pendingleavelist/leavlistforapprovedandreject';
  String updateLeaveStatus    =
      'approveleavprocess/listofleav'; // Approved and Rejected manage by status in param
  String cancelLeave          = 'leavecancel/cancelleave'; // applicant cancels own pending leave
  String leaveApprovalAccess  = 'leaveapproval/access'; // can this user approve leaves? (menu 2388)
  String executiveListWithLatAndLong =
      'Executivelistwithlatlong/executivelistforlatlong';
  String executiveOrderList   =
      'Executiveorderlistwithbranch/orderlistexecutivewithbranch';
  String partyDropdownNew     = 'agentparty/getagentpartyname';
  String validateUserForOrder = 'validateuserfororder/validateuser';
  String matchUserLocation    = 'checkuserlocation/validateuserlocation';
  String singleOrderDetail    = 'orderdetail/orderwithproduct';
  String getOrderPdf          = 'orderpdf/getorderpdf';

  String updateOrderStatus    = 'changeorderstatus/updateorderstatus';
  String partyBalanceDetail   = 'Partybalancedetail/partybalance';
  String locationRouteSave    = 'locationroute/locationsave';
  String executiveDayLocation = 'executivedaylocation/daylocation';
  String forgotPassword       = 'forgotpassword/forgototpget';
  String forgotOtpVerify      = 'forgotpassotpverify/forgototpverify';
  String resetPassword        = 'resetpasswod/resetpass';
  String brandDataList        = 'brandlistnewwithbranch/brandwithimagewithbranch';
  String brandList            = 'brandlistnew/brandwithimage';

  String categoryBannerImage =
      'categorybannerwithbranch/categorybannerlistwithbranch';
  // String categoryBannerImage = 'categorybanner/categorybannerlist';
  String subcategoryList = 'subcategorywithbranch/subcategorylistwithbranch';

  String categoryBrandDataList =
      'categorybrandwithbranch/categorylistbrandwithbranch';
  String rackNoList = 'rackno/getrackno';
  String stockReconciliationReportDetails =
      'stockreconcilation/getstockreportforreconcilation';
  String stockReconciliationSubmit = 'reconcileentry/savereconcileentry';

  String productDetails       = 'productdetail/getproductdetail';
  String unitDetails          = 'unitlist/getunit';
  String itemListVariant      = 'itemvarient/itemlistvarient';
  String addPartyOrCompany    = 'Addparty/addpartydetail';
  String addPartyOrCompanyNew = 'Addpartynew/addpartydetailnew';
  String getCartDetail        = 'cartdetail/getcarddetail';

  ///  Add Costomer
  String addContactsView = 'partycontactdetail/getpartycontact';
  String addContactsDetails = 'savepartycontact/enterpartycontact';
  String designationDropDown = 'designationlist/desinationdropdown';

  /// task management
  //String assignTask =  'assigntaskentry/assigntask';
  //String taskList =  'tasklistwithfilter/gettasklist';
  String taskList          = 'TasksByRole';
  String taskUpdateDetails = 'SaveTaskFollowup';
  String taskDetails       = 'GetTaskDetail';
  String saveTaskFollowup  = 'SaveTaskFollowup';
  String createDirectTask  = 'CreateDirectTask';
  String taskDropdown      = 'TaskDropdown';

  /// task module (new mobile API — taskmaster + TaskComments)
  String taskListV2      = 'task/list';
  String taskDetailV2    = 'task/detail';
  String taskDropdownsV2 = 'task/dropdowns';
  String taskCreateV2    = 'task/create';
  String taskFollowupV2  = 'task/addfollowup';
  String taskStatusV2    = 'task/updatestatus';

  /// push notifications — the API does not expose this yet, see
  /// docs/PUSH_NOTIFICATIONS_BACKEND_SPEC.md. Guarded by
  /// TaskNotificationService.backendSupportsPush.
  String registerPushToken = 'notification/registertoken';

  /// change company
  String companylist = 'companylist/getcompany';
  String branchlist = 'branchlist/getbranch';
  String financialYear = 'financialyear/getfinancialyear';

  /// DownloadDocument
  String downloadDocumentType           = 'documentnamedropdown/getdocumentname';
  String downloadDocumentListWithFilter =
      'documentlistfordownload/getdocumentlistwithfilter';
  String downloadDocumentPrint          = 'printdocument/getdocumenturl';

  /// Change Company

  String performance = 'performannce/getexecutiveperformance';

  /// Graph

  String getsalesreceiptgraphController =
      'salesreceiptgraph/getsalesreceiptgraphController';
  String getmonthwisesales    = 'monthlysalesinvoice/getmonthwisesales';
  String getinvoicedetail     = 'invoicedetail/getinvoicedetail';
  String showperformancegraph = 'performancegraph/showperformancegraph';
  String incentivegrapdetail  = 'incentivegrap/incentivegrapdetail';

  /// OrderFollowup
  String orderFollowupList    = 'orderfollowuplist/getorderfollowuplistwithfilter';
  String orderFollowupDetails = 'orderfollowupdetail/getorderfollowupdetail';
  String orderFollowupSave    = 'orderfollowupsave/saveorderfollowup';

  /// paymentFollowup

  String paymentFollowupList    =
      'paymentfollowuplist/getpaymentfollowuplistwithfilter';
  String paymentFollowupDetails =
      'paymentfollowupdetail/getpaymentfollowupdetail';
  String paymentFollowupSave    = 'orderfollowupsave/saveorderfollowup';

  /// Shipping Management

  String shippingUpdateDetails = 'updateshippingdetail/updateshipping';
  String shippingStatus        = 'shippingstatus/getshippingstatus';
  String shippingDetailsList   =
      'shippingdetailwithfilter/getpendingshippingwithfilter';
  String updateShippingValue   = 'singleshippingdetail/getsingleshippingdetail';

  //String addToCart  = 'addtocart/addcart';
  String addToCart = 'addtocartnew/addcartnew';

  String removeFromCart       = 'removeitem/removecartitem';
  String removeItem           = 'removeitem/removecartitem';
  String placeOrder           = 'placeorder/orderentry';
  String updateCart           = 'cardqtyupdate/productqtychange';
  String updateCartDecimalQty = 'cardqtyupdatedecimal/productqtychangedecimal';
  String cartCount            = 'cartcount/getcartcount';

  /// Approval
  /// Approval Document
  String approvalDocument = 'documentapprovalprint/printdocumentapproval';

  /// UnApproval Count
  String unApprovalCount = 'unapprovedcount/totalcount';

  /// Approval List
  String approvalList         = 'GetApprovalList';
  String approvaldetails      = 'GetApprovalDetail';
  String approvalupdatestatus = 'SubmitApproval';

  /// Approval Filter Screen
  String documentname   = 'Document/Documentdrpdon';
  String clientNameList = 'Allclientlistfilter/clientdrpdon';
  String itemList       = 'itemwithbranch/itemlistwithbranch';
  String statusList     = 'ApprovalStatus/Statusdrpdon';
  String vendorList     = 'Vendor/partyvendordrpdon';

  ///Visit Plan
  /// -VisitPlan Screen
  String allVisitList = 'visit/list';

  /// -Visitplan Detail Screen
  String visitPlanDetail   = 'visit/detail';
  String visitCheckIn      = 'Visitcheckin/Visitcheckindetail';
  String visitPlanCheckout = 'visitplancheckout/Visitcheckoutdetail';

  /// -Visitplan Filter Screen
  String distanceDetails   = "Distancefilterdropdown/getdistancefilter";
  String executiveListData = 'ExecutiveReportPerson/ExecutiveReportPersonList';
  String stateNameList     = 'Statename/statenamelist';
  String areaNameList      = 'Arealist/Areaname';
  String cityNameList      = 'Cityname/citylist';

  /// -Stack Tacking Screen
  String stockCategory   = 'category/categorylist';
  String productListItem = 'itemwithbranch/itemlistwithbranch';
  String stockTaking     = 'Stocktaking/stocktakingin';

  /// -New Visit Planing Screen
  String partyDropdown                = 'allpartylist/partydrpdon'; //till not used
  String searchAreaWiseClientForVisit =
      'searchareawiseclientforvisit/searchclientforviste';
  String addToVisit                   = 'Addvisitlist/addtovisit';

  /// -New Visit Planing Filter Screen
  String nearByList = 'Nearbydistance/Nearbylist';

  /// -Preview Screen
  String previewVisitList = 'Addtovistlist/addtovisitlist';
  String deleteVisitList  = 'deletevisitfromlist/deletevisitlist';
  String saveVisitEntry   = 'Savevisitentry/savevisit';

  /// -Customer List Screen/party list
  String customersList          = 'partydetail/Fullpartydetail';
  String partyDetailsWithBranch =
      'partydetailwithbranch/Fullpartydetailwithbranch';
  String showAccountCustomer    = 'AccountCustomer/showAccountCustomer';
  String getbranchandsite       = 'branchandsite/getbranchandsite';
  String getapprovername        = 'approvername/getapprovername';

  ///Payment Request
  //String paymentrequestentry        = 'paymentrequest/paymentrequestentry';
  //String paymentRequestList         = 'paymentrequest/paymentrequestlist';
  //String updatePaymentRequestStatus = 'paymentrequest/updatepaymentrequest';

  String paymentRequestList         = 'GetPaymentRequestList';
  String paymentrequestentry        = 'SavePaymentRequest';
  String paymentRequestDropdown     = 'PaymentRequestDropdown';
  String updatePaymentRequestStatus = 'SavePaymentRequest';

  String updateCustomerLocation = 'updatepartylocation/updatelocation';
  String updateCustomerRemark   = 'updatepartyremarks/clientremark';
  String getDsrPdf              = 'executivedsr/getdsrpdf';

  String paymentEntrySubmit     = 'Voucherentry/uservoucherentry';
  String collectionEntrySubmit  = 'Voucherentry/uservoucherentry';
  String showCashAndBankAccount = 'Cashandbankaccount/showCashandbankaccount';

  ///new
  ///Collection
  String listWithFilter  = 'Accountentrylist/showaccountentrydetail';
  String collectionEntry = 'Voucherentry/uservoucherentry';
  String customerList    = 'AccountCustomer/showAccountCustomer';

  ///Expenses
  String expensesHead       = 'Expenseslist/showExpenseshead';
  String contraEntry        = 'ContraEntry/userContraentry';
  String fromAccount        = 'Cashandbankaccount/showCashandbankaccount';
  String journalEntry       = 'journalentry/userjournalentry';
  String debitCreditAccount = 'debitandcreditledger/showdebitandcreditledger';

  String transactionList    =
      'Partylistoftransaction/showlistoftransactionofparty';
  String partyOutstanding   = 'Partyoutstadinglist/showpartyoutstanding';
  String printPartyLedger   = 'printledger/printledgerreport';

  String voucherEntrySubmit = 'Voucherentry/uservoucherentry';

  ///MIS module

  String getParentGroup          = 'parentgroup/getparentgroup';
  String getPartyForParent       = 'partyforparentgroup/getpartyforparent';
  String showAllPartyOutstanding = 'alloutstanding/showallpartyoutstanding';
  String printAccountMisReport   =
      'Printallaccountingreport/printaccountmisreport';
  String printAccountRegisterMisReport =
      'Printaccountregister/printaccountregistermisreport';
  String getAccountRegisterLedger =
      'Accountregisterledger/getaccountregisterledger';
  String getShippingStatus       = 'shippingstatus/getshippingstatus';
  String getPendingShipping      = 'pendingshipping/getpendingshipping';
  String getAttendanceReport     = 'attendencereport/getattandencereport';
  String getOrderReport          = 'orderreport/getorderreport';
  String orderReport             = 'orderreport/getorderreport';
  String genericReport           = 'report/getreport';
  String genericReportDetail     = 'report/getreportdetail';
  String getStoreName            = 'storename/getstorename';
  String getStockReport          = 'stockreport/getstockreport';
  String stockEnquiryItems       = 'stockenquiry/items';
  String stockEnquiryGodownWise  = 'stockenquiry/godownwise';

  ///Image Stamping
  String executiveReportPersonListForeImageStamping =
      'ExecutiveReportPerson/ExecutiveReportPersonList';
  String categoryListForeImageStamping = 'category/categorylist';
  String imageList                     = 'executiveimagelist/imagelist';
  // String singleimagedetail          = 'imagedetail/singleimagedetail'; TODO :- not using this api
  String saveImageStamping             = 'imagestamppingsave/saveimagestampping';

  /// category catalouge

  String categoryCatalouge = 'categorywisecatalogue/showcategorywisecatalogue';
  String categoryNewList   = "categorywithbranch/categorylistwithbranch";

  /// sales invoice

  String salesInvoice      = "salesinvoicemis/getsalesinvoicelist";

  /// Salary Sleep

  String downloadSalarySleep = "Downloadsalaryslip/showsalarylist";



  ///MRN module
  String getMrnDropdownList    = 'Getmrndropdownlist';
  String getPendingPo          = 'getpendingpo';
  String processPendingPoList  = 'processpendingpolist';
  String saveMrnEntry          = 'savemrnentry';
  String getItemDetail         = 'itemdetail';
  String getMrnList            = 'getmrnlist';
  String getMrnDetail          = 'mrnfulldetail';
  String getDependentAllDetail = 'getdependentalldetail';


  ///GRN Module
  String getGrnDetail       = 'grnfulldetailController';
  String getGrnList         = 'getgrnlist';
  String saveGrnEntry       = 'savegrnentry';
  String getGrnDropdownList = 'Getmrndropdownlist';
  String getGrnItemDetail   = 'itemdetail';
  String getAddress         = 'getledgeraddressandvaluepercent';

  ///MRN QC Module
  String getMrnQcList        = 'getmrnlist';
  String getMrnQcDetail      = 'mrnandqcdetail';
  String saveQcEntry         = 'saveqcentry';
//  static const String getPendingPoItems = 'getpendingpo';

  /// Indent Module
  String getIndentList         = 'getindentlist';
  String getIndentDetail       = 'indentfulldetail';
  String getIndentDropdownList = 'indentandissuedropdown';
  String saveIndent            = 'createindent';
  String getIndentItemStock    = '';

  /// Lead Management (ERP-native module)
  String leadDashboard    = 'lead/dashboard';
  String leadItems        = 'lead/items';
  String leadFormDropdowns = 'lead/formdropdowns';
  String leadCompanies    = 'lead/companies';
  String leadItemMaster   = 'lead/itemmaster';
  String leadPartyDetail  = 'lead/partydetail';
  String leadSave         = 'lead/save';
  String leadList         = 'lead/list';
  String leadCreate       = 'lead/create';
  String leadAddFollowup  = 'lead/addfollowup';
  String leadAddTask      = 'lead/addtask';
  String leadAddNote      = 'lead/addnote';
  String leadSaveEstimate = 'lead/saveestimate';
  String leadSaveQuotation = 'lead/savequotation';
  String leadFollowups    = 'lead/followups';
  String saleorderList    = 'saleorder/list';
  String saleorderDetail  = 'saleorder/detail';
  String saleorderFormDropdowns = 'saleorder/formdropdowns';
  String saleorderPartyNames    = 'saleorder/partynames';
  String saleorderStoreContacts = 'saleorder/storecontacts';
  String saleorderItemMaster    = 'saleorder/itemmaster';
  String saleorderPartyDetail   = 'saleorder/partydetail';
  String saleorderSave          = 'saleorder/save';
  String saleorderCreateItem    = 'saleorder/createitem';

  /// Tap Card (app-native business-card wallet, dbo.MobileTapCard).
  /// Card images go through the SHARED uploadReimbursementFile endpoint below —
  /// there is no tapcard-specific upload.
  String tapcardList   = 'tapcard/list';
  String tapcardSave   = 'tapcard/save';
  String tapcardDelete = 'tapcard/delete';

  ///Purchase Order
  String purchaseorderList          = 'purchaseorder/list';
  String purchaseorderDetail        = 'purchaseorder/detail';
  String purchaseorderFormDropdowns = 'purchaseorder/formdropdowns';
  String purchaseorderPartyNames    = 'purchaseorder/partynames';
  String purchaseorderStoreContacts = 'purchaseorder/storecontacts';
  String purchaseorderItemMaster    = 'purchaseorder/itemmaster';
  String purchaseorderPartyDetail   = 'purchaseorder/partydetail';
  String purchaseorderSave          = 'purchaseorder/save';
  String purchaseorderCreateItem    = 'purchaseorder/createitem';

  /// Inline "+ Add" on form dropdowns (Delivery Type / Transport Name / Freight
  /// Mode / Transaction Type / Transport Mode). Shared by PO + Performa: they are
  /// all one master (ERPMasterDB `parameter`), keyed by parentid.
  String commonAddParameter = 'common/addparameter';
  // Pending Indent for PO: list of approved indents not yet fully converted, and
  // the seed payload for creating a PO from one.
  String purchaseorderPendingIndents = 'purchaseorder/pendingindents';
  String purchaseorderIndentForPo    = 'purchaseorder/indentforpo';

  ///Issue Item
  String getIssueItemDropdown = 'indentandissuedropdown';
  String getPendingIndentList     = '';
  String processPendingIndentList = '';
  String saveIssueItem       = '';
  String getIssueItemDetail       = '';
  String getIssueItemList    = 'api/IssueItem/GetIssueItemList';

}