import 'package:equatable/equatable.dart';
import '../../domain/entities/sales_invoice_entity.dart';
import '../../../customers/domain/entities/customer_entity.dart';

class BookingWizardState extends Equatable {
  final int currentStep; // 0: Customer, 1: Vehicle, 2: Pricing, 3: Payment, 4: Review
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final SalesInvoiceEntity? savedInvoice;

  // Step 0: Customer & Showroom
  final String? selectedShowroomId;
  final String? selectedCustomerId;
  final String customerName;
  final String customerMobile;
  final List<CustomerEntity> availableCustomers;
  final List<CustomerEntity> filteredCustomers;
  final bool isLoadingCustomers;
  final String customerSearchQuery;
  final CustomerEntity? selectedCustomer;

  // Step 1: Vehicle & Color
  final String? selectedModelId;
  final String? selectedModelName;
  final String? selectedVariantId;
  final String? selectedVariantName;
  final String? selectedColorId;
  final String? selectedColorName;
  final String? selectedColorHex;
  final String? selectedVin;
  final bool isEv;

  // Step 2: Pricing & Taxes (INR)
  final double exShowroomPrice;
  final double discountAmount;
  final double gstRate; // 28.0 (Petrol) or 5.0 (EV)
  final double rtoCharges;
  final double insuranceCharges;
  final double accessoriesTotal;
  final double extendedWarrantyAmount;
  final double fastagCharges;
  final double hypothecationCharges;

  // Step 3: Payment & Settlement
  final double bookingAdvanceAdjusted;
  final double financeAmount;
  final String? financeBank;
  final double exchangeAllowance;
  final double downPaymentPaid;
  final String paymentMode; // 'upi', 'cash', 'card', 'neft_rtgs'

  const BookingWizardState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.savedInvoice,
    this.selectedShowroomId,
    this.selectedCustomerId,
    this.customerName = '',
    this.customerMobile = '',
    this.availableCustomers = const [],
    this.filteredCustomers = const [],
    this.isLoadingCustomers = false,
    this.customerSearchQuery = '',
    this.selectedCustomer,
    this.selectedModelId,
    this.selectedModelName,
    this.selectedVariantId,
    this.selectedVariantName,
    this.selectedColorId,
    this.selectedColorName,
    this.selectedColorHex,
    this.selectedVin,
    this.isEv = false,
    this.exShowroomPrice = 0.0,
    this.discountAmount = 0.0,
    this.gstRate = 28.0,
    this.rtoCharges = 0.0,
    this.insuranceCharges = 0.0,
    this.accessoriesTotal = 0.0,
    this.extendedWarrantyAmount = 0.0,
    this.fastagCharges = 0.0,
    this.hypothecationCharges = 0.0,
    this.bookingAdvanceAdjusted = 0.0,
    this.financeAmount = 0.0,
    this.financeBank,
    this.exchangeAllowance = 0.0,
    this.downPaymentPaid = 0.0,
    this.paymentMode = 'upi',
  });

  // ─── Computed Pricing Getters ───

  /// Taxable Value = Ex-showroom - Discount (inclusive of GST reverse calculated)
  double get netExShowroom => (exShowroomPrice - discountAmount).clamp(0.0, double.infinity);

  double get taxableAmount {
    // Net Ex-showroom = Taxable * (1 + GST / 100)
    return netExShowroom / (1 + (gstRate / 100));
  }

  double get totalGst => netExShowroom - taxableAmount;
  double get cgstAmount => totalGst / 2;
  double get sgstAmount => totalGst / 2;

  double get totalOnRoadPrice {
    return netExShowroom +
        rtoCharges +
        insuranceCharges +
        accessoriesTotal +
        extendedWarrantyAmount +
        fastagCharges +
        hypothecationCharges;
  }

  double get totalPaid => bookingAdvanceAdjusted + financeAmount + exchangeAllowance + downPaymentPaid;
  double get balanceAmount => (totalOnRoadPrice - totalPaid).clamp(0.0, double.infinity);
  bool get isFullyPaid => balanceAmount <= 0;

  bool get canProceedStep0 => customerName.trim().isNotEmpty && customerMobile.trim().length >= 10;
  bool get canProceedStep1 => selectedVariantId != null && selectedColorId != null;
  bool get canProceedStep2 => exShowroomPrice > 0;
  bool get canProceedStep3 => true;

  BookingWizardState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isSaving,
    String? error,
    SalesInvoiceEntity? savedInvoice,
    String? selectedShowroomId,
    String? selectedCustomerId,
    String? customerName,
    String? customerMobile,
    List<CustomerEntity>? availableCustomers,
    List<CustomerEntity>? filteredCustomers,
    bool? isLoadingCustomers,
    String? customerSearchQuery,
    CustomerEntity? selectedCustomer,
    bool clearSelectedCustomer = false,
    bool clearSelectedColor = false,
    String? selectedModelId,
    String? selectedModelName,
    String? selectedVariantId,
    String? selectedVariantName,
    String? selectedColorId,
    String? selectedColorName,
    String? selectedColorHex,
    String? selectedVin,
    bool? isEv,
    double? exShowroomPrice,
    double? discountAmount,
    double? gstRate,
    double? rtoCharges,
    double? insuranceCharges,
    double? accessoriesTotal,
    double? extendedWarrantyAmount,
    double? fastagCharges,
    double? hypothecationCharges,
    double? bookingAdvanceAdjusted,
    double? financeAmount,
    String? financeBank,
    double? exchangeAllowance,
    double? downPaymentPaid,
    String? paymentMode,
  }) {
    return BookingWizardState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      savedInvoice: savedInvoice ?? this.savedInvoice,
      selectedShowroomId: selectedShowroomId ?? this.selectedShowroomId,
      selectedCustomerId: clearSelectedCustomer ? null : (selectedCustomerId ?? this.selectedCustomerId),
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      availableCustomers: availableCustomers ?? this.availableCustomers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
      customerSearchQuery: customerSearchQuery ?? this.customerSearchQuery,
      selectedCustomer: clearSelectedCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      selectedModelId: selectedModelId ?? this.selectedModelId,
      selectedModelName: selectedModelName ?? this.selectedModelName,
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
      selectedVariantName: selectedVariantName ?? this.selectedVariantName,
      selectedColorId: clearSelectedColor ? null : (selectedColorId ?? this.selectedColorId),
      selectedColorName: clearSelectedColor ? null : (selectedColorName ?? this.selectedColorName),
      selectedColorHex: clearSelectedColor ? null : (selectedColorHex ?? this.selectedColorHex),
      selectedVin: selectedVin ?? this.selectedVin,
      isEv: isEv ?? this.isEv,
      exShowroomPrice: exShowroomPrice ?? this.exShowroomPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      gstRate: gstRate ?? this.gstRate,
      rtoCharges: rtoCharges ?? this.rtoCharges,
      insuranceCharges: insuranceCharges ?? this.insuranceCharges,
      accessoriesTotal: accessoriesTotal ?? this.accessoriesTotal,
      extendedWarrantyAmount: extendedWarrantyAmount ?? this.extendedWarrantyAmount,
      fastagCharges: fastagCharges ?? this.fastagCharges,
      hypothecationCharges: hypothecationCharges ?? this.hypothecationCharges,
      bookingAdvanceAdjusted: bookingAdvanceAdjusted ?? this.bookingAdvanceAdjusted,
      financeAmount: financeAmount ?? this.financeAmount,
      financeBank: financeBank ?? this.financeBank,
      exchangeAllowance: exchangeAllowance ?? this.exchangeAllowance,
      downPaymentPaid: downPaymentPaid ?? this.downPaymentPaid,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isLoading,
        isSaving,
        error,
        savedInvoice,
        selectedShowroomId,
        selectedCustomerId,
        customerName,
        customerMobile,
        availableCustomers,
        filteredCustomers,
        isLoadingCustomers,
        customerSearchQuery,
        selectedCustomer,
        selectedModelId,
        selectedVariantId,
        selectedColorId,
        selectedVin,
        exShowroomPrice,
        discountAmount,
        totalOnRoadPrice,
        totalPaid,
        balanceAmount,
      ];
}
