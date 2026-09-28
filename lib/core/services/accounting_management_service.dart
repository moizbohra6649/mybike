import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../../features/accounting/domain/entities/account_entity.dart';
import '../../features/accounting/domain/entities/journal_entry_entity.dart';
import '../../features/accounting/domain/entities/journal_line_entity.dart';
import '../../features/accounting/domain/entities/trial_balance_item_entity.dart';
import '../../features/accounting/data/models/account_model.dart';
import '../../features/accounting/data/models/journal_entry_model.dart';

/// Accounting Management Service
///
/// Handles Chart of Accounts (COA), double-entry journal vouchers, general ledger,
/// anti-tamper reversals, and trial balance calculations with live Supabase CRUD.
class AccountingManagementService {
  AccountingManagementService._();
  static final AccountingManagementService instance = AccountingManagementService._();

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  void resetDevData() {}

  // ═══════════════════════════════════════════════════════════════════
  // CHART OF ACCOUNTS (COA) OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch all accounts with optional filtering directly from Supabase
  Future<List<AccountEntity>> fetchAccounts({
    String? showroomId,
    String? accountType,
    String? search,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('chart_of_accounts').select();
      if (accountType != null && accountType.isNotEmpty && accountType != 'all') {
        query = query.eq('account_type', accountType);
      }
      final response = await query.order('account_code');
      var list = (response as List).map((j) => AccountModel.fromJson(j as Map<String, dynamic>)).toList();

      if (showroomId != null && showroomId.isNotEmpty) {
        list = list.where((a) => a.showroomId == null || a.showroomId == showroomId).toList();
      }
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        list = list.where((a) =>
            a.accountCode.toLowerCase().contains(s) ||
            a.accountName.toLowerCase().contains(s) ||
            a.subType.toLowerCase().contains(s)).toList();
      }
      return list;
    } catch (e) {
      debugPrint('AccountingManagementService.fetchAccounts error: $e');
      return [];
    }
  }

  /// Fetch account by ID
  Future<AccountEntity?> fetchAccountById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final response = await SupabaseService.client!
          .from('chart_of_accounts')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return AccountModel.fromJson(response);
    } catch (e) {
      debugPrint('AccountingManagementService.fetchAccountById error: $e');
      return null;
    }
  }

  /// Create a new account
  Future<AccountEntity> createAccount(AccountEntity account) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final payload = AccountModel.toJson(account);
    payload.remove('id');
    payload.remove('created_at');
    payload.remove('updated_at');

    final response = await SupabaseService.client!
        .from('chart_of_accounts')
        .insert(payload)
        .select()
        .single();
    return AccountModel.fromJson(response);
  }

  /// Update existing account
  Future<AccountEntity> updateAccount(AccountEntity account) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final payload = AccountModel.toJson(account);
    payload.remove('created_at');
    payload['updated_at'] = DateTime.now().toIso8601String();

    final response = await SupabaseService.client!
        .from('chart_of_accounts')
        .update(payload)
        .eq('id', account.id)
        .select()
        .single();
    return AccountModel.fromJson(response);
  }

  // ═══════════════════════════════════════════════════════════════════
  // JOURNAL ENTRY & GENERAL LEDGER OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch journal vouchers from Supabase
  Future<List<JournalEntryEntity>> fetchJournalEntries({
    String? showroomId,
    String? status,
    String? referenceType,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('journal_entries').select(
        '*, journal_entry_lines(*, chart_of_accounts(account_code, account_name, account_type)), showrooms(name)',
      );
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (referenceType != null && referenceType.isNotEmpty && referenceType != 'all') {
        query = query.eq('reference_type', referenceType);
      }
      if (fromDate != null) {
        query = query.gte('entry_date', fromDate.toIso8601String().substring(0, 10));
      }
      if (toDate != null) {
        query = query.lte('entry_date', toDate.toIso8601String().substring(0, 10));
      }

      final response = await query.order('created_at', ascending: false);
      final rawList = response as List;

      final results = rawList.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final sh = row['showrooms'] as Map<String, dynamic>?;
        if (sh != null) {
          row['showroom_name'] = sh['name'];
        }
        final linesData = row['journal_entry_lines'] as List?;
        if (linesData != null) {
          row['lines'] = linesData.map((l) {
            final lMap = Map<String, dynamic>.from(l as Map);
            final acct = lMap['chart_of_accounts'] as Map<String, dynamic>?;
            if (acct != null) {
              lMap['account_code'] = acct['account_code'];
              lMap['account_name'] = acct['account_name'];
              lMap['account_type'] = acct['account_type'];
            }
            return lMap;
          }).toList();
        }
        return JournalEntryModel.fromJson(row);
      }).toList();

      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        return results.where((j) =>
            j.entryNumber.toLowerCase().contains(s) ||
            j.narration.toLowerCase().contains(s) ||
            (j.referenceId?.toLowerCase().contains(s) ?? false)).toList();
      }

      return results;
    } catch (e) {
      debugPrint('AccountingManagementService.fetchJournalEntries error: $e');
      return [];
    }
  }

  /// Fetch a single journal voucher by ID
  Future<JournalEntryEntity?> fetchJournalEntryById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final response = await SupabaseService.client!
          .from('journal_entries')
          .select('*, journal_entry_lines(*, chart_of_accounts(account_code, account_name, account_type)), showrooms(name)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      final row = Map<String, dynamic>.from(response);
      final sh = row['showrooms'] as Map<String, dynamic>?;
      if (sh != null) row['showroom_name'] = sh['name'];

      final linesData = row['journal_entry_lines'] as List?;
      if (linesData != null) {
        row['lines'] = linesData.map((l) {
          final lMap = Map<String, dynamic>.from(l as Map);
          final acct = lMap['chart_of_accounts'] as Map<String, dynamic>?;
          if (acct != null) {
            lMap['account_code'] = acct['account_code'];
            lMap['account_name'] = acct['account_name'];
            lMap['account_type'] = acct['account_type'];
          }
          return lMap;
        }).toList();
      }

      return JournalEntryModel.fromJson(row);
    } catch (e) {
      debugPrint('AccountingManagementService.fetchJournalEntryById error: $e');
      return null;
    }
  }

  /// Create and optionally post a Double-Entry Journal Voucher
  Future<JournalEntryEntity> createJournalEntry(
    JournalEntryEntity entry,
    List<JournalLineEntity> lines, {
    bool autoPost = true,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');
    if (lines.isEmpty) {
      throw Exception('A journal entry must contain at least two line items (Debit and Credit).');
    }

    final totalDebit = lines.fold<double>(0.0, (sum, l) => sum + l.debitAmount);
    final totalCredit = lines.fold<double>(0.0, (sum, l) => sum + l.creditAmount);

    final difference = (totalDebit - totalCredit).abs();
    if (difference >= 0.01) {
      throw Exception(
        'Double-entry balance violation: Total Debits (₹${totalDebit.toStringAsFixed(2)}) does not equal Total Credits (₹${totalCredit.toStringAsFixed(2)}). Difference: ₹${difference.toStringAsFixed(2)}',
      );
    }

    final entryNumber = entry.entryNumber.isNotEmpty
        ? entry.entryNumber
        : 'JRN-${DateTime.now().millisecondsSinceEpoch}';

    final status = autoPost ? 'posted' : entry.status;

    final headerPayload = {
      'showroom_id': entry.showroomId,
      'entry_number': entryNumber,
      'entry_date': entry.entryDate.toIso8601String().substring(0, 10),
      'reference_type': entry.referenceType,
      'reference_id': entry.referenceId,
      'narration': entry.narration,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'is_balanced': true,
      'status': status,
      'posted_at': status == 'posted' ? DateTime.now().toIso8601String() : null,
    };

    final headerRes = await SupabaseService.client!
        .from('journal_entries')
        .insert(headerPayload)
        .select()
        .single();

    final createdId = headerRes['id'] as String;

    final linesPayload = lines.map((l) {
      return {
        'journal_entry_id': createdId,
        'account_id': l.accountId,
        'description': l.description,
        'debit_amount': l.debitAmount,
        'credit_amount': l.creditAmount,
        'showroom_id': entry.showroomId,
      };
    }).toList();

    await SupabaseService.client!.from('journal_entry_lines').insert(linesPayload);

    // Apply posting balance updates to chart_of_accounts if posted
    if (status == 'posted') {
      for (final line in lines) {
        try {
          final acct = await fetchAccountById(line.accountId);
          if (acct != null) {
            double delta = (acct.isAsset || acct.isExpense)
                ? (line.debitAmount - line.creditAmount)
                : (line.creditAmount - line.debitAmount);
            await SupabaseService.client!.from('chart_of_accounts').update({
              'current_balance': acct.currentBalance + delta,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', acct.id);
          }
        } catch (e) {
          debugPrint('Note updating account balance on post: $e');
        }
      }
    }

    return (await fetchJournalEntryById(createdId)) ?? entry;
  }

  /// Strictly enforce audit-compliant anti-tamper reversal
  Future<JournalEntryEntity> reverseJournalEntry(
    String id, {
    required String reason,
    required String reversedBy,
  }) async {
    if (!_isSupabaseLive) throw Exception('Supabase connection is not active');

    final original = await fetchJournalEntryById(id);
    if (original == null) throw Exception('Journal entry not found: $id');
    if (original.status != 'posted') {
      throw Exception('Only posted journal entries can be reversed.');
    }

    final reversalLines = original.lines.map((line) {
      return JournalLineEntity(
        id: '',
        journalEntryId: '',
        accountId: line.accountId,
        accountCode: line.accountCode,
        accountName: line.accountName,
        accountType: line.accountType,
        description: 'Reversal: ${line.description ?? original.entryNumber}',
        debitAmount: line.creditAmount, // Invert
        creditAmount: line.debitAmount, // Invert
        createdAt: DateTime.now(),
      );
    }).toList();

    final reversalNumber = 'REV-${original.entryNumber}';
    final reversalEntry = original.copyWith(
      id: '',
      entryNumber: reversalNumber,
      referenceType: 'reversal',
      referenceId: original.entryNumber,
      narration: 'Reversal of ${original.entryNumber}. Reason: $reason',
      reversedEntryId: original.id,
      status: 'posted',
    );

    final created = await createJournalEntry(reversalEntry, reversalLines, autoPost: true);

    await SupabaseService.client!.from('journal_entries').update({
      'status': 'reversed',
      'reversed_entry_id': created.id,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', original.id);

    return created;
  }

  // ═══════════════════════════════════════════════════════════════════
  // TRIAL BALANCE GENERATOR
  // ═══════════════════════════════════════════════════════════════════

  /// Compute real-time Trial Balance statement
  Future<Map<String, dynamic>> generateTrialBalance({
    String? showroomId,
    DateTime? asOfDate,
  }) async {
    final accounts = await fetchAccounts(showroomId: showroomId);
    final items = <TrialBalanceItemEntity>[];
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (final acct in accounts) {
      double debit = 0.0;
      double credit = 0.0;

      if (acct.isAsset || acct.isExpense) {
        if (acct.currentBalance >= 0) {
          debit = acct.currentBalance;
        } else {
          credit = acct.currentBalance.abs();
        }
      } else {
        if (acct.currentBalance >= 0) {
          credit = acct.currentBalance;
        } else {
          debit = acct.currentBalance.abs();
        }
      }

      totalDebit += debit;
      totalCredit += credit;

      items.add(TrialBalanceItemEntity(
        accountId: acct.id,
        accountCode: acct.accountCode,
        accountName: acct.accountName,
        accountType: acct.accountType,
        debitBalance: debit,
        creditBalance: credit,
      ));
    }

    final isBalanced = (totalDebit - totalCredit).abs() < 0.01;

    return {
      'items': items,
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'difference': (totalDebit - totalCredit).abs(),
      'isBalanced': isBalanced,
      'asOfDate': asOfDate ?? DateTime.now(),
    };
  }
}
