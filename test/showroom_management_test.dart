import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybike/core/services/showroom_management_service.dart';
import 'package:mybike/core/services/showroom_service.dart';
import 'package:mybike/features/showroom/presentation/cubit/showroom_list_cubit.dart';
import 'package:mybike/features/showroom/presentation/cubit/showroom_list_state.dart';
import 'package:mybike/features/showroom/presentation/cubit/showroom_form_cubit.dart';
import 'package:mybike/features/showroom/presentation/cubit/showroom_form_state.dart';
import 'package:mybike/features/showroom/presentation/cubit/showroom_detail_cubit.dart';
import 'package:mybike/features/showroom/presentation/cubit/showroom_detail_state.dart';

import 'package:mybike/core/services/permission_service.dart';
import 'package:mybike/features/auth/domain/entities/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ShowroomManagementService.instance.resetDevData();
    PermissionService.instance.initialize(
      userProfile: UserProfile(
        id: 'admin-01',
        email: 'admin@mybike.com',
        roles: const ['super_admin'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  group('ShowroomListCubit', () {
    late ShowroomListCubit cubit;

    setUp(() {
      cubit = ShowroomListCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ShowroomListInitial', () {
      expect(cubit.state, isA<ShowroomListInitial>());
    });

    test('loadShowrooms emits Loading then Loaded with 3 seeded dev branches', () async {
      final states = <ShowroomListState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadShowrooms();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        isA<ShowroomListLoading>(),
        isA<ShowroomListLoaded>(),
      ]);

      final loaded = cubit.state as ShowroomListLoaded;
      expect(loaded.totalCount, 3);
      expect(loaded.activeCount, 3);
      expect(loaded.totalOperatingCities, 3);
      expect(loaded.totalStaffMapped, greaterThan(0));

      await sub.cancel();
    });

    test('searchShowrooms filters by city, name, or code', () async {
      await cubit.loadShowrooms();

      // Search by city
      await cubit.searchShowrooms('Pune');
      var state = cubit.state as ShowroomListLoaded;
      expect(state.showrooms.length, 1);
      expect(state.showrooms.first.showroom.code, 'IND-WEST');

      // Search by code
      await cubit.searchShowrooms('IND-MAIN');
      state = cubit.state as ShowroomListLoaded;
      expect(state.showrooms.length, 1);
      expect(state.showrooms.first.showroom.city, 'Mumbai');

      // Search non-existent
      await cubit.searchShowrooms('NonExistentCity');
      state = cubit.state as ShowroomListLoaded;
      expect(state.showrooms.isEmpty, true);
    });

    test('filterByActive filters active and inactive branches', () async {
      await cubit.loadShowrooms();

      // Deactivate one showroom
      await cubit.toggleShowroomStatus('sh-002', false);

      // Filter active
      await cubit.filterByActive(true);
      var state = cubit.state as ShowroomListLoaded;
      expect(state.showrooms.length, 2);
      for (final s in state.showrooms) {
        expect(s.showroom.isActive, true);
      }

      // Filter inactive
      await cubit.filterByActive(false);
      state = cubit.state as ShowroomListLoaded;
      expect(state.showrooms.length, 1);
      expect(state.showrooms.first.showroom.id, 'sh-002');
    });

    test('clearFilters resets all search and filter queries', () async {
      await cubit.loadShowrooms();
      await cubit.searchShowrooms('Mumbai');
      await cubit.filterByActive(true);

      await cubit.clearFilters();
      final state = cubit.state as ShowroomListLoaded;
      expect(state.searchQuery, isNull);
      expect(state.activeFilter, isNull);
      expect(state.totalCount, 3);
    });
  });

  group('ShowroomFormCubit', () {
    late ShowroomFormCubit cubit;

    setUp(() {
      cubit = ShowroomFormCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initNewShowroom sets up empty form with Indian states', () {
      cubit.initNewShowroom();
      expect(cubit.state, isA<ShowroomFormReady>());
      final state = cubit.state as ShowroomFormReady;
      expect(state.isEditMode, false);
      expect(state.existingShowroom, isNull);
      expect(state.availableStates.contains('Maharashtra'), true);
      expect(state.availableStates.contains('Karnataka'), true);
    });

    test('loadShowroomForEdit loads existing branch details', () async {
      await cubit.loadShowroomForEdit('sh-001');
      expect(cubit.state, isA<ShowroomFormReady>());
      final state = cubit.state as ShowroomFormReady;
      expect(state.isEditMode, true);
      expect(state.existingShowroom?.code, 'IND-MAIN');
      expect(state.existingShowroom?.gstin, '27AABCU9603R1ZM');
    });

    test('validation rejects invalid GSTIN format', () async {
      cubit.initNewShowroom();

      await cubit.saveShowroom(
        name: 'Test Showroom',
        code: 'TEST-01',
        address: '123 Main St',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001',
        phone: '+91 9999999999',
        gstin: 'INVALID_GST', // Invalid format
        invoicePrefix: 'TST',
      );

      expect(cubit.state, isA<ShowroomFormReady>());
    });

    test('validation rejects invalid PIN code', () async {
      cubit.initNewShowroom();

      await cubit.saveShowroom(
        name: 'Test Showroom',
        code: 'TEST-01',
        address: '123 Main St',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '0000', // Invalid PIN
        phone: '+91 9999999999',
        invoicePrefix: 'TST',
      );

      expect(cubit.state, isA<ShowroomFormReady>());
    });

    test('saveShowroom successfully creates a new showroom and generates sequences', () async {
      cubit.initNewShowroom();

      final states = <ShowroomFormState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.saveShowroom(
        name: 'MYBIKE North Hub',
        code: 'IND-NORTH',
        address: 'Sector 18, Noida Road',
        city: 'Delhi',
        state: 'Delhi',
        pincode: '110001',
        phone: '+91 11 2345 6789',
        email: 'delhi.north@mybike.com',
        gstin: '07AABCU9603R1Z5',
        pan: 'AABCU9603R',
        bankName: 'State Bank of India',
        bankAccountNumber: '302000112233',
        bankIfsc: 'SBIN0001234',
        bankBranch: 'Connaught Place',
        invoicePrefix: 'MB-DEL',
      );
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        isA<ShowroomFormSaving>(),
        isA<ShowroomFormSuccess>(),
      ]);

      final successState = cubit.state as ShowroomFormSuccess;
      expect(successState.showroom.code, 'IND-NORTH');
      expect(successState.showroom.invoicePrefix, 'MB-DEL');

      // Verify sequences were generated
      final seqs = await ShowroomManagementService.instance.fetchShowroomSequences(successState.showroom.id);
      expect(seqs.length, 5);

      await sub.cancel();
    });

    test('saveShowroom successfully updates an existing showroom', () async {
      await cubit.loadShowroomForEdit('sh-001');

      await cubit.saveShowroom(
        name: 'MYBIKE Flagship Central Updated',
        code: 'IND-MAIN',
        address: 'Updated Address',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400051',
        phone: '+91 22 2650 1000',
        invoicePrefix: 'MB-MUM',
      );

      expect(cubit.state, isA<ShowroomFormSuccess>());
      final updated = await ShowroomManagementService.instance.fetchShowroomById('sh-001');
      expect(updated?.name, 'MYBIKE Flagship Central Updated');
      expect(updated?.address, 'Updated Address');
    });
  });

  group('ShowroomDetailCubit', () {
    late ShowroomDetailCubit cubit;

    setUp(() {
      cubit = ShowroomDetailCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('loadShowroomDetail hydrates showroom, staff, and sequences', () async {
      await cubit.loadShowroomDetail('sh-001');
      expect(cubit.state, isA<ShowroomDetailLoaded>());

      final state = cubit.state as ShowroomDetailLoaded;
      expect(state.showroom.code, 'IND-MAIN');
      expect(state.sequences.length, 5);

      // Verify sequence preview formatting
      final invSeq = state.sequences.firstWhere((s) => s.docType == 'sale_invoice');
      expect(invSeq.prefix, 'MB-MUM-INV-');
      expect(invSeq.currentNumber, 184);
      expect(invSeq.nextNumber, 185);
      expect(invSeq.previewNextNumber, 'MB-MUM-INV-00185');
    });

    test('updateSequence modifies sequence parameters', () async {
      await cubit.loadShowroomDetail('sh-001');
      final state = cubit.state as ShowroomDetailLoaded;
      final seq = state.sequences.firstWhere((s) => s.docType == 'sale_invoice');

      await cubit.updateSequence(
        seq.id,
        prefix: 'NEW-MUM-INV-',
        nextNumber: 500,
        paddingZeros: 6,
      );

      final updatedState = cubit.state as ShowroomDetailLoaded;
      final updatedSeq = updatedState.sequences.firstWhere((s) => s.id == seq.id);
      expect(updatedSeq.prefix, 'NEW-MUM-INV-');
      expect(updatedSeq.currentNumber, 499);
      expect(updatedSeq.nextNumber, 500);
      expect(updatedSeq.paddingZeros, 6);
      expect(updatedSeq.previewNextNumber, 'NEW-MUM-INV-000500');
    });

    test('switchOperatingShowroom updates active branch context', () async {
      await cubit.loadShowroomDetail('sh-002');
      await cubit.switchOperatingShowroom('sh-002');

      expect(ShowroomService.instance.activeShowroom?.code, 'IND-WEST');
    });
  });

  group('InvoiceSequenceEntity', () {
    test('previewNextNumber handles zero padding correctly', () {
      final now = DateTime.now();
      final seq = InvoiceSequenceEntity(
        id: '1',
        showroomId: 'sh-1',
        docType: 'sale_invoice',
        prefix: 'MB-INV-',
        currentNumber: 7,
        paddingZeros: 5,
        createdAt: now,
        updatedAt: now,
      );

      expect(seq.nextNumber, 8);
      expect(seq.previewNextNumber, 'MB-INV-00008');
    });
  });
}
