import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_screen_logger.dart';
import 'route_names.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/showroom_selection_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/showroom/presentation/screens/showroom_list_screen.dart';
import '../../features/showroom/presentation/screens/showroom_form_screen.dart';
import '../../features/showroom/presentation/screens/showroom_detail_screen.dart';
import '../../features/users/presentation/screens/user_list_screen.dart';
import '../../features/users/presentation/screens/user_form_screen.dart';
import '../../features/users/presentation/screens/user_detail_screen.dart';
import '../../features/users/presentation/screens/role_list_screen.dart';
import '../../features/users/presentation/screens/role_form_screen.dart';
import '../../features/vehicles/presentation/screens/vehicle_list_screen.dart';
import '../../features/vehicles/presentation/screens/vehicle_form_screen.dart';
import '../../features/vehicles/presentation/screens/vehicle_detail_screen.dart';
import '../../features/inventory/presentation/screens/inventory_list_screen.dart';
import '../../features/inventory/presentation/screens/stock_inward_screen.dart';
import '../../features/inventory/presentation/screens/stock_transfer_screen.dart';
import '../../features/inventory/presentation/screens/vehicle_inventory_detail_screen.dart';
import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/customers/presentation/screens/customer_form_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/lead_pipeline_screen.dart';
import '../../features/customers/presentation/screens/booking_list_screen.dart';
import '../../features/suppliers/presentation/screens/supplier_list_screen.dart';
import '../../features/suppliers/presentation/screens/supplier_form_screen.dart';
import '../../features/suppliers/presentation/screens/supplier_detail_screen.dart';
import '../../features/purchases/presentation/screens/purchase_order_list_screen.dart';
import '../../features/purchases/presentation/screens/purchase_order_form_screen.dart';
import '../../features/purchases/presentation/screens/purchase_order_detail_screen.dart';
import '../../features/sales/presentation/screens/sales_invoice_list_screen.dart';
import '../../features/sales/presentation/screens/sales_invoice_detail_screen.dart';
import '../../features/sales/presentation/screens/booking_wizard_screen.dart';
import '../../features/sales/presentation/screens/delivery_challan_screen.dart';
import '../../features/accounting/presentation/screens/chart_of_accounts_screen.dart';
import '../../features/accounting/presentation/screens/journal_entry_list_screen.dart';
import '../../features/accounting/presentation/screens/journal_entry_form_screen.dart';
import '../../features/accounting/presentation/screens/trial_balance_screen.dart';
import '../../features/finance/presentation/screens/finance_dashboard_screen.dart';
import '../../features/finance/presentation/screens/voucher_list_screen.dart';
import '../../features/finance/presentation/screens/voucher_form_screen.dart';
import '../../features/finance/presentation/screens/outstanding_ledger_screen.dart';
import '../../features/gst/presentation/screens/gst_dashboard_screen.dart';
import '../../features/gst/presentation/screens/gst_rate_config_screen.dart';
import '../../features/gst/presentation/screens/gstr1_report_screen.dart';
import '../../features/gst/presentation/screens/gstr3b_report_screen.dart';
import '../../features/reports/presentation/screens/reports_hub_screen.dart';
import '../../features/reports/presentation/screens/report_viewer_screen.dart';
import '../../features/reports/presentation/screens/document_preview_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/documents/presentation/screens/document_dms_hub_screen.dart';
import '../../features/audit/presentation/screens/audit_trail_screen.dart';
import '../../features/approvals/presentation/screens/approval_hub_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../common/components/app_error_state.dart';

/// MYBIKE Router Configuration
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    observers: [
      AppScreenNavigatorObserver(),
    ],
    redirect: (context, state) {
      AppScreenLogger.logRoute(state.matchedLocation);
      return null;
    },
    routes: _routes,
    errorBuilder: (context, state) => Scaffold(
      body: AppErrorState(
        title: 'Page Not Found',
        message: 'The requested route "${state.uri.path}" could not be found.',
        onBack: () => context.goNamed(RouteNames.dashboard),
        retryLabel: 'Go to Dashboard',
        onRetry: () => context.goNamed(RouteNames.dashboard),
      ),
    ),
  );

  static final List<RouteBase> _routes = [
    // ─── Splash ───
    GoRoute(
      path: '/',
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // ─── Login ───
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),

    // ─── Showroom Selection (Multi-showroom authorized staff) ───
    GoRoute(
      path: '/showroom-selection',
      name: RouteNames.showroomSelection,
      builder: (context, state) => const ShowroomSelectionScreen(),
    ),

    // ─── Dashboard ───
    GoRoute(
      path: '/dashboard',
      name: RouteNames.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),

    // ─── Showroom Management ───
    GoRoute(
      path: '/showrooms',
      name: RouteNames.showrooms,
      builder: (context, state) => const ShowroomListScreen(),
    ),
    GoRoute(
      path: '/showrooms/create',
      name: RouteNames.showroomCreate,
      builder: (context, state) {
        final editId = state.uri.queryParameters['editId'];
        return ShowroomFormScreen(editShowroomId: editId);
      },
    ),
    GoRoute(
      path: '/showrooms/:showroomId',
      name: RouteNames.showroomDetail,
      builder: (context, state) {
        final showroomId = state.pathParameters['showroomId']!;
        return ShowroomDetailScreen(showroomId: showroomId);
      },
    ),

    // ─── User Management ───
    GoRoute(
      path: '/users',
      name: RouteNames.users,
      builder: (context, state) => const UserListScreen(),
    ),
    GoRoute(
      path: '/users/create',
      name: RouteNames.userCreate,
      builder: (context, state) {
        final editId = state.uri.queryParameters['editId'];
        return UserFormScreen(editUserId: editId);
      },
    ),
    GoRoute(
      path: '/users/:userId',
      name: RouteNames.userDetail,
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return UserDetailScreen(userId: userId);
      },
    ),

    // ─── Role Management ───
    GoRoute(
      path: '/roles',
      name: RouteNames.roles,
      builder: (context, state) {
        final action = state.uri.queryParameters['action'];
        final roleId = state.uri.queryParameters['roleId'];

        if (action == 'create') {
          return const RoleFormScreen();
        }
        if (action == 'edit' && roleId != null) {
          return RoleFormScreen(editRoleId: roleId);
        }

        return const RoleListScreen();
      },
    ),

    // ─── Vehicle Master ───
    GoRoute(
      path: '/vehicles',
      name: RouteNames.vehicles,
      builder: (context, state) => const VehicleListScreen(),
    ),
    GoRoute(
      path: '/vehicles/create',
      name: RouteNames.vehicleCreate,
      builder: (context, state) {
        final editId = state.uri.queryParameters['editId'];
        return VehicleFormScreen(modelId: editId);
      },
    ),
    GoRoute(
      path: '/vehicles/:vehicleId',
      name: RouteNames.vehicleDetail,
      builder: (context, state) {
        final vehicleId = state.pathParameters['vehicleId']!;
        return VehicleDetailScreen(modelId: vehicleId);
      },
    ),
    GoRoute(
      path: '/vehicles/:vehicleId/edit',
      builder: (context, state) {
        final vehicleId = state.pathParameters['vehicleId']!;
        return VehicleFormScreen(modelId: vehicleId);
      },
    ),

    // ─── Inventory Management ───
    GoRoute(
      path: '/inventory',
      name: RouteNames.inventory,
      builder: (context, state) => const InventoryListScreen(),
    ),
    GoRoute(
      path: '/inventory/inward',
      name: RouteNames.stockInward,
      builder: (context, state) => const StockInwardScreen(),
    ),
    GoRoute(
      path: '/inventory/transfer',
      name: RouteNames.stockTransfer,
      builder: (context, state) => const StockTransferScreen(),
    ),
    GoRoute(
      path: '/inventory/:vehicleId',
      builder: (context, state) {
        final vehicleId = state.pathParameters['vehicleId']!;
        return VehicleInventoryDetailScreen(vehicleId: vehicleId);
      },
    ),

    // ─── Customer Management ───
    GoRoute(
      path: '/customers',
      name: RouteNames.customers,
      builder: (context, state) => const CustomerListScreen(),
    ),
    GoRoute(
      path: '/customers/create',
      name: RouteNames.customerCreate,
      builder: (context, state) {
        final editId = state.uri.queryParameters['editId'];
        return CustomerFormScreen(editCustomerId: editId);
      },
    ),
    GoRoute(
      path: '/customers/:customerId',
      name: RouteNames.customerDetail,
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        return CustomerDetailScreen(customerId: customerId);
      },
    ),

    // ─── Lead Pipeline ───
    GoRoute(
      path: '/leads',
      builder: (context, state) => const LeadPipelineScreen(),
    ),

    // ─── Bookings ───
    GoRoute(
      path: '/bookings',
      name: RouteNames.bookings,
      builder: (context, state) => const BookingListScreen(),
    ),

    // ─── Sales & Invoicing ───
    GoRoute(
      path: '/sales',
      name: RouteNames.sales,
      builder: (context, state) => const SalesInvoiceListScreen(),
    ),
    GoRoute(
      path: '/sales/create',
      name: RouteNames.saleCreate,
      builder: (context, state) => const BookingWizardScreen(),
    ),
    GoRoute(
      path: '/sales/:invoiceId',
      name: RouteNames.saleDetail,
      builder: (context, state) {
        final invoiceId = state.pathParameters['invoiceId']!;
        return SalesInvoiceDetailScreen(invoiceId: invoiceId);
      },
    ),
    GoRoute(
      path: '/sales/:invoiceId/delivery',
      builder: (context, state) {
        final invoiceId = state.pathParameters['invoiceId']!;
        return DeliveryChallanScreen(invoiceId: invoiceId);
      },
    ),

    // ─── Procurement: Suppliers ───
    GoRoute(
      path: '/suppliers',
      name: RouteNames.suppliers,
      builder: (context, state) => const SupplierListScreen(),
    ),
    GoRoute(
      path: '/suppliers/create',
      name: RouteNames.supplierCreate,
      builder: (context, state) {
        final editId = state.uri.queryParameters['editId'];
        return SupplierFormScreen(editSupplierId: editId);
      },
    ),
    GoRoute(
      path: '/suppliers/:supplierId',
      name: RouteNames.supplierDetail,
      builder: (context, state) {
        final supplierId = state.pathParameters['supplierId']!;
        return SupplierDetailScreen(supplierId: supplierId);
      },
    ),

    // ─── Procurement: Purchase Orders ───
    GoRoute(
      path: '/purchases',
      name: RouteNames.purchases,
      builder: (context, state) => const PurchaseOrderListScreen(),
    ),
    GoRoute(
      path: '/purchases/create',
      name: RouteNames.purchaseCreate,
      builder: (context, state) {
        final editId = state.uri.queryParameters['editId'];
        return PurchaseOrderFormScreen(editPurchaseId: editId);
      },
    ),
    GoRoute(
      path: '/purchases/:purchaseId',
      name: RouteNames.purchaseDetail,
      builder: (context, state) {
        final purchaseId = state.pathParameters['purchaseId']!;
        return PurchaseOrderDetailScreen(purchaseId: purchaseId);
      },
    ),

    // ─── Accounting Foundation ───
    GoRoute(
      path: '/accounting',
      name: RouteNames.accounting,
      builder: (context, state) => const ChartOfAccountsScreen(),
    ),
    GoRoute(
      path: '/accounting/chart-of-accounts',
      name: RouteNames.chartOfAccounts,
      builder: (context, state) => const ChartOfAccountsScreen(),
    ),
    GoRoute(
      path: '/accounting/journals',
      name: RouteNames.journal,
      builder: (context, state) => const JournalEntryListScreen(),
    ),
    GoRoute(
      path: '/accounting/journals/create',
      name: RouteNames.journalCreate,
      builder: (context, state) => const JournalEntryFormScreen(),
    ),
    GoRoute(
      path: '/accounting/trial-balance',
      name: RouteNames.trialBalance,
      builder: (context, state) => const TrialBalanceScreen(),
    ),

    // ─── Finance Module ───
    GoRoute(
      path: '/finance',
      name: RouteNames.finance,
      builder: (context, state) => const FinanceDashboardScreen(),
    ),
    GoRoute(
      path: '/finance/vouchers',
      name: RouteNames.vouchers,
      builder: (context, state) {
        final type = state.uri.queryParameters['type'];
        return VoucherListScreen(initialType: type);
      },
    ),
    GoRoute(
      path: '/finance/vouchers/create',
      name: RouteNames.voucherCreate,
      builder: (context, state) {
        final type = state.uri.queryParameters['type'];
        return VoucherFormScreen(initialType: type);
      },
    ),
    GoRoute(
      path: '/finance/outstandings',
      name: RouteNames.outstandings,
      builder: (context, state) => const OutstandingLedgerScreen(),
    ),
    GoRoute(
      path: '/finance/payments',
      name: RouteNames.payments,
      builder: (context, state) => const VoucherListScreen(initialType: 'payment'),
    ),
    GoRoute(
      path: '/finance/receipts',
      name: RouteNames.receipts,
      builder: (context, state) => const VoucherListScreen(initialType: 'receipt'),
    ),
    GoRoute(
      path: '/finance/expenses',
      name: RouteNames.expenses,
      builder: (context, state) => const VoucherListScreen(initialType: 'expense'),
    ),

    // ─── GST & Tax Module ───
    GoRoute(
      path: '/gst',
      name: RouteNames.gstDashboard,
      builder: (context, state) => const GstDashboardScreen(),
    ),
    GoRoute(
      path: '/gst/rates',
      name: RouteNames.gstRates,
      builder: (context, state) => const GstRateConfigScreen(),
    ),
    GoRoute(
      path: '/gst/gstr-1',
      name: RouteNames.gstr1Report,
      builder: (context, state) => const Gstr1ReportScreen(),
    ),
    GoRoute(
      path: '/gst/gstr-3b',
      name: RouteNames.gstr3bReport,
      builder: (context, state) => const Gstr3bReportScreen(),
    ),

    // ─── Reports & Statements Module ───
    GoRoute(
      path: '/reports',
      name: RouteNames.reports,
      builder: (context, state) => const ReportsHubScreen(),
    ),
    GoRoute(
      path: '/reports/:reportType',
      name: 'report-viewer',
      builder: (context, state) {
        final reportType = state.pathParameters['reportType']!;
        return ReportViewerScreen(reportType: reportType);
      },
    ),
    GoRoute(
      path: '/document/preview',
      name: RouteNames.documentPreview,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final title = extra?['title'] as String? ?? 'Document Preview';
        final filename = extra?['filename'] as String?;
        final pdfBytes = extra?['pdfBytes'];
        return DocumentPreviewScreen(
          title: title,
          filename: filename,
          pdfBytes: pdfBytes,
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      name: RouteNames.notifications,
      builder: (context, state) => const NotificationCenterScreen(),
    ),
    GoRoute(
      path: '/documents',
      name: RouteNames.documents,
      builder: (context, state) => const DocumentDmsHubScreen(),
    ),
    GoRoute(
      path: '/audit-logs',
      name: RouteNames.auditLogs,
      builder: (context, state) => const AuditTrailScreen(),
    ),
    GoRoute(
      path: '/approvals',
      name: RouteNames.approvals,
      builder: (context, state) => const ApprovalHubScreen(),
    ),

    // ─── Administration ───
    GoRoute(
      path: '/settings',
      name: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ];
}
