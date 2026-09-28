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

  bool get _isSupabaseLive =>
      SupabaseConfig.isConfigured && SupabaseService.client != null;

  // ═══════════════════════════════════════════════════════════════════
  // INVOICE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch invoices with optional filters directly from Supabase
  Future<List<SalesInvoiceEntity>> fetchInvoices({
    String? showroomId,
    String? status,
    String? search,
  }) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('sales_invoices').select(
        '*, customers(first_name, last_name, mobile_primary), vehicle_variants(name, vehicle_models(name)), vehicle_colors(name), showrooms(name)',
      );
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false);
      final rawList = response as List;

      final results = rawList.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        // Hydrate joined relation names into flat model attributes
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

      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        return results.where((inv) =>
            inv.invoiceNumber.toLowerCase().contains(s) ||
            inv.vin.toLowerCase().contains(s) ||
            (inv.customerName?.toLowerCase().contains(s) ?? false) ||
            (inv.customerMobile?.contains(s) ?? false)).toList();
      }
      return results;
    } catch (e) {
      debugPrint('SalesManagementService.fetchInvoices error: $e');
      return [];
    }
  }

  /// Fetch a single invoice by ID
  Future<SalesInvoiceEntity?> fetchInvoiceById(String id) async {
    if (!_isSupabaseLive) return null;

    try {
      final response = await SupabaseService.client!
          .from('sales_invoices')
          .select(
            '*, customers(first_name, last_name, mobile_primary), vehicle_variants(name, vehicle_models(name)), vehicle_colors(name), showrooms(name)',
          )
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

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
    } catch (e) {
      debugPrint('SalesManagementService.fetchInvoiceById error: $e');
      return null;
    }
  }

  /// Create a new Sales Invoice (GST Tax Invoice)
  Future<SalesInvoiceEntity> createInvoice(
    SalesInvoiceEntity invoice, {
    List<InvoiceItemEntity>? items,
  }) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = SalesInvoiceModel.toInsertJson(invoice);
    if (payload['invoice_number'] == null || (payload['invoice_number'] as String).isEmpty) {
      payload['invoice_number'] = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await SupabaseService.client!
        .from('sales_invoices')
        .insert(payload)
        .select()
        .single();

    final created = SalesInvoiceModel.fromJson(response);

    // Track vehicle line item
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

    try {
      await SupabaseService.client!.from('invoice_items').insert(vehicleItemMap);

      if (items != null && items.isNotEmpty) {
        final lineItemsPayload = items.map((i) {
          final m = InvoiceItemModel.toJson(i);
          m.remove('id');
          m.remove('created_at');
          m['invoice_id'] = created.id;
          return m;
        }).toList();
        await SupabaseService.client!.from('invoice_items').insert(lineItemsPayload);
      }
    } catch (e) {
      debugPrint('Invoice line items insertion note: $e');
    }

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
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final response = await SupabaseService.client!
        .from('sales_invoices')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .select()
        .single();

    return SalesInvoiceModel.fromJson(response);
  }

  // ═══════════════════════════════════════════════════════════════════
  // PAYMENT RECEIPTS
  // ═══════════════════════════════════════════════════════════════════

  void resetDevData() {}

  /// Alias for createReceipt for lifecycle callers
  Future<PaymentReceiptEntity> recordPaymentReceipt(PaymentReceiptEntity receipt) =>
      createReceipt(receipt);

  /// Fetch payment receipts directly from Supabase
  Future<List<PaymentReceiptEntity>> fetchReceipts({String? invoiceId, String? showroomId}) async {
    if (!_isSupabaseLive) return [];

    try {
      var query = SupabaseService.client!.from('payment_receipts').select('*, customers(first_name, last_name)');
      if (invoiceId != null && invoiceId.isNotEmpty) {
        query = query.eq('invoice_id', invoiceId);
      }
      if (showroomId != null && showroomId.isNotEmpty) {
        query = query.eq('showroom_id', showroomId);
      }
      final response = await query.order('created_at', ascending: false);
      final rawList = response as List;

      return rawList.map((e) {
        final row = Map<String, dynamic>.from(e as Map);
        final cust = row['customers'] as Map<String, dynamic>?;
        if (cust != null) {
          row['customer_name'] = '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
        }
        return PaymentReceiptModel.fromJson(row);
      }).toList();
    } catch (e) {
      debugPrint('SalesManagementService.fetchReceipts error: $e');
      return [];
    }
  }

  /// Create and persist a payment receipt against an invoice
  Future<PaymentReceiptEntity> createReceipt(PaymentReceiptEntity receipt) async {
    if (!_isSupabaseLive) {
      throw Exception('Supabase connection is not active');
    }

    final payload = PaymentReceiptModel.toJson(receipt);
    payload.remove('id');
    payload.remove('created_at');
    if (payload['receipt_number'] == null || (payload['receipt_number'] as String).isEmpty) {
      payload['receipt_number'] = 'RCP-${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await SupabaseService.client!
        .from('payment_receipts')
        .insert(payload)
        .select()
        .single();

    final createdReceipt = PaymentReceiptModel.fromJson(response);

    // Update parent invoice balance and payment status
    if (receipt.invoiceId != null) {
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
