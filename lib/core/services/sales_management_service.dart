import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../../features/sales/domain/entities/sales_invoice_entity.dart';
import '../../features/sales/domain/entities/invoice_item_entity.dart';
import '../../features/sales/domain/entities/payment_receipt_entity.dart';
import '../../features/sales/domain/entities/delivery_challan_entity.dart';
import '../../features/sales/domain/entities/gate_pass_entity.dart';
import '../../features/sales/data/models/sales_invoice_model.dart';
import '../../features/sales/data/models/payment_receipt_model.dart';
import '../../features/sales/data/models/delivery_challan_model.dart';
import '../../features/sales/data/models/gate_pass_model.dart';
import '../../features/sales/data/models/invoice_item_model.dart';
import 'inventory_management_service.dart';
import 'customer_management_service.dart';

/// Sales Management Service
///
/// Handles all dealership sales, GST tax invoicing, payment receipts,
/// delivery challans, and gate passes with direct Supabase CRUD persistence.
class SalesManagementService {
  SalesManagementService._();
  static final SalesManagementService instance = SalesManagementService._();

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  /// Operational seed invoices conforming with the dealership database seed
  static final List<SalesInvoiceEntity> seedInvoices = [
    SalesInvoiceEntity(
      id: 'e1111111-1111-4111-8111-111111111111',
      showroomId: '643cbe40-8f72-400b-9c8e-a1c372e0be60',
      showroomName: 'Mumbai Flagship Showroom',
      customerId: 'a1111111-1111-4111-8111-111111111111',
      customerName: 'Rajesh Sharma',
      customerMobile: '9820112233',
      invoiceNumber: 'INV-2026-0001',
      invoiceDate: DateTime(2026, 3, 18),
      variantId: 'ed20dcc6-3ecd-4275-9bcf-fef5170167a1',
      modelName: "Honda CB350 H'ness",
      variantName: 'DLX Pro Dual Tone',
      colorId: 'dc7007fe-1686-4afa-a1dd-672bc73489e6',
      colorName: 'Precious Red Metallic',
      vin: 'ME4NC5800N800101',
      engineNumber: 'NC58E800101',
      hsnCode: '8711',
      gstRate: 28.0,
      isInterstate: false,
      exShowroomPrice: 217800.0,
      discountAmount: 3000.0,
      taxableAmount: 167812.50,
      cgstAmount: 23493.75,
      sgstAmount: 23493.75,
      rtoCharges: 26136.0,
      insuranceCharges: 13068.0,
      accessoriesTotal: 4500.0,
      extendedWarrantyAmount: 2500.0,
      fastagCharges: 500.0,
      hypothecationCharges: 1500.0,
      totalOnRoadPrice: 266004.0,
      bookingAdvanceAdjusted: 25000.0,
      financeAmount: 150000.0,
      financeBank: 'HDFC Bank',
      amountPaid: 266004.0,
      balanceAmount: 0.0,
      paymentStatus: 'paid',
      status: 'delivered',
      createdAt: DateTime(2026, 3, 18),
      updatedAt: DateTime(2026, 3, 18),
    ),
    SalesInvoiceEntity(
      id: 'e2222222-2222-4222-8222-222222222222',
      showroomId: '90cfc09a-5d7f-4890-8a8b-c57c830dbf55',
      showroomName: 'Pune West Hub',
      customerId: 'a2222222-2222-4222-8222-222222222222',
      customerName: 'Sneha Patil',
      customerMobile: '9890223344',
      invoiceNumber: 'INV-2026-0002',
      invoiceDate: DateTime(2026, 3, 22),
      variantId: 'fe430c3a-3e29-4aab-9c4d-37ed84771853',
      modelName: 'Honda Activa 6G',
      variantName: 'Deluxe',
      colorId: '6d18fe64-5b46-49f1-b2fb-7923790b27d3',
      colorName: 'Pearl Siren Blue',
      vin: 'ME4JF9100N800202',
      engineNumber: 'JF91E800202',
      hsnCode: '8711',
      gstRate: 28.0,
      isInterstate: false,
      exShowroomPrice: 82500.0,
      discountAmount: 1000.0,
      taxableAmount: 63671.88,
      cgstAmount: 8914.06,
      sgstAmount: 8914.06,
      rtoCharges: 9900.0,
      insuranceCharges: 4950.0,
      accessoriesTotal: 1800.0,
      extendedWarrantyAmount: 1200.0,
      totalOnRoadPrice: 99350.0,
      bookingAdvanceAdjusted: 10000.0,
      amountPaid: 99350.0,
      balanceAmount: 0.0,
      paymentStatus: 'paid',
      status: 'delivered',
      createdAt: DateTime(2026, 3, 22),
      updatedAt: DateTime(2026, 3, 22),
    ),
    SalesInvoiceEntity(
      id: 'e3333333-3333-4333-8333-333333333333',
      showroomId: '589c1835-940d-4fcf-ab35-da31a0502825',
      showroomName: 'Bengaluru Metro Showroom',
      customerId: 'a3333333-3333-4333-8333-333333333333',
      customerName: 'Vikram Iyer',
      customerMobile: '9845334455',
      invoiceNumber: 'INV-2026-0003',
      invoiceDate: DateTime(2026, 3, 26),
      variantId: 'c7b5277d-e8b4-48ef-8ccf-38a6c9023d2a',
      modelName: 'Ather 450X Gen 3',
      variantName: '3.7 kWh Pro',
      colorId: 'c7b5277d-e8b4-48ef-8ccf-38a6c9023c01',
      colorName: 'True White',
      vin: 'MALJA450XN800303',
      hsnCode: '8711',
      gstRate: 5.0,
      isInterstate: false,
      exShowroomPrice: 154999.0,
      discountAmount: 2000.0,
      taxableAmount: 145713.33,
      cgstAmount: 3642.83,
      sgstAmount: 3642.83,
      rtoCharges: 7750.0,
      insuranceCharges: 6200.0,
      accessoriesTotal: 3500.0,
      extendedWarrantyAmount: 2000.0,
      totalOnRoadPrice: 172449.0,
      bookingAdvanceAdjusted: 10000.0,
      financeAmount: 100000.0,
      financeBank: 'State Bank of India',
      amountPaid: 172449.0,
      balanceAmount: 0.0,
      paymentStatus: 'paid',
      status: 'issued',
      createdAt: DateTime(2026, 3, 26),
      updatedAt: DateTime(2026, 3, 26),
    ),
  ];

  final List<SalesInvoiceEntity> _localInvoices = [];
  final List<PaymentReceiptEntity> _localReceipts = [];

  // ═══════════════════════════════════════════════════════════════════
  // INVOICE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch invoices with optional filters directly from Supabase or fallback
  Future<List<SalesInvoiceEntity>> fetchInvoices({
    String? showroomId,
    String? status,
    String? search,
  }) async {
    List<SalesInvoiceEntity> results = [];

    if (_isSupabaseLive) {
      try {
        var query = SupabaseService.client!.from('sales_invoices').select(
          '*, customers(first_name, last_name, mobile_primary), vehicle_variants(name, vehicle_models(name)), vehicle_colors(name), showrooms(name)',
        );
        if (showroomId != null && showroomId.isNotEmpty && _uuidRegex.hasMatch(showroomId)) {
          query = query.eq('showroom_id', showroomId);
        }
        if (status != null && status.isNotEmpty && status != 'all') {
          query = query.eq('status', status);
        }
        final response = await query.order('created_at', ascending: false);
        final rawList = response as List;

        results = rawList.map((e) {
          final row = Map<String, dynamic>.from(e as Map);
          final cust = row['customers'] as Map<String, dynamic>?;
          if (cust != null) {
            row['customer_name'] = '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
            row['customer_mobile'] = cust['mobile_primary'];
          }
          final variant = row['vehicle_variants'] as Map<String, dynamic>?;
          if (variant != null) {
            row['variant_name'] = variant['name'];
            final model = variant['vehicle_models'] as Map<String, dynamic>?;
            if (model != null) {
              row['model_name'] = model['name'];
            }
          }
          final color = row['vehicle_colors'] as Map<String, dynamic>?;
          if (color != null) {
            row['color_name'] = color['name'];
          }
          final showroom = row['showrooms'] as Map<String, dynamic>?;
          if (showroom != null) {
            row['showroom_name'] = showroom['name'];
          }
          return SalesInvoiceModel.fromJson(row);
        }).toList();
      } catch (e) {
        debugPrint('SalesManagementService.fetchInvoices error: $e');
      }
    }

    // Merge in-memory newly created invoices (avoiding duplicates)
    final existingIds = results.map((r) => r.id).toSet();
    for (final loc in _localInvoices) {
      if (!existingIds.contains(loc.id)) {
        results.insert(0, loc);
        existingIds.add(loc.id);
      }
    }

    // Fall back to seed invoices if database returned empty
    if (results.isEmpty) {
      results = List<SalesInvoiceEntity>.from(seedInvoices);
    }

    if (showroomId != null && showroomId.isNotEmpty && _uuidRegex.hasMatch(showroomId)) {
      results = results.where((inv) => inv.showroomId == showroomId).toList();
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      results = results.where((inv) => inv.status == status).toList();
    }

    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim().toLowerCase();
      results = results.where((inv) =>
          inv.invoiceNumber.toLowerCase().contains(s) ||
          inv.vin.toLowerCase().contains(s) ||
          (inv.customerName?.toLowerCase().contains(s) ?? false) ||
          (inv.customerMobile?.contains(s) ?? false)).toList();
    }
    return results;
  }

  /// Fetch a single invoice by ID
  Future<SalesInvoiceEntity?> fetchInvoiceById(String id) async {
    // Check in-memory local cache first for newly generated invoices
    final localMatch = _localInvoices.cast<SalesInvoiceEntity?>().firstWhere(
          (i) => i?.id == id,
          orElse: () => null,
        );
    if (localMatch != null) return localMatch;

    if (_isSupabaseLive && _uuidRegex.hasMatch(id)) {
      try {
        final response = await SupabaseService.client!
            .from('sales_invoices')
            .select(
              '*, customers(first_name, last_name, mobile_primary), vehicle_variants(name, vehicle_models(name)), vehicle_colors(name), showrooms(name)',
            )
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          final row = Map<String, dynamic>.from(response);
          final cust = row['customers'] as Map<String, dynamic>?;
          if (cust != null) {
            row['customer_name'] = '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
            row['customer_mobile'] = cust['mobile_primary'];
          }
          final variant = row['vehicle_variants'] as Map<String, dynamic>?;
          if (variant != null) {
            row['variant_name'] = variant['name'];
            final model = variant['vehicle_models'] as Map<String, dynamic>?;
            if (model != null) {
              row['model_name'] = model['name'];
            }
          }
          final color = row['vehicle_colors'] as Map<String, dynamic>?;
          if (color != null) {
            row['color_name'] = color['name'];
          }
          final showroom = row['showrooms'] as Map<String, dynamic>?;
          if (showroom != null) {
            row['showroom_name'] = showroom['name'];
          }
          return SalesInvoiceModel.fromJson(row);
        }
      } catch (e) {
        debugPrint('SalesManagementService.fetchInvoiceById error: $e');
      }
    }

    // Fallback to seed invoices
    return seedInvoices.cast<SalesInvoiceEntity?>().firstWhere(
          (i) => i?.id == id,
          orElse: () => null,
        );
  }

  /// Create a new Sales Invoice (GST Tax Invoice)
  Future<SalesInvoiceEntity> createInvoice(
    SalesInvoiceEntity invoice, {
    List<InvoiceItemEntity>? items,
  }) async {
    final invoiceNumber = (invoice.invoiceNumber.isNotEmpty)
        ? invoice.invoiceNumber
        : 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    SalesInvoiceEntity? created;

    if (_isSupabaseLive) {
      try {
        final payload = SalesInvoiceModel.toInsertJson(invoice);
        payload['invoice_number'] = invoiceNumber;

        final response = await SupabaseService.client!
            .from('sales_invoices')
            .insert(payload)
            .select()
            .single();

        final createdFromDb = SalesInvoiceModel.fromJson(response);
        created = createdFromDb.copyWith(
          customerName: invoice.customerName,
          customerMobile: invoice.customerMobile,
          modelName: invoice.modelName,
          variantName: invoice.variantName,
          colorName: invoice.colorName,
          showroomName: invoice.showroomName,
        );

        final vehicleItemMap = {
          'invoice_id': created.id,
          'item_type': 'vehicle',
          'description': '${invoice.modelName ?? "Vehicle"} ${invoice.variantName ?? ""}'.trim(),
          'hsn_sac_code': invoice.hsnCode,
          'quantity': 1,
          'unit_price': invoice.taxableAmount,
          'taxable_amount': invoice.taxableAmount,
          'gst_rate': invoice.gstRate,
          'tax_amount': invoice.totalGst,
          'total_amount': invoice.taxableAmount + invoice.totalGst,
        };
        await SupabaseService.client!.from('invoice_items').insert(vehicleItemMap);

        if (items != null && items.isNotEmpty) {
          final lineItemsPayload = items.map((i) {
            final m = InvoiceItemModel.toJson(i);
            m.remove('id');
            m.remove('created_at');
            m['invoice_id'] = created!.id;
            return m;
          }).toList();
          await SupabaseService.client!.from('invoice_items').insert(lineItemsPayload);
        }
      } catch (e) {
        debugPrint('SalesManagementService.createInvoice Supabase fallback: $e');
      }
    }

    if (created == null) {
      final hex = DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
      final localId = 'e0000000-0000-4000-8000-$hex';
      created = invoice.copyWith(
        id: localId,
        invoiceNumber: invoiceNumber,
      );
    }

    _localInvoices.removeWhere((i) => i.id == created!.id);
    _localInvoices.insert(0, created);

    // If linked to a booking, mark the booking as confirmed / invoiced
    if (invoice.bookingId != null) {
      try {
        await CustomerManagementService.instance.updateBookingStatus(
          invoice.bookingId!,
          'confirmed',
        );
      } catch (e) {
        debugPrint('Note: Booking not updated: $e');
      }
    }

    return created;
  }

  /// Update invoice state
  Future<SalesInvoiceEntity> updateInvoiceStatus(String id, String status) async {
    if (_isSupabaseLive && _uuidRegex.hasMatch(id)) {
      try {
        final response = await SupabaseService.client!
            .from('sales_invoices')
            .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', id)
            .select()
            .single();

        return SalesInvoiceModel.fromJson(response);
      } catch (e) {
        debugPrint('SalesManagementService.updateInvoiceStatus note: $e');
      }
    }

    // Update in local cache
    final idx = _localInvoices.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _localInvoices[idx] = _localInvoices[idx].copyWith(status: status);
      return _localInvoices[idx];
    }

    throw Exception('Invoice not found');
  }

  // ═══════════════════════════════════════════════════════════════════
  // PAYMENT RECEIPTS
  // ═══════════════════════════════════════════════════════════════════

  void resetDevData() {
    _localInvoices.clear();
    _localReceipts.clear();
  }

  /// Alias for createReceipt for lifecycle callers
  Future<PaymentReceiptEntity> recordPaymentReceipt(PaymentReceiptEntity receipt) =>
      createReceipt(receipt);

  /// Fetch payment receipts directly from Supabase or local cache
  Future<List<PaymentReceiptEntity>> fetchReceipts({String? invoiceId, String? showroomId}) async {
    List<PaymentReceiptEntity> results = [];

    if (_isSupabaseLive) {
      try {
        var query = SupabaseService.client!.from('payment_receipts').select('*, customers(first_name, last_name)');
        if (invoiceId != null && invoiceId.isNotEmpty && _uuidRegex.hasMatch(invoiceId)) {
          query = query.eq('invoice_id', invoiceId);
        }
        if (showroomId != null && showroomId.isNotEmpty && _uuidRegex.hasMatch(showroomId)) {
          query = query.eq('showroom_id', showroomId);
        }
        final response = await query.order('created_at', ascending: false);
        final rawList = response as List;

        results = rawList.map((e) {
          final row = Map<String, dynamic>.from(e as Map);
          final cust = row['customers'] as Map<String, dynamic>?;
          if (cust != null) {
            row['customer_name'] = '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
          }
          return PaymentReceiptModel.fromJson(row);
        }).toList();
      } catch (e) {
        debugPrint('SalesManagementService.fetchReceipts error: $e');
      }
    }

    // Merge in-memory local receipts
    final existingIds = results.map((r) => r.id).toSet();
    for (final loc in _localReceipts) {
      if (!existingIds.contains(loc.id)) {
        if (invoiceId != null && loc.invoiceId != invoiceId) continue;
        results.insert(0, loc);
        existingIds.add(loc.id);
      }
    }

    return results;
  }

  /// Create and persist a payment receipt against an invoice
  Future<PaymentReceiptEntity> createReceipt(PaymentReceiptEntity receipt) async {
    final receiptNumber = (receipt.receiptNumber.isNotEmpty)
        ? receipt.receiptNumber
        : 'RCP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    PaymentReceiptEntity? createdReceipt;

    if (_isSupabaseLive) {
      try {
        final payload = PaymentReceiptModel.toJson(receipt);
        payload.remove('id');
        payload.remove('created_at');
        payload['receipt_number'] = receiptNumber;

        final response = await SupabaseService.client!
            .from('payment_receipts')
            .insert(payload)
            .select()
            .single();

        createdReceipt = PaymentReceiptModel.fromJson(response);
      } catch (e) {
        debugPrint('SalesManagementService.createReceipt Supabase fallback: $e');
      }
    }

    if (createdReceipt == null) {
      final hex = DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
      final localId = 'r0000000-0000-4000-8000-$hex';
      createdReceipt = receipt.copyWith(
        id: localId,
        receiptNumber: receiptNumber,
      );
    }

    _localReceipts.removeWhere((r) => r.id == createdReceipt!.id);
    _localReceipts.insert(0, createdReceipt);

    // Update parent invoice balance and payment status in local store
    if (receipt.invoiceId != null) {
      final idx = _localInvoices.indexWhere((i) => i.id == receipt.invoiceId);
      if (idx >= 0) {
        final inv = _localInvoices[idx];
        final newPaid = inv.amountPaid + receipt.amount;
        final newBal = (inv.totalOnRoadPrice - newPaid).clamp(0.0, double.infinity);
        _localInvoices[idx] = inv.copyWith(
          amountPaid: newPaid,
          balanceAmount: newBal,
          paymentStatus: newBal <= 0 ? 'paid' : 'partial',
        );
      }

      if (_isSupabaseLive && _uuidRegex.hasMatch(receipt.invoiceId!)) {
        try {
          final inv = await fetchInvoiceById(receipt.invoiceId!);
          if (inv != null) {
            final newPaid = inv.amountPaid + receipt.amount;
            final newBalance = (inv.totalOnRoadPrice - newPaid).clamp(0.0, double.infinity);
            final newStatus = newBalance <= 0.0 ? 'paid' : 'partial';

            await SupabaseService.client!.from('sales_invoices').update({
              'amount_paid': newPaid,
              'balance_amount': newBalance,
              'payment_status': newStatus,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', receipt.invoiceId!);
          }
        } catch (e) {
          debugPrint('Note updating invoice balance: $e');
        }
      }
    }

    return createdReceipt;
  }

  // ═══════════════════════════════════════════════════════════════════
  // DELIVERY CHALLAN & GATE PASS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch delivery challans from Supabase
  Future<List<DeliveryChallanEntity>> fetchDeliveryChallans({String? showroomId}) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('delivery_challans').select(
        '*, sales_invoices(invoice_number, vehicle_variants(name, vehicle_models(name)), vehicle_colors(name))',
      );
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      final response = await query.order('created_at', ascending: false);
      final rawList = response as List;

      return rawList.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final inv = row['sales_invoices'] as Map<String, dynamic>?;
        if (inv != null) {
          row['invoice_number'] = inv['invoice_number'];
          final variant = inv['vehicle_variants'] as Map<String, dynamic>?;
          if (variant != null) {
            row['variant_name'] = variant['name'];
            final model = variant['vehicle_models'] as Map<String, dynamic>?;
            if (model != null) {
              row['model_name'] = model['name'];
            }
          }
          final color = inv['vehicle_colors'] as Map<String, dynamic>?;
          if (color != null) {
            row['color_name'] = color['name'];
          }
        }
        return DeliveryChallanModel.fromJson(row);
      }).toList();
    } catch (e) {
      debugPrint('SalesManagementService.fetchDeliveryChallans error: $e');
      return [];
    }
  }

  /// Fetch delivery challan by ID
  Future<DeliveryChallanEntity?> fetchDeliveryChallanById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final response = await SupabaseService.client!
          .from('delivery_challans')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return DeliveryChallanModel.fromJson(response);
    } catch (e) {
      debugPrint('SalesManagementService.fetchDeliveryChallanById error: $e');
      return null;
    }
  }

  /// Fetch delivery challan by invoice ID
  Future<DeliveryChallanEntity?> fetchChallanByInvoiceId(String invoiceId) async {
    if (!_isSupabaseLive) return null;

    try {
      final response = await SupabaseService.client!
          .from('delivery_challans')
          .select()
          .eq('invoice_id', invoiceId)
          .maybeSingle();

      if (response == null) return null;
      return DeliveryChallanModel.fromJson(response);
    } catch (e) {
      debugPrint('SalesManagementService.fetchChallanByInvoiceId error: $e');
      return null;
    }
  }

  /// Fetch invoice line items
  Future<List<InvoiceItemEntity>> fetchInvoiceItems(String invoiceId) async {
    if (!_isSupabaseLive) return [];

    try {
      final response = await SupabaseService.client!
          .from('invoice_items')
          .select()
          .eq('invoice_id', invoiceId)
          .order('created_at', ascending: true);

      return (response as List).map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('SalesManagementService.fetchInvoiceItems error: $e');
      return [];
    }
  }

  /// Create a Delivery Challan, updates Invoice to 'delivered' and vehicle to 'delivered'
  Future<DeliveryChallanEntity> createDeliveryChallan(DeliveryChallanEntity challan) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = DeliveryChallanModel.toJson(challan);
    payload.remove('id');
    payload.remove('created_at');
    if (payload['challan_number'] == null || (payload['challan_number'] as String).isEmpty) {
      payload['challan_number'] = 'DC-${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await SupabaseService.client!
        .from('delivery_challans')
        .insert(payload)
        .select()
        .single();

    final createdChallan = DeliveryChallanModel.fromJson(response);

    // Update invoice status to 'delivered'
    try {
      await updateInvoiceStatus(challan.invoiceId, 'delivered');
    } catch (e) {
      debugPrint('Note updating invoice status on delivery: $e');
    }

    // Update vehicle inventory status if vehicle ID or VIN is known
    try {
      final v = await InventoryManagementService.instance.fetchVehicleByVin(challan.allocatedVin);
      if (v != null) {
        await InventoryManagementService.instance.updateVehicleStatus(v.vehicle.id, 'delivered');
        await InventoryManagementService.instance.logStockMovement(
          vehicleId: v.vehicle.id,
          movementType: 'delivered',
          remarks: 'Vehicle handed over to customer under challan ${createdChallan.challanNumber}',
        );
      }
    } catch (e) {
      debugPrint('Note updating inventory vehicle on delivery: $e');
    }

    return createdChallan;
  }

  /// Fetch gate passes
  Future<List<GatePassEntity>> fetchGatePasses({String? showroomId, String? challanId}) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('gate_passes').select();
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      if (challanId != null && challanId.isNotEmpty) {
        query = query.eq('challan_id', challanId);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((e) => GatePassModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('SalesManagementService.fetchGatePasses error: $e');
      return [];
    }
  }

  /// Create security Gate Pass for physical showroom exit
  Future<GatePassEntity> createGatePass(GatePassEntity gatePass) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = GatePassModel.toJson(gatePass);
    payload.remove('id');
    payload.remove('created_at');
    if (payload['gate_pass_number'] == null || (payload['gate_pass_number'] as String).isEmpty) {
      payload['gate_pass_number'] = 'GP-${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await SupabaseService.client!
        .from('gate_passes')
        .insert(payload)
        .select()
        .single();

    return GatePassModel.fromJson(response);
  }

  /// Security mark vehicle departure at the showroom exit gate
  Future<GatePassEntity> markGatePassDeparted(String gatePassId) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final response = await SupabaseService.client!
        .from('gate_passes')
        .update({
          'status': 'departed',
          'vehicle_departed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', gatePassId)
        .select()
        .single();

    return GatePassModel.fromJson(response);
  }
}
