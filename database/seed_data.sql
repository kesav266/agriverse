-- ====================================================================
-- AgriVerse AI - Demonstration Seed Data Script
-- Target Engine: PostgreSQL 15+ / Supabase
-- Description: Realistic agricultural records for development and demonstration.
-- NOTE: All records are strictly synthetic test fixtures. Contains NO production secrets.
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. Demo Farmer Profiles
-- --------------------------------------------------------------------
INSERT INTO public.profiles (
    id, full_name, phone_number, hashed_password, village, district, state, preferred_language, simple_mode_enabled
)
VALUES 
    (
        '11111111-1111-1111-1111-111111111111',
        'Ramesh Kumar (రమేష్ కుమార్)',
        '+919876543210',
        '$2b$12$e8F0lD6L9aQz.3b3O1vPceP12X5zRzXp0mR9A0M1u1y2w3v4u5t6s', -- bcrypt hash for 'secret123'
        'Tenali',
        'Guntur',
        'Andhra Pradesh',
        'te',
        true
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'Srinivas Rao (శ్రీనివాస రావు)',
        '+919876543211',
        '$2b$12$e8F0lD6L9aQz.3b3O1vPceP12X5zRzXp0mR9A0M1u1y2w3v4u5t6s',
        'Jangaon',
        'Warangal',
        'Telangana',
        'en',
        false
    )
ON CONFLICT (phone_number) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    village = EXCLUDED.village,
    preferred_language = EXCLUDED.preferred_language;

-- --------------------------------------------------------------------
-- 2. Demo Farms
-- --------------------------------------------------------------------
INSERT INTO public.farms (
    id, farmer_id, farm_name, land_area_acres, soil_type, irrigation_source, latitude, longitude, survey_number
)
VALUES 
    (
        '33333333-3333-3333-3333-333333333333',
        '11111111-1111-1111-1111-111111111111',
        'Green Valley Paddy Field',
        4.5,
        'Black Cotton',
        'Borewell',
        16.243000,
        80.640000,
        'Sy. No. 142/A'
    ),
    (
        '44444444-4444-4444-4444-444444444444',
        '11111111-1111-1111-1111-111111111111',
        'Sunrise Chilli Orchard',
        2.0,
        'Red Sandy',
        'Drip',
        16.250000,
        80.650000,
        'Sy. No. 89/2'
    )
ON CONFLICT (id) DO UPDATE SET
    farm_name = EXCLUDED.farm_name,
    land_area_acres = EXCLUDED.land_area_acres;

-- --------------------------------------------------------------------
-- 3. Demo Crop Cycles
-- --------------------------------------------------------------------
INSERT INTO public.crop_cycles (
    id, farm_id, crop_name, variety, sowing_date, expected_harvest_date, stage, status
)
VALUES 
    (
        '55555555-5555-5555-5555-555555555555',
        '33333333-3333-3333-3333-333333333333',
        'Paddy (Rice)',
        'BPT 5204 (Samba Mahsuri)',
        '2026-07-15',
        '2026-11-20',
        'Flowering',
        'Active'
    ),
    (
        '66666666-6666-6666-6666-666666666666',
        '44444444-4444-4444-4444-444444444444',
        'Red Chilli',
        'Teja 334',
        '2026-08-01',
        '2026-12-15',
        'Vegetative',
        'Active'
    )
ON CONFLICT (id) DO UPDATE SET
    stage = EXCLUDED.stage,
    status = EXCLUDED.status;

-- --------------------------------------------------------------------
-- 4. Demo Field Observations
-- --------------------------------------------------------------------
INSERT INTO public.farm_observations (
    id, crop_cycle_id, observation_date, soil_moisture_percentage, pest_symptoms, notes
)
VALUES 
    (
        'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1',
        '55555555-5555-5555-5555-555555555555',
        CURRENT_DATE - INTERVAL '3 days',
        52.5,
        'No active pest symptoms observed',
        'Panicle initiation observed uniformly across plot'
    ),
    (
        'a2a2a2a2-a2a2-a2a2-a2a2-a2a2a2a2a2a2',
        '66666666-6666-6666-6666-666666666666',
        CURRENT_DATE - INTERVAL '1 day',
        38.0,
        'Mild leaf curling along border rows',
        'Soil drying rapidly; schedule irrigation in next 24 hours'
    )
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------
-- 5. Demo Crop Recommendations
-- --------------------------------------------------------------------
INSERT INTO public.crop_recommendations (
    id, farm_id, crop_name, category, recommendation_title, details_en, details_te, confidence_score, is_actioned
)
VALUES 
    (
        '77777777-7777-7777-7777-777777777777',
        '33333333-3333-3333-3333-333333333333',
        'Paddy (Rice)',
        'Fertilizer',
        'Apply Potassium Chloride (MOP)',
        'Apply 25 kg/acre of MOP during flowering stage to enhance grain filling and increase drought tolerance.',
        'వరి ధాన్యం బాగా నిండటానికి పూత దశలో ఎకరానికి 25 కిలోల పొటాషియం క్లోరైడ్ (MOP) చల్లండి.',
        0.96,
        false
    ),
    (
        '88888888-8888-8888-8888-888888888888',
        '44444444-4444-4444-4444-444444444444',
        'Red Chilli',
        'Pest Management',
        'Thrips Control Advisory',
        'Spray Neem Oil (10,000 ppm) at 2 ml/liter of water in early morning to prevent thrips infestation on young chilli shoots.',
        'మిరప ఆకు ముడత మరియు తామర పురుగుల నివారణకు ఉదయాన్నే లీటరు నీటికి 2 మి.లీ వేప నూనెను పిచికారీ చేయండి.',
        0.94,
        false
    )
ON CONFLICT (id) DO UPDATE SET
    recommendation_title = EXCLUDED.recommendation_title,
    confidence_score = EXCLUDED.confidence_score;

-- --------------------------------------------------------------------
-- 6. Demo Weather Observations
-- --------------------------------------------------------------------
INSERT INTO public.weather_observations (
    id, district, temperature_celsius, humidity_percentage, rainfall_mm, wind_speed_kmh, forecast_condition
)
VALUES 
    (
        '99999999-9999-9999-9999-999999999999',
        'Guntur',
        31.5,
        78.0,
        12.5,
        14.2,
        'Light Rain & Humid'
    ),
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'Warangal',
        33.0,
        65.0,
        0.0,
        10.5,
        'Partly Cloudy'
    )
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------
-- 7. Demo Crop Health Diagnoses
-- --------------------------------------------------------------------
INSERT INTO public.crop_health_diagnoses (
    id, farmer_id, crop_name, image_url, detected_disease, severity, recommended_treatment_en, recommended_treatment_te
)
VALUES 
    (
        'd1d1d1d1-d1d1-d1d1-d1d1-d1d1d1d1d1d1',
        '11111111-1111-1111-1111-111111111111',
        'Paddy (Rice)',
        'https://storage.googleapis.com/agriverse-demo-bucket/diagnoses/paddy_blast_sample_1.jpg',
        'Paddy Leaf Blast (Magnaporthe oryzae)',
        'Moderate',
        'Apply Tricyclazole 75% WP at 0.6 g/liter of water. Maintain proper drainage in field.',
        'లీటరు నీటికి 0.6 గ్రాముల ట్రైసైక్లాజోల్ 75% WP పిచికారీ చేయండి. పొలంలో నీటి పారుదల సరిగ్గా ఉంచండి.'
    )
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------
-- 8. Demo Yield Estimates
-- --------------------------------------------------------------------
INSERT INTO public.yield_estimates (
    id, crop_cycle_id, farm_id, estimated_yield_quintals, cost_of_cultivation_inr, expected_market_price_per_quintal, projected_revenue_inr, projected_net_profit_inr
)
VALUES 
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        '55555555-5555-5555-5555-555555555555',
        '33333333-3333-3333-3333-333333333333',
        112.5,
        95000.00,
        2300.00,
        258750.00,
        163750.00
    )
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------
-- 9. Demo Assistant Conversations & Messages
-- --------------------------------------------------------------------
INSERT INTO public.assistant_conversations (
    id, farmer_id, title
)
VALUES 
    (
        'c1c1c1c1-c1c1-c1c1-c1c1-c1c1c1c1c1c1',
        '11111111-1111-1111-1111-111111111111',
        'Paddy Flowering Fertilizer Inquiry'
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.assistant_messages (
    id, conversation_id, sender, content, language
)
VALUES 
    (
        'e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1',
        'c1c1c1c1-c1c1-c1c1-c1c1-c1c1c1c1c1c1',
        'user',
        'వరి పూత దశలో ఏ ఎరువులు వాడాలి?',
        'te'
    ),
    (
        'e2e2e2e2-e2e2-e2e2-e2e2-e2e2e2e2e2e2',
        'c1c1c1c1-c1c1-c1c1-c1c1-c1c1c1c1c1c1',
        'assistant',
        'వరి పూత దశలో ధాన్యం నాణ్యత మెరుగుపరచడానికి మరియు గింజ బరువు పెరగడానికి ఎకరానికి 25 కిలోల పొటాషియం క్లోరైడ్ (MOP) చల్లండి. పొలంలో 2-3 సెం.మీ తేమ ఉండేలా చూడండి.',
        'te'
    )
ON CONFLICT (id) DO NOTHING;
