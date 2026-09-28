import 'package:flutter/foundation.dart';
import 'accounting_management_service.dart';
import 'sales_management_service.dart';
import 'supplier_management_service.dart';
import 'supabase_service.dart';
import '../config/supabase_config.dart';
import '../../features/finance/domain/entities/finance_voucher_entity.dart';
import '../../features/finance/domain/entities/party_outstanding_entity.dart';
import '../../features/accounting/domain/entities/journal_entry_entity.dart';
import '../../features/accounting/domain/entities/journal_line_entity.dart';

/// Finance Management Service
///
/// Handles Cash & Bank accounts, Payments, Receipts, Contra transfers,
/// Credit/Debit Notes, Outstandings aging analysis, and real-time
/// synchronization with the Double-Entry General Ledger directly backed by Supabase.
class FinanceManagementService {
  FinanceManagementService._();
  static final FinanceManagementService instance = FinanceManagementService._();

  final AccountingManagementService _accountingService = AccountingManagementService.instance;

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  void resetDevData() {}

  // ═══════════════════════════════════════════════════════════════════
  // CASH & BANK BALANCES (QUERIED DIRECTLY FROM GENERAL LEDGER)
  // ═══════════════════════════════════════════════════════════════════

  /// Get liquid asset balances (Cash and Bank accounts)
  Future<Map<String, dynamic>> getLiquidBalances({String? showroomId}) async {
    final accounts = await _accountingService.fetchAccounts(showroomId: showroomId);
    
    final cashAccounts = accounts.where((a) => a.subType == 'cash').toList();
    final bankAccounts = accounts.where((a) => a.subType == 'bank').toList();

    final totalCash = cashAccounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance);
    final totalBank = bankAccounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance);
    final totalLiquid = totalCash + totalBank;

    return {
      'totalLiquid': totalLiquid,
      'totalCash': totalCash,
      'totalBank': totalBank,
      'cashAccounts': cashAccounts,
      'bankAccounts': bankAccounts,
    };
  }

  // ═══════════════════════════════════════════════════════════════════
  // VOUCHER MANAGEMENT & AUTOMATIC DOUBLE-ENTRY POSTING
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch vouchers with optional filtering from Supabase
  Future<List<FinanceVoucherEntity>> fetchVouchers({
    String? showroomId,
    String? voucherType,
    String? status,
    String? search,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('finance_vouchers').select(
        '*, showrooms(name), src:source_account_id(account_name), dest:destination_account_id(account_name)',
      );

      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      if (voucherType != null && voucherType.isNotEmpty && voucherType != 'all') {
        query = query.eq('voucher_type', voucherType);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }

      final response = await query.order('voucher_date', ascending: false);
      final rawList = response as List;

      final results = rawList.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final sh = row['showrooms'] as Map<String, dynamic>?;
        if (sh != null) row['showroom_name'] = sh['name'];

        final src = row['src'] as Map<String, dynamic>?;
        if (src != null) row['source_account_name'] = src['account_name'];

        final dest = row['dest'] as Map<String, dynamic>?;
        if (dest != null) row['destination_account_name'] = dest['account_name'];

        return FinanceVoucherEntity(
          id: row['id'] as String,
          showroomId: row['showroom_id'] as String? ?? '',
          voucherNumber: row['voucher_number'] as String? ?? '',
          voucherType: row['voucher_type'] as String? ?? 'payment',
          voucherDate: DateTime.tryParse(row['voucher_date']?.toString() ?? '') ?? DateTime.now(),
          partyType: row['party_type'] as String? ?? 'other',
          partyId: row['party_id'] as String?,
          partyName: row['party_name'] as String? ?? '',
          partyPhone: row['party_phone'] as String?,
          paymentMode: row['payment_mode'] as String? ?? 'bank_transfer',
          sourceAccountId: row['source_account_id'] as String?,
          destinationAccountId: row['destination_account_id'] as String?,
          amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
          taxDeductedTds: (row['tax_deducted_tds'] as num?)?.toDouble() ?? 0.0,
          netAmount: (row['net_amount'] as num?)?.toDouble() ?? 0.0,
          referenceNumber: row['reference_number'] as String?,
          referenceDate: row['reference_date'] != null ? DateTime.tryParse(row['reference_date'].toString()) : null,
          bankName: row['bank_name'] as String?,
          narration: row['narration'] as String? ?? '',
          status: row['status'] as String? ?? 'posted',
          journalEntryId: row['journal_entry_id'] as String?,
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          // DB column is camelCase 'updatedAt', not snake_case 'updated_at'
          updatedAt: DateTime.tryParse((row['updatedAt'] ?? row['updated_at'])?.toString() ?? '') ?? DateTime.now(),
          showroomName: row['showroom_name'] as String?,
          sourceAccountName: row['source_account_name'] as String?,
          destinationAccountName: row['destination_account_name'] as String?,
        );
      }).toList();

      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        return results.where((v) =>
            v.voucherNumber.toLowerCase().contains(s) ||
            v.partyName.toLowerCase().contains(s) ||
            (v.referenceNumber?.toLowerCase().contains(s) ?? false)).toList();
      }

      return results;
    } catch (e) {
      debugPrint('FinanceManagementService.fetchVouchers error: $e');
      return [];
    }
  }

  /// Create and post a Financial Voucher with automatic General Ledger integration
  Future<FinanceVoucherEntity> createVoucher(
    FinanceVoucherEntity voucher, {
    bool autoPostToGL = true,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');
    if (voucher.amount <= 0) {
      throw ArgumentError('Voucher amount must be strictly positive.');
    }

    final prefix = _getVoucherPrefix(voucher.voucherType);
    final voucherNumber = voucher.voucherNumber.isNotEmpty
        ? voucher.voucherNumber
        : '$prefix-${DateTime.now().millisecondsSinceEpoch}';

    String? createdJournalId;

    // Automatic GL entry
    if (autoPostToGL && voucher.sourceAccountId != null && voucher.destinationAccountId != null) {
      try {
        final glEntry = await _postCorrespondingJournalEntry(
          voucherNumber: voucherNumber,
          voucher: voucher,
        );
        createdJournalId = glEntry.id;
      } catch (e) {
        debugPrint('Note creating GL entry for voucher: $e');
      }
    }

    final payload = {
      'showroom_id': voucher.showroomId,
      'voucher_number': voucherNumber,
      'voucher_type': voucher.voucherType,
      'voucher_date': voucher.voucherDate.toIso8601String().substring(0, 10),
      'party_type': voucher.partyType,
      'party_id': voucher.partyId,
      'party_name': voucher.partyName,
      'party_phone': voucher.partyPhone,
      'payment_mode': voucher.paymentMode,
      'source_account_id': voucher.sourceAccountId,
      'destination_account_id': voucher.destinationAccountId,
      'amount': voucher.amount,
      'tax_deducted_tds': voucher.taxDeductedTds,
      'net_amount': voucher.netAmount,
      'reference_number': voucher.referenceNumber,
      'reference_date': voucher.referenceDate?.toIso8601String().substring(0, 10),
      'bank_name': voucher.bankName,
      'narration': voucher.narration,
      'status': voucher.status,
      'journal_entry_id': createdJournalId,
    };

    final res = await SupabaseService.client!
        .from('finance_vouchers')
        .insert(payload)
        .select()
        .single();

    return voucher.copyWith(
      id: res['id'] as String,
      voucherNumber: voucherNumber,
      journalEntryId: createdJournalId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<JournalEntryEntity> _postCorrespondingJournalEntry({
    required String voucherNumber,
    required FinanceVoucherEntity voucher,
  }) async {
    final srcAcct = await _accountingService.fetchAccountById(voucher.sourceAccountId!);
    final destAcct = await _accountingService.fetchAccountById(voucher.destinationAccountId!);

    if (srcAcct == null || destAcct == null) {
      throw ArgumentError('Specified source or destination account does not exist in Chart of Accounts.');
    }

    String debitAccountId;
    String debitAccountName;
    String debitAccountCode;
    String debitAccountType;

    String creditAccountId;
    String creditAccountName;
    String creditAccountCode;
    String creditAccountType;

    switch (voucher.voucherType) {
      case 'receipt':
        debitAccountId = destAcct.id;
        debitAccountName = destAcct.accountName;
        debitAccountCode = destAcct.accountCode;
        debitAccountType = destAcct.accountType;

        creditAccountId = srcAcct.id;
        creditAccountName = srcAcct.accountName;
        creditAccountCode = srcAcct.accountCode;
        creditAccountType = srcAcct.accountType;
        break;

      case 'payment':
      case 'expense':
      case 'contra':
      case 'credit_note':
      case 'debit_note':
      default:
        debitAccountId = destAcct.id;
        debitAccountName = destAcct.accountName;
        debitAccountCode = destAcct.accountCode;
        debitAccountType = destAcct.accountType;

        creditAccountId = srcAcct.id;
        creditAccountName = srcAcct.accountName;
        creditAccountCode = srcAcct.accountCode;
        creditAccountType = srcAcct.accountType;
        break;
    }

    final lines = [
      JournalLineEntity(
        id: '',
        journalEntryId: '',
        accountId: debitAccountId,
        accountCode: debitAccountCode,
        accountName: debitAccountName,
        accountType: debitAccountType,
        debitAmount: voucher.netAmount,
        creditAmount: 0.0,
        description: '${voucher.typeLabel} via ${voucher.paymentModeLabel}',
        createdAt: DateTime.now(),
      ),
      JournalLineEntity(
        id: '',
        journalEntryId: '',
        accountId: creditAccountId,
        accountCode: creditAccountCode,
        accountName: creditAccountName,
        accountType: creditAccountType,
        debitAmount: 0.0,
        creditAmount: voucher.netAmount,
        description: '${voucher.typeLabel} via ${voucher.paymentModeLabel}',
        createdAt: DateTime.now(),
      ),
    ];

    final journalEntry = JournalEntryEntity(
      id: '',
      showroomId: voucher.showroomId,
      entryNumber: 'JRN-$voucherNumber',
      entryDate: voucher.voucherDate,
      referenceType: voucher.voucherType,
      referenceId: voucherNumber,
      narration: voucher.narration.isNotEmpty
          ? voucher.narration
          : '${voucher.typeLabel} for ${voucher.partyName} via ${voucher.paymentModeLabel}',
      totalDebit: voucher.netAmount,
      totalCredit: voucher.netAmount,
      isBalanced: true,
      status: 'posted',
      postedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      showroomName: voucher.showroomName,
    );

    return await _accountingService.createJournalEntry(
      journalEntry,
      lines,
      autoPost: true,
    );
  }

  String _getVoucherPrefix(String type) {
    switch (type) {
      case 'payment':
        return 'PMT';
      case 'receipt':
        return 'RCT';
      case 'contra':
        return 'CNT';
      case 'expense':
        return 'EXP';
      case 'credit_note':
        return 'CRN';
      case 'debit_note':
        return 'DBN';
      default:
        return 'VCH';
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // OUTSTANDINGS & AGING ANALYSIS (RECEIVABLES & PAYABLES)
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch Customer Receivables calculated from real invoices
  Future<List<PartyOutstandingEntity>> fetchCustomerReceivables({String? showroomId}) async {
    final invoices = await SalesManagementService.instance.fetchInvoices(showroomId: showroomId);
    final unpaid = invoices.where((i) => i.paymentStatus != 'paid' && i.balanceAmount > 0).toList();

    final Map<String, List<dynamic>> grouped = {};
    for (final inv in unpaid) {
      grouped.putIfAbsent(inv.customerId, () => []).add(inv);
    }

    final now = DateTime.now();
    final list = <PartyOutstandingEntity>[];

    for (final entry in grouped.entries) {
      final custInvoices = entry.value;
      final first = custInvoices.first;
      final totalInvoiced = custInvoices.fold<double>(0.0, (s, i) => s + (i.totalOnRoadPrice as double));
      final totalSettled = custInvoices.fold<double>(0.0, (s, i) => s + (i.amountPaid as double));
      final balance = totalInvoiced - totalSettled;

      double b0 = 0, b30 = 0, b60 = 0, b90 = 0;
      for (final inv in custInvoices) {
        final days = now.difference(inv.invoiceDate as DateTime).inDays;
        final b = inv.balanceAmount as double;
        if (days <= 30) {
          b0 += b;
        } else if (days <= 60) {
          b30 += b;
        } else if (days <= 90) {
          b60 += b;
        } else {
          b90 += b;
        }
      }

      list.add(PartyOutstandingEntity(
        partyId: entry.key,
        partyName: first.customerName ?? 'Customer #${entry.key}',
        partyType: 'customer',
        phone: first.customerMobile ?? '',
        showroomId: first.showroomId,
        showroomName: first.showroomName,
        totalInvoiced: totalInvoiced,
        totalSettled: totalSettled,
        outstandingBalance: balance,
        bucket0To30: b0,
        bucket31To60: b30,
        bucket61To90: b60,
        bucket90Plus: b90,
        latestInvoiceDate: first.invoiceDate as DateTime,
      ));
    }

    list.sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));
    return list;
  }

  /// Fetch Supplier/OEM Payables from live suppliers
  Future<List<PartyOutstandingEntity>> fetchSupplierPayables({String? showroomId}) async {
    final suppliers = await SupplierManagementService.instance.fetchSuppliers();
    final list = <PartyOutstandingEntity>[];

    for (final s in suppliers) {
      if (s.openingBalance > 0) {
        list.add(PartyOutstandingEntity(
          partyId: s.id,
          partyName: s.name,
          partyType: 'supplier',
          phone: s.phone,
          email: s.email,
          totalInvoiced: s.openingBalance,
          totalSettled: 0.0,
          outstandingBalance: s.openingBalance,
          bucket0To30: s.openingBalance,
          bucket31To60: 0.0,
          bucket61To90: 0.0,
          bucket90Plus: 0.0,
          latestInvoiceDate: s.createdAt,
        ));
      }
    }

    list.sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));
    return list;
  }

  /// Aggregate total receivables and payables KPIs
  Future<Map<String, dynamic>> getOutstandingsSummary({String? showroomId}) async {
    final receivables = await fetchCustomerReceivables(showroomId: showroomId);
    final payables = await fetchSupplierPayables(showroomId: showroomId);

    final totalReceivable = receivables.fold<double>(0.0, (s, r) => s + r.outstandingBalance);
    final totalPayable = payables.fold<double>(0.0, (s, p) => s + p.outstandingBalance);

    final overdueReceivables = receivables.fold<double>(
      0.0,
      (s, r) => s + (r.bucket31To60 + r.bucket61To90 + r.bucket90Plus),
    );

    final overduePayables = payables.fold<double>(
      0.0,
      (s, p) => s + (p.bucket31To60 + p.bucket61To90 + p.bucket90Plus),
    );

    return {
      'totalReceivable': totalReceivable,
      'totalPayable': totalPayable,
      'netWorkingBalance': totalReceivable - totalPayable,
      'overdueReceivables': overdueReceivables,
      'overduePayables': overduePayables,
      'receivablesCount': receivables.length,
      'payablesCount': payables.length,
    };
  }
}
