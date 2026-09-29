import 'package:equatable/equatable.dart';

/// Payment Receipt Domain Entity
class PaymentReceiptEntity extends Equatable {
  final String id;
  final String showroomId;
  final String customerId;
  final String? invoiceId;
  final String? bookingId;
  final String receiptNumber; // e.g. "IND-MUM-RCP-00042"
  final DateTime receiptDate;
  final double amount;
  final String paymentMode; // 'cash', 'upi', 'neft_rtgs', 'card', 'cheque', 'finance_disbursement', 'exchange_credit'
  final String? paymentReference;
  final String? bankName;
  final String? collectedBy;
  final String? notes;
  final DateTime createdAt;

  // Hydrated helper
  final String? customerName;

  const PaymentReceiptEntity({
    required this.id,
    required this.showroomId,
    required this.customerId,
    this.invoiceId,
    this.bookingId,
    required this.receiptNumber,
    required this.receiptDate,
    required this.amount,
    required this.paymentMode,
    this.paymentReference,
    this.bankName,
    this.collectedBy,
    this.notes,
    required this.createdAt,
    this.customerName,
  });

  String get paymentModeLabel {
    switch (paymentMode) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'neft_rtgs':
        return 'NEFT / RTGS';
      case 'card':
        return 'Debit / Credit Card';
      case 'cheque':
        return 'Cheque';
      case 'finance_disbursement':
        return 'Loan Disbursement';
      case 'exchange_credit':
        return 'Exchange Vehicle Credit';
      default:
        return paymentMode;
    }
  }

  PaymentReceiptEntity copyWith({
    String? id,
    String? showroomId,
    String? customerId,
    String? invoiceId,
    String? bookingId,
    String? receiptNumber,
    DateTime? receiptDate,
    double? amount,
    String? paymentMode,
    String? paymentReference,
    String? bankName,
    String? collectedBy,
    String? notes,
    DateTime? createdAt,
    String? customerName,
  }) {
    return PaymentReceiptEntity(
      id: id ?? this.id,
      showroomId: showroomId ?? this.showroomId,
      customerId: customerId ?? this.customerId,
      invoiceId: invoiceId ?? this.invoiceId,
      bookingId: bookingId ?? this.bookingId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptDate: receiptDate ?? this.receiptDate,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentReference: paymentReference ?? this.paymentReference,
      bankName: bankName ?? this.bankName,
      collectedBy: collectedBy ?? this.collectedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
    );
  }

  @override
  List<Object?> get props => [id, receiptNumber, invoiceId, amount, paymentMode];
}
