-- ============================================================================
-- MYBIKE Dealership Operational Data Seed Script
-- Populates real operational records strictly conforming to database check constraints
-- ============================================================================

DO $$
DECLARE
  v_showroom_mum UUID := '643cbe40-8f72-400b-9c8e-a1c372e0be60'; -- Mumbai Flagship
  v_showroom_pun UUID := '90cfc09a-5d7f-4890-8a8b-c57c830dbf55'; -- Pune West Hub
  v_showroom_blr UUID := '589c1835-940d-4fcf-ab35-da31a0502825'; -- Bengaluru Metro
  v_showroom_del UUID := '14708474-232f-4c6b-8cac-8caff421b623'; -- Delhi NCR Hub

  v_sup_honda UUID := '1b488739-f18f-48da-adf0-dc98a3a121b0';
  v_sup_ather UUID := 'c8fa504f-8889-496f-aeff-174599bedafe';
  v_sup_tvs   UUID := '70918fba-d0c0-417f-b1f7-6bd5c27eb97c';

  v_var_cb350  UUID := 'ed20dcc6-3ecd-4275-9bcf-fef5170167a1';
  v_col_cb350  UUID := 'dc7007fe-1686-4afa-a1dd-672bc73489e6';

  v_var_activa UUID := 'fe430c3a-3e29-4aab-9c4d-37ed84771853';
  v_col_activa UUID := '6d18fe64-5b46-49f1-b2fb-7923790b27d3';

  v_var_ather  UUID := 'c7b5277d-e8b4-48ef-8ccf-38a6c9023d2a';
  v_col_ather  UUID;

  v_var_rtr    UUID := '274bff7a-db20-4338-911a-523fdd27f7ef';
  v_col_rtr    UUID;

  v_cust_1 UUID := 'a1111111-1111-4111-8111-111111111111';
  v_cust_2 UUID := 'a2222222-2222-4222-8222-222222222222';
  v_cust_3 UUID := 'a3333333-3333-4333-8333-333333333333';
  v_cust_4 UUID := 'a4444444-4444-4444-8444-444444444444';
  v_cust_5 UUID := 'a5555555-5555-4555-8555-555555555555';

  v_veh_1 UUID := 'b1111111-1111-4111-8111-111111111111';
  v_veh_2 UUID := 'b2222222-2222-4222-8222-222222222222';
  v_veh_3 UUID := 'b3333333-3333-4333-8333-333333333333';
  v_veh_4 UUID := 'b4444444-4444-4444-8444-444444444444';
  v_veh_5 UUID := 'b5555555-5555-4555-8555-555555555555';
  v_veh_6 UUID := 'b6666666-6666-4666-8666-666666666666';

  v_po_1 UUID := 'd1111111-1111-4111-8111-111111111111';
  v_po_2 UUID := 'd2222222-2222-4222-8222-222222222222';
  v_po_3 UUID := 'd3333333-3333-4333-8333-333333333333';

  v_inv_1 UUID := 'e1111111-1111-4111-8111-111111111111';
  v_inv_2 UUID := 'e2222222-2222-4222-8222-222222222222';
  v_inv_3 UUID := 'e3333333-3333-4333-8333-333333333333';

  v_bk_1 UUID := 'f1111111-1111-4111-8111-111111111111';
  v_bk_2 UUID := 'f2222222-2222-4222-8222-222222222222';

  v_acc_cash UUID := '13977dc9-13f7-4f96-874a-a056eaea3996';
  v_acc_bank UUID := 'a36d4955-9e65-4335-a33e-074b56aadd6b';
  v_acc_sales UUID := '80dcc912-e74c-4e68-8117-bb8987480cee';
BEGIN
  -- Select matching color for ather and rtr
  SELECT id INTO v_col_ather FROM vehicle_colors WHERE model_id = (SELECT model_id FROM vehicle_variants WHERE id = v_var_ather) LIMIT 1;
  SELECT id INTO v_col_rtr FROM vehicle_colors WHERE model_id = (SELECT model_id FROM vehicle_variants WHERE id = v_var_rtr) LIMIT 1;

  -- 1. SEED REAL CUSTOMERS
  INSERT INTO public.customers (
    id, showroom_id, customer_number, first_name, last_name, mobile_primary, email,
    city, state, pin_code, kyc_status, customer_type, is_active, created_at, updated_at
  ) VALUES
  (
    v_cust_1, v_showroom_mum, 'CUST-2026-0001', 'Rajesh', 'Sharma', '9820112233', 'rajesh.sharma@gmail.com',
    'Mumbai', 'Maharashtra', '400050', 'verified', 'individual', true, NOW() - INTERVAL '15 days', NOW()
  ),
  (
    v_cust_2, v_showroom_pun, 'CUST-2026-0002', 'Sneha', 'Patil', '9890223344', 'sneha.patil@yahoo.co.in',
    'Pune', 'Maharashtra', '411004', 'verified', 'individual', true, NOW() - INTERVAL '10 days', NOW()
  ),
  (
    v_cust_3, v_showroom_blr, 'CUST-2026-0003', 'Vikram', 'Iyer', '9845334455', 'vikram.iyer@outlook.com',
    'Bengaluru', 'Karnataka', '560038', 'verified', 'individual', true, NOW() - INTERVAL '7 days', NOW()
  ),
  (
    v_cust_4, v_showroom_del, 'CUST-2026-0004', 'Amit', 'Verma', '9811445566', 'amit.verma@gmail.com',
    'Delhi', 'Delhi', '110001', 'verified', 'individual', true, NOW() - INTERVAL '5 days', NOW()
  ),
  (
    v_cust_5, v_showroom_mum, 'CUST-2026-0005', 'Rahul', 'Mehta', '9820556677', 'rahul.mehta@corporatesolutions.in',
    'Mumbai', 'Maharashtra', '400001', 'verified', 'corporate', true, NOW() - INTERVAL '2 days', NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  -- 2. SEED REAL INVENTORY VEHICLES (status: 'in_stock', 'booked', 'delivered')
  INSERT INTO public.inventory_vehicles (
    id, showroom_id, variant_id, color_id, vin, engine_number, motor_number, key_number,
    status, purchase_cost, received_date, mfg_year_month, odometer_reading_km, location_in_showroom,
    pdi_status, created_at, updated_at
  ) VALUES
  (
    v_veh_1, v_showroom_mum, v_var_cb350, v_col_cb350, 'ME4NC5800N800101', 'NC58E800101', NULL, 'KEY-CB-01',
    'delivered', 178000.00, CURRENT_DATE - 14, '2026-03', 1.0, 'Bay 1', 'passed', NOW() - INTERVAL '14 days', NOW()
  ),
  (
    v_veh_2, v_showroom_pun, v_var_activa, v_col_activa, 'ME4JF9100N800202', 'JF91E800202', NULL, 'KEY-ACT-02',
    'delivered', 62500.00, CURRENT_DATE - 10, '2026-03', 2.0, 'Bay 2', 'passed', NOW() - INTERVAL '10 days', NOW()
  ),
  (
    v_veh_3, v_showroom_blr, v_var_ather, v_col_ather, 'MALJA450XN800303', NULL, 'MOT-ATH-800303', 'KEY-ATH-03',
    'delivered', 128000.00, CURRENT_DATE - 6, '2026-04', 3.0, 'EV Zone', 'passed', NOW() - INTERVAL '6 days', NOW()
  ),
  (
    v_veh_4, v_showroom_mum, v_var_cb350, v_col_cb350, 'ME4NC5800N800404', 'NC58E800404', NULL, 'KEY-CB-04',
    'in_stock', 178000.00, CURRENT_DATE - 4, '2026-04', 0.5, 'Showroom Floor', 'passed', NOW() - INTERVAL '4 days', NOW()
  ),
  (
    v_veh_5, v_showroom_pun, v_var_rtr, v_col_rtr, 'MD625AC30N800505', 'AC3E800505', NULL, 'KEY-RTR-05',
    'in_stock', 115000.00, CURRENT_DATE - 3, '2026-04', 0.8, 'Display Line', 'passed', NOW() - INTERVAL '3 days', NOW()
  ),
  (
    v_veh_6, v_showroom_blr, v_var_activa, v_col_activa, 'ME4JF9100N800606', 'JF91E800606', NULL, 'KEY-ACT-06',
    'booked', 62500.00, CURRENT_DATE - 2, '2026-04', 1.0, 'Storage Yard', 'passed', NOW() - INTERVAL '2 days', NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  -- 3. SEED REAL BOOKINGS (status: 'pending', 'confirmed', 'allocated', 'delivered')
  INSERT INTO public.bookings (
    id, showroom_id, customer_id, booking_number, variant_id, color_id,
    booking_amount, payment_mode, payment_reference, ex_showroom_price, on_road_price,
    status, expected_delivery_date, created_at, updated_at
  ) VALUES
  (
    v_bk_1, v_showroom_blr, v_cust_3, 'BK-2026-0001', v_var_activa, v_col_activa,
    10000.00, 'upi', 'UPI-BK-9182', 82500.00, 99350.00,
    'confirmed', CURRENT_DATE + 5, NOW() - INTERVAL '2 days', NOW()
  ),
  (
    v_bk_2, v_showroom_mum, v_cust_5, 'BK-2026-0002', v_var_cb350, v_col_cb350,
    25000.00, 'neft', 'NEFT-BK-3321', 217800.00, 266004.00,
    'confirmed', CURRENT_DATE + 7, NOW() - INTERVAL '1 day', NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  -- 4. SEED REAL PURCHASE ORDERS (category: 'new_vehicle', status: 'sent', 'partial', 'received')
  INSERT INTO public.purchase_orders (
    id, showroom_id, supplier_id, po_number, order_date, expected_delivery_date,
    purchase_category, subtotal, tax_amount, total_amount, paid_amount, payment_status,
    status, notes, created_at, updated_at
  ) VALUES
  (
    v_po_1, v_showroom_mum, v_sup_honda, 'PO-2026-0001', CURRENT_DATE - 20, CURRENT_DATE - 14,
    'new_vehicle', 1202500.00, 336700.00, 1539200.00, 1539200.00, 'paid',
    'received', 'Batch delivery of 5 Honda two-wheelers', NOW() - INTERVAL '20 days', NOW()
  ),
  (
    v_po_2, v_showroom_blr, v_sup_ather, 'PO-2026-0002', CURRENT_DATE - 12, CURRENT_DATE - 6,
    'new_vehicle', 512000.00, 25600.00, 537600.00, 537600.00, 'paid',
    'received', 'Ather 450X Pro units allocation', NOW() - INTERVAL '12 days', NOW()
  ),
  (
    v_po_3, v_showroom_pun, v_sup_tvs, 'PO-2026-0003', CURRENT_DATE - 5, CURRENT_DATE + 3,
    'new_vehicle', 460000.00, 128800.00, 588800.00, 200000.00, 'partial',
    'partial', 'Apache RTR stock replenishment', NOW() - INTERVAL '5 days', NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.purchase_order_items (
    purchase_order_id, line_number, item_type, description, quantity,
    received_quantity, unit_price, tax_rate, line_total, created_at
  ) VALUES
  (v_po_1, 1, 'new_vehicle', 'Honda CB350 DLX Pro Dual Tone', 3, 3, 178000.00, 28.0, 683520.00, NOW() - INTERVAL '20 days'),
  (v_po_1, 2, 'new_vehicle', 'Honda Activa 6G Deluxe', 4, 4, 62500.00, 28.0, 320000.00, NOW() - INTERVAL '20 days'),
  (v_po_2, 1, 'new_vehicle', 'Ather 450X 3.7 kWh Pro', 4, 4, 128000.00, 5.0, 537600.00, NOW() - INTERVAL '12 days'),
  (v_po_3, 1, 'new_vehicle', 'Apache RTR 160 4V Dual Channel ABS', 4, 2, 115000.00, 28.0, 588800.00, NOW() - INTERVAL '5 days')
  ON CONFLICT DO NOTHING;

  -- 5. SEED REAL SALES INVOICES (status: 'delivered', 'issued')
  INSERT INTO public.sales_invoices (
    id, showroom_id, customer_id, vehicle_inventory_id, invoice_number, invoice_date,
    variant_id, color_id, vin, engine_number, hsn_code, gst_rate, is_interstate,
    ex_showroom_price, discount_amount, taxable_amount, cgst_amount, sgst_amount, igst_amount,
    rto_charges, insurance_charges, accessories_total, extended_warranty_amount, fastag_charges,
    hypothecation_charges, tcs_amount, round_off, total_on_road_price, booking_advance_adjusted,
    finance_amount, finance_bank, exchange_allowance, amount_paid, balance_amount, payment_status,
    status, notes, created_at, updated_at
  ) VALUES
  (
    v_inv_1, v_showroom_mum, v_cust_1, v_veh_1, 'INV-2026-0001', CURRENT_DATE - 12,
    v_var_cb350, v_col_cb350, 'ME4NC5800N800101', 'NC58E800101', '8711', 28.00, false,
    217800.00, 3000.00, 167812.50, 23493.75, 23493.75, 0.00,
    26136.00, 13068.00, 4500.00, 2500.00, 500.00,
    1500.00, 0.00, 0.00, 266004.00, 25000.00,
    150000.00, 'HDFC Bank', 0.00, 266004.00, 0.00, 'paid',
    'delivered', 'Full settlement received. Vehicle delivered.', NOW() - INTERVAL '12 days', NOW()
  ),
  (
    v_inv_2, v_showroom_pun, v_cust_2, v_veh_2, 'INV-2026-0002', CURRENT_DATE - 8,
    v_var_activa, v_col_activa, 'ME4JF9100N800202', 'JF91E800202', '8711', 28.00, false,
    82500.00, 1000.00, 63671.88, 8914.06, 8914.06, 0.00,
    9900.00, 4950.00, 1800.00, 1200.00, 0.00,
    0.00, 0.00, 0.00, 99350.00, 10000.00,
    0.00, NULL, 0.00, 99350.00, 0.00, 'paid',
    'delivered', 'Cash & UPI settlement.', NOW() - INTERVAL '8 days', NOW()
  ),
  (
    v_inv_3, v_showroom_blr, v_cust_3, v_veh_3, 'INV-2026-0003', CURRENT_DATE - 4,
    v_var_ather, v_col_ather, 'MALJA450XN800303', NULL, '8711', 5.00, false,
    154999.00, 2000.00, 145713.33, 3642.83, 3642.83, 0.00,
    7750.00, 6200.00, 3500.00, 2000.00, 0.00,
    0.00, 0.00, 0.00, 172449.00, 10000.00,
    100000.00, 'State Bank of India', 0.00, 172449.00, 0.00, 'paid',
    'delivered', 'EV subsidy applied. Dispatched with charger.', NOW() - INTERVAL '4 days', NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  -- 6. SEED REAL FINANCE VOUCHERS (voucher_type: 'payment', 'receipt', 'expense')
  INSERT INTO public.finance_vouchers (
    id, showroom_id, voucher_number, voucher_type, voucher_date, party_type, party_name,
    amount, net_amount, payment_mode, reference_number, narration, status, source_account_id,
    destination_account_id
  ) VALUES
  (
    'c1111111-1111-4111-8111-111111111111', v_showroom_mum, 'RV-2026-0001', 'receipt', CURRENT_DATE - 12,
    'customer', 'Rajesh Sharma', 91004.00, 91004.00, 'bank_transfer', 'HDFC-RTGS-9821',
    'Payment receipt for CB350 delivery INV-2026-0001', 'posted',
    v_acc_bank, v_acc_sales
  ),
  (
    'c2222222-2222-4222-8222-222222222222', v_showroom_pun, 'RV-2026-0002', 'receipt', CURRENT_DATE - 8,
    'customer', 'Sneha Patil', 89350.00, 89350.00, 'upi', 'UPI-9831-PUN',
    'Payment receipt for Activa 6G INV-2026-0002', 'posted',
    v_acc_cash, v_acc_sales
  ),
  (
    'c3333333-3333-4333-8333-333333333333', v_showroom_mum, 'PV-2026-0001', 'payment', CURRENT_DATE - 15,
    'supplier', 'Honda Motorcycle & Scooter India', 500000.00, 500000.00, 'bank_transfer', 'NEFT-MUM-8812',
    'Advance payment against PO-2026-0001', 'posted',
    v_acc_bank, v_acc_cash
  )
  ON CONFLICT (id) DO NOTHING;

END $$;
