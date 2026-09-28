import '../../domain/entities/vehicle_variant_entity.dart';

/// Vehicle Variant Data Model with JSON serialization for Supabase
class VehicleVariantModel extends VehicleVariantEntity {
  const VehicleVariantModel({
    required super.id,
    required super.modelId,
    required super.name,
    required super.code,
    super.engineCc,
    super.maxPower,
    super.maxTorque,
    super.fuelCapacityLiters,
    super.mileageKmpl,
    super.transmission,
    super.emissionNorm,
    super.batteryCapacityKwh,
    super.motorPowerKw,
    super.rangeKm,
    super.trueRangeKm,
    super.chargingTimeHours,
    super.fastCharging = false,
    super.batteryWarrantyYears,
    required super.exShowroomPrice,
    super.gstRate = 28.0,
    super.cessRate = 0.0,
    super.rtoCharges = 0.0,
    super.insuranceCharges = 0.0,
    super.otherCharges = 0.0,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VehicleVariantModel.fromJson(Map<String, dynamic> json) {
    return VehicleVariantModel(
      id: json['id'] as String,
      modelId: json['model_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      engineCc: ((json['engine_cc'] ?? json['engine_capacity_cc']) as num?)?.toDouble(),
      maxPower: (json['max_power'] ?? (json['max_power_bhp'] != null ? '${json['max_power_bhp']} bhp' : null)) as String?,
      maxTorque: (json['max_torque'] ?? (json['max_torque_nm'] != null ? '${json['max_torque_nm']} Nm' : null)) as String?,
      fuelCapacityLiters: ((json['fuel_capacity_liters'] ?? json['fuel_tank_capacity_l']) as num?)?.toDouble(),
      mileageKmpl: (json['mileage_kmpl'] as num?)?.toDouble(),
      transmission: json['transmission'] as String?,
      emissionNorm: json['emission_norm'] as String?,
      batteryCapacityKwh: (json['battery_capacity_kwh'] as num?)?.toDouble(),
      motorPowerKw: (json['motor_power_kw'] as num?)?.toDouble(),
      rangeKm: ((json['range_km'] ?? json['certified_range_km']) as num?)?.toInt(),
      trueRangeKm: (json['true_range_km'] as num?)?.toInt(),
      chargingTimeHours: (json['charging_time_hours'] as num?)?.toDouble(),
      fastCharging: (json['fast_charging'] ?? json['fast_charging_support']) as bool? ?? false,
      batteryWarrantyYears: (json['battery_warranty_years'] as num?)?.toInt(),
      exShowroomPrice: (json['ex_showroom_price'] as num?)?.toDouble() ?? 0.0,
      gstRate: ((json['gst_rate'] ?? json['gst_rate_percent']) as num?)?.toDouble() ?? 28.0,
      cessRate: ((json['cess_rate'] ?? json['cess_percent']) as num?)?.toDouble() ?? 0.0,
      rtoCharges: (json['rto_charges'] as num?)?.toDouble() ?? 0.0,
      insuranceCharges: (json['insurance_charges'] as num?)?.toDouble() ?? 0.0,
      otherCharges: ((json['other_charges'] ?? json['handling_charges']) as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model_id': modelId,
      'name': name,
      'code': code,
      'engine_cc': engineCc,
      'max_power': maxPower,
      'max_torque': maxTorque,
      'fuel_capacity_liters': fuelCapacityLiters,
      'mileage_kmpl': mileageKmpl,
      'transmission': transmission,
      'emission_norm': emissionNorm,
      'battery_capacity_kwh': batteryCapacityKwh,
      'motor_power_kw': motorPowerKw,
      'range_km': rangeKm,
      'true_range_km': trueRangeKm,
      'charging_time_hours': chargingTimeHours,
      'fast_charging': fastCharging,
      'battery_warranty_years': batteryWarrantyYears,
      'ex_showroom_price': exShowroomPrice,
      'gst_rate': gstRate,
      'cess_rate': cessRate,
      'rto_charges': rtoCharges,
      'insurance_charges': insuranceCharges,
      'other_charges': otherCharges,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VehicleVariantModel.fromEntity(VehicleVariantEntity entity) {
    return VehicleVariantModel(
      id: entity.id,
      modelId: entity.modelId,
      name: entity.name,
      code: entity.code,
      engineCc: entity.engineCc,
      maxPower: entity.maxPower,
      maxTorque: entity.maxTorque,
      fuelCapacityLiters: entity.fuelCapacityLiters,
      mileageKmpl: entity.mileageKmpl,
      transmission: entity.transmission,
      emissionNorm: entity.emissionNorm,
      batteryCapacityKwh: entity.batteryCapacityKwh,
      motorPowerKw: entity.motorPowerKw,
      rangeKm: entity.rangeKm,
      trueRangeKm: entity.trueRangeKm,
      chargingTimeHours: entity.chargingTimeHours,
      fastCharging: entity.fastCharging,
      batteryWarrantyYears: entity.batteryWarrantyYears,
      exShowroomPrice: entity.exShowroomPrice,
      gstRate: entity.gstRate,
      cessRate: entity.cessRate,
      rtoCharges: entity.rtoCharges,
      insuranceCharges: entity.insuranceCharges,
      otherCharges: entity.otherCharges,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
