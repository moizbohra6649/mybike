import 'package:flutter_test/flutter_test.dart';
import 'package:mybike/core/config/app_config.dart';
import 'package:mybike/core/config/supabase_config.dart';
import 'package:mybike/features/auth/data/models/user_profile_model.dart';
import 'package:mybike/features/roles/data/models/role_model.dart';
import 'package:mybike/features/showroom/data/models/showroom_model.dart';
import 'package:mybike/features/finance/data/models/financial_year_model.dart';

void main() {
  group('Phase 3 — Database Foundation & Models Tests', () {
    test('UserProfileModel parses JSON and verifies role/showroom access', () {
      final json = {
        'id': 'u-123',
        'email': 'admin@mybike.com',
        'full_name': 'Moiz Bohra',
        'is_active': true,
        'roles': ['super_admin'],
        'user_showrooms': [
          {'showroom_id': 'sh-001', 'is_default': true}
        ],
        'created_at': '2026-04-01T10:00:00.000Z',
        'updated_at': '2026-04-01T10:00:00.000Z',
      };

      final profile = UserProfileModel.fromJson(json);

      expect(profile.id, 'u-123');
      expect(profile.email, 'admin@mybike.com');
      expect(profile.fullName, 'Moiz Bohra');
      expect(profile.isSuperAdmin, isTrue);
      expect(profile.isAdmin, isTrue);
      expect(profile.hasShowroomAccess('sh-001'), isTrue);
      expect(profile.hasShowroomAccess('sh-other'), isTrue); // Super Admin has access to all
      expect(profile.defaultShowroomId, 'sh-001');

      final serialized = profile.toJson();
      expect(serialized['email'], 'admin@mybike.com');
      expect(serialized['full_name'], 'Moiz Bohra');
    });

    test('ShowroomModel parses JSON and computes full address', () {
      final json = {
        'id': 'sh-001',
        'name': 'MYBIKE Flagship Central',
        'code': 'IND-MAIN',
        'address': 'Plot 42, Automobile Hub',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'pincode': '400050',
        'phone': '+91 98200 12345',
        'invoice_prefix': 'MBMUM',
        'is_active': true,
        'created_at': '2026-04-01T10:00:00.000Z',
        'updated_at': '2026-04-01T10:00:00.000Z',
      };

      final showroom = ShowroomModel.fromJson(json);

      expect(showroom.code, 'IND-MAIN');
      expect(showroom.fullAddress, 'Plot 42, Automobile Hub, Mumbai, Maharashtra - 400050');
      expect(showroom.invoicePrefix, 'MBMUM');
    });

    test('RoleModel and PermissionModel evaluate module permissions', () {
      final json = {
        'id': 'r-001',
        'name': 'sales_manager',
        'display_name': 'Sales Manager',
        'permissions': [
          {'id': 'p-1', 'module': 'sales', 'action': 'view'},
          {'id': 'p-2', 'module': 'sales', 'action': 'approve'},
        ],
      };

      final role = RoleModel.fromJson(json);

      expect(role.displayName, 'Sales Manager');
      expect(role.hasPermission('sales', 'view'), isTrue);
      expect(role.hasPermission('sales', 'approve'), isTrue);
      expect(role.hasPermission('accounting', 'view'), isFalse);
    });

    test('FinancialYearModel validates date ranges and period containment', () {
      final json = {
        'id': 'fy-001',
        'name': '2026-27',
        'start_date': '2026-04-01',
        'end_date': '2027-03-31',
        'is_current': true,
        'is_locked': false,
        'created_at': '2026-04-01T10:00:00.000Z',
        'updated_at': '2026-04-01T10:00:00.000Z',
      };

      final fy = FinancialYearModel.fromJson(json);

      expect(fy.name, '2026-27');
      expect(fy.isCurrent, isTrue);
      expect(fy.containsDate(DateTime(2026, 9, 18)), isTrue);
      expect(fy.containsDate(DateTime(2025, 12, 31)), isFalse);
    });

    test('SupabaseConfig operates safely in default/placeholder environment', () {
      AppConfig.setEnvironment(
        Environment.development,
        customUrl: 'https://dev-erp.mybike.internal',
        customAnonKey: 'dev_anon_key_placeholder',
      );
      expect(SupabaseConfig.isConfigured, isFalse);
    });
  });
}
