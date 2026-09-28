-- ============================================================================
-- TEKMRKTG (ISABELLA AI) ENGINE & PROSPECT PIPELINE
-- Engine: PostgreSQL (Supabase)
-- Author: TekMRKTG Engineering
-- Description: Client intake, phone call routing, HITL escalation triggers, 
--              and high-intent prospect tracking for Arizona fine dining.
-- ============================================================================

-- 1. CREATE CORE TABLES
CREATE TABLE IF NOT EXISTS restaurant_clients (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    restaurant_name VARCHAR(100) NOT NULL,
    plan_tier VARCHAR(30) DEFAULT 'Pro Plan',     -- 'Pro Plan' ($297-$397/mo) or 'Partner Plan'
    phone_number VARCHAR(20) NOT NULL,
    max_party_auto_book INT DEFAULT 6,             -- Parties > 6 trigger HITL escalation
    status VARCHAR(20) DEFAULT 'Prospect',          -- 'Prospect', 'Active', 'Onboarding'
    prospect_zone VARCHAR(10) CHECK (prospect_zone IN ('Green', 'Yellow', 'Red')),
    location_city VARCHAR(50) DEFAULT 'Phoenix',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS call_logs (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    client_id BIGINT REFERENCES restaurant_clients(id) ON DELETE CASCADE,
    caller_phone VARCHAR(20) NOT NULL,
    call_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    intent VARCHAR(50) NOT NULL,                  -- 'Reservation', 'Modification', 'Catering'
    party_size INT DEFAULT 2,
    requested_date TIMESTAMP WITH TIME ZONE,
    has_allergies BOOLEAN DEFAULT FALSE,
    special_notes TEXT,
    ai_resolution_status VARCHAR(30) DEFAULT 'PENDING' -- 'AUTO_BOOKED', 'ANSWERED_INQUIRY', 'ESCALATED_HITL'
);

CREATE TABLE IF NOT EXISTS hitl_escalations (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    call_id BIGINT REFERENCES call_logs(id) ON DELETE CASCADE,
    escalation_reason VARCHAR(100) NOT NULL,       -- 'Party Size Exceeds Limit', 'Severe Allergy'
    assigned_staff_user VARCHAR(50),
    status VARCHAR(20) DEFAULT 'PENDING',           -- 'PENDING', 'APPROVED', 'REJECTED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. AUTOMATED PL/pgSQL HITL ESCALATION TRIGGER (AFTER INSERT)
CREATE OR REPLACE FUNCTION process_isabella_routing()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.party_size > 6 OR NEW.has_allergies = TRUE OR NEW.intent = 'Catering' THEN
        -- Update the call log resolution status
        UPDATE call_logs 
        SET ai_resolution_status = 'ESCALATED_HITL' 
        WHERE id = NEW.id;
        
        -- Insert record into human escalation queue
        INSERT INTO hitl_escalations (call_id, escalation_reason, status)
        VALUES (
            NEW.id, 
            CASE 
                WHEN NEW.party_size > 6 THEN 'Party size exceeds auto-booking threshold'
                WHEN NEW.has_allergies = TRUE THEN 'Dietary/Allergy accommodation required'
                ELSE 'Catering / Private Dining Request'
            END,
            'PENDING'
        );
    ELSE
        UPDATE call_logs 
        SET ai_resolution_status = 'AUTO_BOOKED' 
        WHERE id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_isabella_call_routing
AFTER INSERT ON call_logs
FOR EACH ROW
EXECUTE FUNCTION process_isabella_routing();

-- 3. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE restaurant_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE hitl_escalations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read client info" ON restaurant_clients FOR SELECT USING (true);
CREATE POLICY "Public read call logs" ON call_logs FOR SELECT USING (true);
CREATE POLICY "Public read escalations" ON hitl_escalations FOR SELECT USING (true);

-- 4. SEED DATA: ARIZONA HIGH-INTENT PROSPECTS (SANITIZED MOCK NUMBERS)
INSERT INTO restaurant_clients (restaurant_name, plan_tier, phone_number, max_party_auto_book, status, prospect_zone, location_city) 
VALUES 
    ('The Stockyards Restaurant', 'Pro Plan', '+1-602-555-0101', 6, 'Prospect', 'Green', 'Phoenix'),
    ('Cowboy Club Grille & Spirits', 'Pro Plan', '+1-928-555-0102', 8, 'Prospect', 'Green', 'Sedona'),
    ('Different Pointe of View', 'Partner Plan', '+1-602-555-0103', 6, 'Prospect', 'Green', 'Phoenix'),
    ('Lon''s at The Hermosa Inn', 'Partner Plan', '+1-602-555-0104', 6, 'Prospect', 'Green', 'Paradise Valley'),
    ('Mariposa Sedona', 'Pro Plan', '+1-928-555-0105', 6, 'Prospect', 'Green', 'Sedona'),
    ('Village Chop House', 'Pro Plan', '+1-928-555-0106', 6, 'Prospect', 'Green', 'Sedona');

-- 5. TEST CALL LOGS (AUTOMATICALLY TRIGGERS HITL ESCALATIONS)
INSERT INTO call_logs (client_id, caller_phone, intent, party_size, has_allergies, special_notes)
VALUES 
    (1, '+1-480-555-0199', 'Reservation', 4, FALSE, 'Standard booth requested'),
    (1, '+1-480-555-0188', 'Reservation', 12, FALSE, 'Large corporate gathering'),
    (2, '+1-928-555-0177', 'Reservation', 2, TRUE, 'Celiac / severe gluten allergy');
-- Table 3: HITL Escalation Queue (For Human Staff Action)
CREATE TABLE IF NOT EXISTS hitl_escalations (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    call_id BIGINT REFERENCES call_logs(id) ON DELETE CASCADE,
    escalation_reason VARCHAR(100) NOT NULL,   -- 'Party Size Exceeds Limit', 'Severe Allergy', 'Catering Request'
    assigned_staff_user VARCHAR(50),
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    status VARCHAR(20) DEFAULT 'PENDING'       -- 'PENDING', 'APPROVED', 'REJECTED'
);

-- ----------------------------------------------------------------------------
-- 2. SAMPLE DATA INSERTION (Based on Knowledge Base & Demo Data)
-- ----------------------------------------------------------------------------

INSERT INTO restaurant_clients (restaurant_name, plan_tier, tier_category, phone_number, max_party_auto_book)
VALUES 
    ('Mastro''s Steakhouse', 'Partner Plan', 'Tier 1', '+16025550199', 6),
    ('The Capital Grille', 'Pro Plan', 'Tier 1', '+16025550244', 6),
    ('Sunshine Breakfast Cafe', 'Pro Plan', 'Tier 3', '+19125550112', 8);

-- Insert Calls
INSERT INTO call_logs (client_id, caller_phone, intent, party_size, requested_date, has_allergies, special_notes, ai_resolution_status)
VALUES 
    (1, '+14805551234', 'Reservation', 4, '2026-10-15 19:00:00', FALSE, 'Anniversary dinner', 'AUTO_BOOKED'),
    (1, '+14805555678', 'Reservation', 12, '2026-10-18 18:30:00', FALSE, 'Large corporate party', 'ESCALATED_HITL'), -- HITL Trigger
    (1, '+14805559012', 'Special Request', 2, '2026-10-20 20:00:00', TRUE, 'Severe peanut allergy', 'ESCALATED_HITL');  -- HITL Trigger

-- Insert HITL Queue Records
INSERT INTO hitl_escalations (call_id, escalation_reason)
VALUES 
    (2, 'Party size (12) exceeds auto-booking threshold (6)'),
    (3, 'Severe dietary/allergy protocol required');

-- ----------------------------------------------------------------------------
-- 3. ROUTING ENGINE QUERY (Call Classification & Escalation Audit)
-- ----------------------------------------------------------------------------

SELECT 
    c.id AS call_id,
    r.restaurant_name,
    c.caller_phone,
    c.intent,
    c.party_size,
    c.has_allergies,
    CASE 
        -- HITL Guardrail 1: Large Party Sizes
        WHEN c.party_size > r.max_party_auto_book 
            THEN 'ESCALATE: Exceeds Auto-Book Limit (Requires Manager Approval)'
        
        -- HITL Guardrail 2: Severe Dietary/Allergy Requests
        WHEN c.has_allergies = TRUE 
            THEN 'ESCALATE: Severe Dietary Accommodation Protocol Triggered'
        
        -- HITL Guardrail 3: Catering or Complex Inquiries
        WHEN c.intent = 'Catering' 
            THEN 'ESCALATE: Route to Private Event Coordinator'
        
        ELSE 'AUTO_CONFIRM: Booked by Isabella AI'
    END AS routing_action
FROM call_logs c
JOIN restaurant_clients r ON c.client_id = r.id
ORDER BY c.id ASC;
