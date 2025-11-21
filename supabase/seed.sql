insert into auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        raw_app_meta_data,
        raw_user_meta_data,
        email_confirmed_at,
        created_at
    )
values (
        '00000000-0000-0000-0000-000000000000',
        '1405a312-949d-4cb1-a926-a4b6a8e1fdff',
        'authenticated',
        'authenticated',
        'reviewer1@email.com',
        '$2a$10$X7TFGZxsEHV.WuDT1KoV5u9nMFIdhmDycTBer.qlTiTIN1kx067Ge',
        '{"provider":"email","providers":["email"]}',
        '{}',
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        '3042a462-c5ca-45ca-973c-6d59e2c69c1d',
        'authenticated',
        'authenticated',
        'admin1@email.com',
        '$2a$10$JgmamB1Dzt6t48J8kKybJuBkODQtE0DLpiK9wQyN3vMdTi/2A49Lu',
        '{"provider":"email","providers":["email"]}',
        '{}',
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        '53b1dc1b-6ad9-4fdd-a469-872cab371913',
        'authenticated',
        'authenticated',
        'manager1@email.com',
        '$2a$10$7cXc15s1ZgLuRjKEVF41BeH8N0zPUU5rudDLpMdaiWCeYAylPCadW',
        '{"provider":"email","providers":["email"]}',
        '{}',
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        '94d127fb-860e-45a7-a30f-dbb982e10b3f',
        'authenticated',
        'authenticated',
        'reviewer2@email.com',
        '$2a$10$4jbqp65G.IKUcoephLpQteMxB4S2eTZuKQ4IwHMwCkMWAwzxQAN4.',
        '{"provider":"email","providers":["email"]}',
        '{}',
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        'authenticated',
        'authenticated',
        'manager2@email.com',
        '$2a$10$o8ZywWLn/klPpiUKxl8pE.e5aHoTOkjeSqbTK4MkN1NlsUSCNeed2',
        '{"provider":"email","providers":["email"]}',
        '{}',
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        'ec422962-e6c7-4d39-9809-f46010a826a3',
        'authenticated',
        'authenticated',
        'reviewer3@email.com',
        '$2a$10$rDW1fmBh/up/9wnV2SHFC.W0dUtjpo5tsF4R5tayd.HL49mlBFJvC',
        '{"provider":"email","providers":["email"]}',
        '{}',
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    );
insert into auth.identities (
        id,
        provider_id,
        user_id,
        identity_data,
        provider,
        created_at
    )
values (
        '1405a312-949d-4cb1-a926-a4b6a8e1fdff',
        '1405a312-949d-4cb1-a926-a4b6a8e1fdff',
        '1405a312-949d-4cb1-a926-a4b6a8e1fdff',
        '{"sub": "1405a312-949d-4cb1-a926-a4b6a8e1fdff"}',
        'email',
        timezone('utc'::text, now())
    ),
    (
        '3042a462-c5ca-45ca-973c-6d59e2c69c1d',
        '3042a462-c5ca-45ca-973c-6d59e2c69c1d',
        '3042a462-c5ca-45ca-973c-6d59e2c69c1d',
        '{"sub": "3042a462-c5ca-45ca-973c-6d59e2c69c1d"}',
        'email',
        timezone('utc'::text, now())
    ),
    (
        '53b1dc1b-6ad9-4fdd-a469-872cab371913',
        '53b1dc1b-6ad9-4fdd-a469-872cab371913',
        '53b1dc1b-6ad9-4fdd-a469-872cab371913',
        '{"sub": "53b1dc1b-6ad9-4fdd-a469-872cab371913"}',
        'email',
        timezone('utc'::text, now())
    ),
    (
        '94d127fb-860e-45a7-a30f-dbb982e10b3f',
        '94d127fb-860e-45a7-a30f-dbb982e10b3f',
        '94d127fb-860e-45a7-a30f-dbb982e10b3f',
        '{"sub": "94d127fb-860e-45a7-a30f-dbb982e10b3f"}',
        'email',
        timezone('utc'::text, now())
    ),
    (
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        '{"sub": "9bea1fed-87e9-4c1e-a60e-96fe17374ed8"}',
        'email',
        timezone('utc'::text, now())
    ),
    (
        'ec422962-e6c7-4d39-9809-f46010a826a3',
        'ec422962-e6c7-4d39-9809-f46010a826a3',
        'ec422962-e6c7-4d39-9809-f46010a826a3',
        '{"sub": "ec422962-e6c7-4d39-9809-f46010a826a3"}',
        'email',
        timezone('utc'::text, now())
    );
INSERT INTO "public"."profiles" (
        "id",
        "email",
        "first_name",
        "last_name",
        "role",
        "manager_id",
        "created_at",
        "updated_at"
    )
VALUES (
        '1405a312-949d-4cb1-a926-a4b6a8e1fdff',
        'reviewer1@emai.com',
        'Reviewer',
        'One',
        'reviewer',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        '2025-06-03 12:08:32.155442+00',
        '2025-06-03 12:08:32.155442+00'
    ),
    (
        '3042a462-c5ca-45ca-973c-6d59e2c69c1d',
        'admin1@email.com',
        'Admin',
        'One',
        'admin',
        null,
        '2025-06-03 11:58:57.756722+00',
        '2025-06-03 11:58:57.756722+00'
    ),
    (
        '53b1dc1b-6ad9-4fdd-a469-872cab371913',
        'manager1@email.com',
        'Manager',
        'One',
        'manager',
        null,
        '2025-06-03 12:12:48.501012+00',
        '2025-06-03 12:12:48.501012+00'
    ),
    (
        '94d127fb-860e-45a7-a30f-dbb982e10b3f',
        'reviewer2@email.com',
        'Reviewer',
        'Two',
        'reviewer',
        '53b1dc1b-6ad9-4fdd-a469-872cab371913',
        '2025-06-03 12:14:42.385828+00',
        '2025-06-03 12:14:42.385828+00'
    ),
    (
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        'manager2@email.com',
        'Manager',
        'Two',
        'manager',
        null,
        '2025-06-03 12:12:13.250549+00',
        '2025-06-03 12:12:13.250549+00'
    ),
    (
        'ec422962-e6c7-4d39-9809-f46010a826a3',
        'reviewer3@email.com',
        'Reviewer',
        'Three',
        'reviewer',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        '2025-06-03 12:14:19.355899+00',
        '2025-06-03 12:14:19.355899+00'
    );
INSERT INTO "public"."shipment_requests" (
        "id",
        "title",
        "description",
        "extracted_data",
        "status",
        "created_at",
        "updated_at",
        "user_id",
        "data_extracted",
        "transportMode",
        "entry_number",
        "entry_link",
        "hidden"
    )
VALUES (
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204',
        'Ocean Shipment',
        'Please find the attached shipment documents Firms Code: WAHL',
        '{"notes":"","units":"CTNS","products":[{"quantity":"932","net_weight":"464","description":"Table Toy","gross_weight":"464","tariff_codes":["99030124","8424899000"],"total_line_value":"932","country_of_origin_code":"CN"},{"quantity":"10188","net_weight":"35","description":"Headphones","gross_weight":"35","tariff_codes":["99030124","8504409580"],"total_line_value":"611","country_of_origin_code":"CN"},{"quantity":"4653","net_weight":"221","description":"RAISED CHEESE HEAD (FILISTER) SCREW","gross_weight":"221","tariff_codes":[],"total_line_value":"2327","country_of_origin_code":"CN"},{"quantity":"5889","net_weight":"221","description":"Party Supply","gross_weight":"221","tariff_codes":["99030124","9505906000"],"total_line_value":"1943","country_of_origin_code":"CN"},{"quantity":"543","net_weight":"221","description":"Bath brush","gross_weight":"221","tariff_codes":["99030124","9603298010"],"total_line_value":"326","country_of_origin_code":"CN"},{"quantity":"736","net_weight":"11","description":"StICKER","gross_weight":"11","tariff_codes":["99030124","4821104000"],"total_line_value":"22","country_of_origin_code":"CN"},{"quantity":"3466","net_weight":"33","description":"Hair brush","gross_weight":"33","tariff_codes":["99030124","9603293000"],"total_line_value":"5303","country_of_origin_code":"CN"},{"quantity":"9555","net_weight":"282","description":"PINS","gross_weight":"282","tariff_codes":["99030124","7319909000"],"total_line_value":"96","country_of_origin_code":"CN"},{"quantity":"93","net_weight":"282","description":"Plastic cup","gross_weight":"282","tariff_codes":["99030124","3924104000"],"total_line_value":"59","country_of_origin_code":"CN"},{"quantity":"551","net_weight":"23","description":"HEXAGON NUT M6 DIN 917 V2A","gross_weight":"23","tariff_codes":[],"total_line_value":"534","country_of_origin_code":"CN"},{"quantity":"3901","net_weight":"345","description":"Phone COVER","gross_weight":"345","tariff_codes":["99030124","4202929700"],"total_line_value":"3979","country_of_origin_code":"CN"},{"quantity":"1200","net_weight":"71","description":"Storage bag","gross_weight":"71","tariff_codes":["99030124","6305900000"],"total_line_value":"1740","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"52","description":"Sticker","gross_weight":"52","tariff_codes":["99030124","4802543100"],"total_line_value":"200","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"168","description":"Bottle opener","gross_weight":"168","tariff_codes":["99030124","7323930080"],"total_line_value":"1000","country_of_origin_code":"CN"},{"quantity":"1864","net_weight":"210","description":"Light bulb","gross_weight":"210","tariff_codes":["99030124","8539228060"],"total_line_value":"280","country_of_origin_code":"CN"},{"quantity":"30","net_weight":"12","description":"pendant lights","gross_weight":"12","tariff_codes":["99030124","9405198010"],"total_line_value":"360","country_of_origin_code":"CN"},{"quantity":"5000","net_weight":"180","description":"Cup mat","gross_weight":"180","tariff_codes":["99030124","3924901050"],"total_line_value":"3500","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"88","description":"nail file","gross_weight":"88","tariff_codes":["99030124","8214203000"],"total_line_value":"200","country_of_origin_code":"CN"}],"quantity":"776","containers":[{"container_size":"40 ft HC","container_number":"MSCU1234567"}],"vessel_name":"COSCO BELGIUM","shipper_name":"CHINA ABRASIVES EXPORT CORPORATION","voyage_number":"095E","consignee_name":"KABOFER TRADING INC","invoice_number":"INV100000LAX","port_of_loading":"SHANGHAI,CHINA","gross_weight_kgs":"16250","manufacturer_name":"CHINA ABRASIVES EXPORT CORPORATION","master_bol_number":"534343282","port_of_discharge":"LONG BEACH, CA","total_invoice_value":"23211","description_of_goods":"HOUSEHOLD AND PERSONAL ITEMS","manufacturer_address":"183 ZHONG YUAN WEST ROAD","country_of_export_code":"CN","estimated_arrival_date_mmddyy":"082919"}',
        'new',
        '2025-06-10 16:03:06.585517+00',
        '2025-06-26 13:56:50.263+00',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        'false',
        'ocean',
        'FV4-03226705-3',
        'https://sandbox.netchb.com/app/entry/viewEntry.do?filerCode=ST9&entryNo=2050399',
        'true'
    ),
    (
        '6a511fc0-4a85-4ffe-8df3-5a97aa5440f7',
        'Ocean Freight',
        '',
        '{"containers":[{"seal_number":"EMCWDGDSD","container_size":"40HQ","container_number":"MSCU1234567","container_weight":"16250","container_quantity":"776","container_measurement":"136","container_weight_unit":"KGS","container_quantity_unit":"CARTON(S)","container_measurement_unit":"CBM"}],"vessel_name":"COSCO BELGIUM","shipper_name":"CHINA ABRASIVES EXPORT CORPORATION","voyage_number":"095E","consignee_name":"KABOFER TRADING INC","port_of_loading":"SHANGHAI,CHINA","house_bol_number":"ZMLU34110002","master_bol_number":"COSU534343282","port_of_discharge":"LONG BEACH, CA","description_of_goods":"HOUSEHOLD AND PERSONAL ITEMS","date_of_export_mmddyy":"082219","estimated_arrival_date_mmddyy":"082919"}',
        'pending',
        '2025-07-03 12:30:25.076975+00',
        '2025-07-03 12:30:25.076975+00',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        'false',
        'ocean',
        'FV4-03226705-3',
        'https://sandbox.netchb.com/app/entry/viewEntry.do?filerCode=ST9&entryNo=2050399',
        'true'
    ),
    (
        '7119f100-23ba-453d-8bcc-bfe375f278ba',
        'Air freight',
        'please find the attached document',
        '{"notes":"","units":"PKGS","products":[{"quantity":"2","net_weight":"125","description":"Metal sign","gross_weight":"160","tariff_codes":["99038803","99030124","99030125","8310000000"],"total_line_value":"54","country_of_origin_code":"CN"},{"quantity":"1","net_weight":"105","description":"wall printer","gross_weight":"121","tariff_codes":["99038815","99030124","99030125","8443321090"],"total_line_value":"39","country_of_origin_code":"CN"},{"quantity":"2","net_weight":"50","description":"outdoor light box","gross_weight":"63","tariff_codes":["99038803","99030124","99030125","9405616000"],"total_line_value":"20","country_of_origin_code":"CN"},{"quantity":"60","net_weight":"90","description":"plastics strip","gross_weight":"105","tariff_codes":["99038802","99030124","99030125","3921901950"],"total_line_value":"31","country_of_origin_code":"CN"}],"quantity":"5","containers":[],"vessel_name":"","shipper_name":"ZHONGSHAN DINGZE TRADING COMPANY CO.,LTD","flight_number":"443","voyage_number":"","consignee_name":"JANTA TRADING LLC","invoice_number":"784-40716465","port_of_loading":"SHANGHAI","gross_weight_kgs":"426","house_awb_number":"","house_bol_number":"","manufacturer_name":"ZHONGSHAN DINGZE TRADING COMPANY CO.,LTD","master_awb_number":"78440716465","master_bol_number":"","port_of_discharge":"LOS ANGELES","flight_carrier_code":"CZ","total_invoice_value":"144","description_of_goods":"ACRYLIC LIGHT BOX / WALL PRINTER / OUTDOOR LIGHT BOX / WEARING STRIP","manufacturer_address":"1605 ROOM.JIAHUA CAIHONG BUILDING , NO 9 CAIHONG ROAD WEST DISTRICT ZHONGSHAN GUANGDONG ,CHINA","date_of_export_mmddyy":"061225","country_of_export_code":"CN","estimated_arrival_date_mmddyy":"061425"}',
        'completed',
        '2025-07-24 11:58:54.364059+00',
        '2025-07-24 17:16:36.818+00',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        'false',
        'air',
        'FV4-2050399-4',
        'https://sandbox.netchb.com/app/entry/viewEntry.do?filerCode=ST9&entryNo=2050399',
        'false'
    ),
    (
        '767826a5-1c9b-4645-bad8-68e477580168',
        'Ocean freight',
        'Help us create 7501 for the attached documents',
        '{"notes":"","units":"CTNS","products":[{"quantity":"932","net_weight":"464.3","description":"Table Toy","part_number":"TY-8424899-01","gross_weight":"464.3","tariff_codes":["99038802","99030124","99030125","8424899000"],"total_line_value":"932.00","country_of_origin_code":"CN"},{"quantity":"10188","net_weight":"34.5","description":"Headphones","part_number":"HP-8504409-A","gross_weight":"34.5","tariff_codes":["99038803","99030124","99030125","8504409580"],"total_line_value":"611.28","country_of_origin_code":"CN"},{"quantity":"4653","net_weight":"221","description":"RAISED CHEESE HEAD (FILISTER) SCREW","part_number":"","gross_weight":"221","tariff_codes":[],"total_line_value":"2327","country_of_origin_code":"CN"},{"quantity":"4653","net_weight":"221","description":"STORAGE BOX","part_number":"SBX-8518302-V2","gross_weight":"664.2","tariff_codes":["99030124","99030125","8518302000"],"total_line_value":"2326.50","country_of_origin_code":"CN"},{"quantity":"5889","net_weight":"221","description":"Party Supply","part_number":"PS-940590-SUP","gross_weight":"221","tariff_codes":["99030124","99030125","9505906000"],"total_line_value":"1943.37","country_of_origin_code":"CN"},{"quantity":"543","net_weight":"221","description":"Bath brush","part_number":"BB-960329-XL","gross_weight":"221","tariff_codes":["99030124","99030125","9603298010"],"total_line_value":"325.80","country_of_origin_code":"CN"},{"quantity":"736","net_weight":"11.4","description":"StICKER","part_number":"STK-4821104-05","gross_weight":"11.4","tariff_codes":["99038803","99030124","99030125","4821104000"],"total_line_value":"22.08","country_of_origin_code":"CN"},{"quantity":"3466","net_weight":"32.8","description":"Hair brush","part_number":"HB-960329-001","gross_weight":"32.8","tariff_codes":["99030124","99030125","9603293000"],"total_line_value":"5302.98","country_of_origin_code":"CN"},{"quantity":"9555","net_weight":"282","description":"PINS","part_number":"PIN-731990-STD","gross_weight":"282","tariff_codes":["99038815","99030124","99030133","99038190","7319909000"],"total_line_value":"95.55","country_of_origin_code":"CN"},{"quantity":"93","net_weight":"282","description":"Plastic cup","part_number":"CUP-392410-003","gross_weight":"282","tariff_codes":["99030124","99030125","3924104000"],"total_line_value":"58.59","country_of_origin_code":"CN"},{"quantity":"551","net_weight":"23","description":"HEXAGON NUT M6 DIN 917 V2A","gross_weight":"23","tariff_codes":[],"total_line_value":"534","country_of_origin_code":"CN"},{"quantity":"551","net_weight":"23.4","description":"Hand fan","part_number":"FAN-670290-MINI","gross_weight":"23.4","tariff_codes":["99030124","99030125","6702903500"],"total_line_value":"534.47","country_of_origin_code":"CN"},{"quantity":"3901","net_weight":"345.2","description":"Phone COVER","part_number":"PHCV-420292-PR","gross_weight":"345.2","tariff_codes":["99038803","99030124","99030125","4202929700"],"total_line_value":"3979.02","country_of_origin_code":"CN"},{"quantity":"1200","net_weight":"71.4","description":"Storage bag","part_number":"BAG-630590-L","gross_weight":"71.4","tariff_codes":["99038815","99030124","99030125","6305900000"],"total_line_value":"1740.00","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"52.4","description":"Sticker","part_number":"STK-4825431-01","gross_weight":"52.4","tariff_codes":["99038803","99030124","99030125","4802543100"],"total_line_value":"200.00","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"167.8","description":"Bottle opener","part_number":"BOP-732393-02","gross_weight":"167.8","tariff_codes":["99030124","99030133","99038190","7323930080"],"total_line_value":"1000.00","country_of_origin_code":"CN"},{"quantity":"1864","net_weight":"210.2","description":"Light bulb","part_number":"LB-853922-E27","gross_weight":"210.2","tariff_codes":["99030124","99030125","8539228060"],"total_line_value":"279.60","country_of_origin_code":"CN"},{"quantity":"30","net_weight":"12.3","description":"pendant lights","part_number":"PL-940519-SM","gross_weight":"12.3","tariff_codes":["99038803","99030124","99030125","9405198010"],"total_line_value":"360.00","country_of_origin_code":"CN"},{"quantity":"5000","net_weight":"180.3","description":"Cup mat","part_number":"CM-392490-RND","gross_weight":"180.3","tariff_codes":["99030124","99030125","3924901050"],"total_line_value":"3500.00","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"88.2","description":"nail file","part_number":"NF-821420-STD","gross_weight":"88.2","tariff_codes":["99030124","99030125","8214203000"],"total_line_value":"200.00","country_of_origin_code":"CN"}],"quantity":"776","containers":[{"container_size":"40HQ","container_number":"MSCU1234567"}],"vessel_name":"COSCO BELGIUM","shipper_name":"CHINA ABRASIVES EXPORT CORPORATION","flight_number":"","voyage_number":"095E","consignee_name":"KABOFER TRADING INC","invoice_number":"INV100000LAX","port_of_loading":"SHANGHAI,CHINA","gross_weight_kgs":"16250.000","house_awb_number":"","house_bol_number":"ZMLU34110002","manufacturer_name":"CHINA ABRASIVES EXPORT CORPORATION","master_awb_number":"","master_bol_number":"COSU534343282","port_of_discharge":"LONG BEACH, CA","flight_carrier_code":"","total_invoice_value":"23211.24","description_of_goods":"HOUSEHOLD AND PERSONAL ITEMS","manufacturer_address":"183 ZHONG YUAN WEST ROAD","date_of_export_mmddyy":"082219","country_of_export_code":"CN","estimated_arrival_date_mmddyy":"082919"}',
        'completed',
        '2025-07-08 12:42:56.53446+00',
        '2025-07-24 17:27:28.29+00',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        'false',
        'ocean',
        'FV4-03226705-3',
        'https://sandbox.netchb.com/app/entry/viewEntry.do?filerCode=ST9&entryNo=2050399',
        'false'
    ),
    (
        '8d2d817e-78fc-486f-b9b0-631f94281021',
        'Air Shipment',
        'firms codel: WAHL',
        '{"units":"PKGS","products":[{"quantity":"2","net_weight":"125","description":"Metal sign","gross_weight":"160","tariff_codes":["99038803","99030124","99030125","8310000000"],"total_line_value":"54","country_of_origin_code":"CN"},{"quantity":"1","net_weight":"105","description":"wall printer","gross_weight":"121","tariff_codes":["99038815","99030124","99030125","8443321090"],"total_line_value":"39","country_of_origin_code":"CN"},{"quantity":"2","net_weight":"50","description":"outdoor light box","gross_weight":"63","tariff_codes":["99038803","99030124","99030125","9405616000"],"total_line_value":"20","country_of_origin_code":"CN"},{"quantity":"60","net_weight":"90","description":"plastics strip","gross_weight":"105","tariff_codes":["99038802","99030124","99030125","3921901950"],"total_line_value":"31","country_of_origin_code":"CN"}],"quantity":"5","firms_code":"","shipper_name":"ZHONGSHAN DINGZE TRADING COMPANY CO.,LTD","flight_number":"443","consignee_name":"JANTA TRADING LLC","invoice_number":"784-40716465","gross_weight_kgs":"426","house_awb_number":"","manufacturer_name":"ZHONGSHAN DINGZE TRADING COMPANY CO.,LTD","master_awb_number":"78440716465","port_of_discharge":"LOS ANGELES","customer_reference":"784-40716465","ultimate_consignee":"JANTA TRADING LLC","flight_carrier_code":"CZ","total_invoice_value":"144","description_of_goods":"ACRYLIC LIGHT BOX / WALL PRINTER / OUTDOOR LIGHT BOX / WEARING STRIP","manufacturer_address":"1605 ROOM.JIAHUA CAIHONG BUILDING , NO 9 CAIHONG ROAD WEST DISTRICT ZHONGSHAN GUANGDONG ,CHINA","date_of_export_mmddyy":"061225","country_of_export_code":"CN","port_of_discharge_code":"2720","estimated_arrival_date_mmddyy":"061425","port_of_discharge_state_2_letter_code":"CA"}',
        'new',
        '2025-06-03 14:19:45.199932+00',
        '2025-06-03 17:32:34.291+00',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        'false',
        'air',
        'FV4-03226705-3',
        'https://sandbox.netchb.com/app/entry/viewEntry.do?filerCode=ST9&entryNo=2050399',
        'true'
    ),
    (
        'f4cdefbb-8c57-4e3e-96f1-55f55a4c5c41',
        'Truck Shipment',
        'desc',
        '{"notes":"","products":[{"quantity":"932","net_weight":"464","description":"Table Toy","gross_weight":"464","tariff_codes":["8424899000"],"total_line_value":"932","country_of_origin_code":"CN"},{"quantity":"10188","net_weight":"35","description":"Headphones","gross_weight":"35","tariff_codes":["8504409580"],"total_line_value":"611","country_of_origin_code":"CN"},{"quantity":"4653","net_weight":"221","description":"STORAGE BOX","gross_weight":"221","tariff_codes":["8518302000"],"total_line_value":"2327","country_of_origin_code":"CN"},{"quantity":"5889","net_weight":"221","description":"Party Supply","gross_weight":"221","tariff_codes":["9505906000"],"total_line_value":"1943","country_of_origin_code":"CN"},{"quantity":"543","net_weight":"221","description":"Bath brush","gross_weight":"221","tariff_codes":["9603298010"],"total_line_value":"326","country_of_origin_code":"CN"},{"quantity":"736","net_weight":"11","description":"StICKER","gross_weight":"11","tariff_codes":["4821104000"],"total_line_value":"22","country_of_origin_code":"CN"},{"quantity":"3466","net_weight":"33","description":"Hair brush","gross_weight":"33","tariff_codes":["9603293000"],"total_line_value":"5303","country_of_origin_code":"CN"},{"quantity":"9555","net_weight":"282","description":"PINS","gross_weight":"282","tariff_codes":["7319909000"],"total_line_value":"96","country_of_origin_code":"CN"},{"quantity":"93","net_weight":"282","description":"Plastic cup","gross_weight":"282","tariff_codes":["3924104000"],"total_line_value":"59","country_of_origin_code":"CN"},{"quantity":"551","net_weight":"23","description":"Hand fan","gross_weight":"23","tariff_codes":["6702903500"],"total_line_value":"534","country_of_origin_code":"CN"},{"quantity":"3901","net_weight":"345","description":"Phone COVER","gross_weight":"345","tariff_codes":["4202929700"],"total_line_value":"3979","country_of_origin_code":"CN"},{"quantity":"1200","net_weight":"71","description":"Storage bag","gross_weight":"71","tariff_codes":["6305900000"],"total_line_value":"1740","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"52","description":"Sticker","gross_weight":"52","tariff_codes":["4802543100"],"total_line_value":"200","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"168","description":"Bottle opener","gross_weight":"168","tariff_codes":["7323930080"],"total_line_value":"1000","country_of_origin_code":"CN"},{"quantity":"1864","net_weight":"210","description":"Light bulb","gross_weight":"210","tariff_codes":["8539228060"],"total_line_value":"280","country_of_origin_code":"CN"},{"quantity":"30","net_weight":"12","description":"pendant lights","gross_weight":"12","tariff_codes":["9405198010"],"total_line_value":"360","country_of_origin_code":"CN"},{"quantity":"5000","net_weight":"180","description":"Cup mat","gross_weight":"180","tariff_codes":["3924901050"],"total_line_value":"3500","country_of_origin_code":"CN"},{"quantity":"2000","net_weight":"88","description":"nail file","gross_weight":"88","tariff_codes":["8214203000"],"total_line_value":"200","country_of_origin_code":"CN"}],"containers":[{"container_size":"40 ft HC","container_number":"MSCU1234567"}],"vessel_name":"COSCO BELGIUM","shipper_name":"CHINA ABRASIVES EXPORT CORPORATION","voyage_number":"095E","consignee_name":"KABOFER TRADING INC","invoice_number":"INV100000LAX","port_of_loading":"SHANGHAI,CHINA","gross_weight_kgs":"16250","manufacturer_name":"CHINA ABRASIVES EXPORT CORPORATION","master_bol_number":"534343282","port_of_discharge":"LONG BEACH, CA","total_invoice_value":"23211","description_of_goods":"HOUSEHOLD AND PERSONAL ITEMS","manufacturer_address":"183 ZHONG YUAN WEST ROAD","country_of_export_code":"CN","estimated_arrival_date_mmddyy":"082919"}',
        'new',
        '2025-06-03 14:31:03.98888+00',
        '2025-06-15 20:39:52.266+00',
        '9bea1fed-87e9-4c1e-a60e-96fe17374ed8',
        'false',
        'land',
        'FV4-03226705-3',
        'https://sandbox.netchb.com/app/entry/viewEntry.do?filerCode=ST9&entryNo=2050399',
        'false'
    );
INSERT INTO "public"."shipment_request_files" (
        "id",
        "shipment_request_id",
        "file_name",
        "file_path",
        "file_type",
        "file_size",
        "created_at"
    )
VALUES (
        '172d51c7-d993-4129-8dde-899a80ad47d9',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204',
        'BL-COSU534343282.pdf',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204/1749571386690.pdf',
        'application/pdf',
        '167744',
        '2025-06-10 16:03:09.086957+00'
    ),
    (
        '3440b2bc-dd8e-484a-8003-622928382ffa',
        'f4cdefbb-8c57-4e3e-96f1-55f55a4c5c41',
        'Arrival_Notice_-_SS25048594.pdf',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204/1749571386690.pdf',
        'application/pdf',
        '489845',
        '2025-06-03 14:31:16.823132+00'
    ),
    (
        '3d5cc182-707e-4a52-98ac-bc907dc03e22',
        '8d2d817e-78fc-486f-b9b0-631f94281021',
        'MATS4272731000.pdf',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204/1749571386690.pdf',
        'application/pdf',
        '82954',
        '2025-06-03 14:19:48.20307+00'
    ),
    (
        '55a2748d-88e1-4838-a040-a459dcbec39a',
        '8d2d817e-78fc-486f-b9b0-631f94281021',
        '12月43柜_清关文件-RICH.xlsx',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204/1749571389198.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        '17874',
        '2025-06-03 14:19:46.813158+00'
    ),
    (
        '781f4d4e-8d18-4714-8519-e7273305361e',
        '767826a5-1c9b-4645-bad8-68e477580168',
        'BL-COSU534343282.pdf',
        '767826a5-1c9b-4645-bad8-68e477580168/1751978576636.pdf',
        'application/pdf',
        '167744',
        '2025-07-08 12:42:58.98427+00'
    ),
    (
        'a3eef67e-8f29-4b66-8e7c-139aed292b2e',
        '7119f100-23ba-453d-8bcc-bfe375f278ba',
        'PACKING LIST.pdf',
        '7119f100-23ba-453d-8bcc-bfe375f278ba/1753358338150.pdf',
        'application/pdf',
        '29290',
        '2025-07-24 11:58:58.76001+00'
    ),
    (
        'ac72b68e-5d3b-4e9b-a64c-fa43e4c49157',
        '767826a5-1c9b-4645-bad8-68e477580168',
        'Demo-Invoice-PackingList_1.xlsx',
        '767826a5-1c9b-4645-bad8-68e477580168/1751978579082.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        '13507',
        '2025-07-08 12:43:00.157431+00'
    ),
    (
        'acc6aaac-c574-4f28-bde2-e8e3eece9437',
        '6a511fc0-4a85-4ffe-8df3-5a97aa5440f7',
        'BL-COSU534343282.pdf',
        '6a511fc0-4a85-4ffe-8df3-5a97aa5440f7/1751545825252.pdf',
        'application/pdf',
        '167744',
        '2025-07-03 12:30:27.183547+00'
    ),
    (
        'b13db3f0-7ec3-4520-8b53-2e2ada95fb65',
        'f4cdefbb-8c57-4e3e-96f1-55f55a4c5c41',
        'COPY件-CMDUNGP2292140.pdf',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204/1749571386690.pdf',
        'application/pdf',
        '327266',
        '2025-06-03 14:31:22.273828+00'
    ),
    (
        'b9a5b104-8485-4a22-8021-4962aa6072eb',
        'f4cdefbb-8c57-4e3e-96f1-55f55a4c5c41',
        '税金草单-CMDUNGP2292140_带备注.xlsx',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204/1749571389198.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        '18113',
        '2025-06-03 14:31:23.220268+00'
    ),
    (
        'eb135c1b-b962-4afa-8973-d8c4886522c2',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204',
        'Demo-Invoice-PackingList_1.xlsx',
        '5f6fbd5a-b7af-4caf-9e1f-f22b342d4204/1749571389198.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        '13083',
        '2025-06-10 16:03:10.814243+00'
    ),
    (
        'ef84052a-3fd0-405b-8bb1-29caead1d11b',
        '7119f100-23ba-453d-8bcc-bfe375f278ba',
        '784-40716465.pdf',
        '7119f100-23ba-453d-8bcc-bfe375f278ba/1753358334576.pdf',
        'application/pdf',
        '594521',
        '2025-07-24 11:58:57.039513+00'
    ),
    (
        'f607ce8f-7a1f-4f85-9fed-264d0633524d',
        '7119f100-23ba-453d-8bcc-bfe375f278ba',
        'Invoice.pdf',
        '7119f100-23ba-453d-8bcc-bfe375f278ba/1753358337167.pdf',
        'application/pdf',
        '79030',
        '2025-07-24 11:58:58.031661+00'
    );