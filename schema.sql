-- ============================================================================
-- TEKMRKTG (ISABELLA AI) DATABASE SCHEMA & CALL ROUTING ENGINE
-- Engine: PostgreSQL (Supabase)
-- Author: TekMRKTG Engineering
-- Description: Core schema for client onboarding, incoming call logs, AI reservation 
--              intake, and Human-in-the-Loop (HITL) escalation routing.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SCHEMA INITIALIZATION & TABLES
-- ----------------------------------------------------------------------------

-- Table 1: Restaurant Clients
CREATE TABLE IF NOT EXISTS restaurant_clients (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    restaurant_name VARCHAR(100) NOT NULL,
    plan_tier VARCHAR(20) DEFAULT 'Pro Plan', -- 'Pro Plan' ($397/mo) or 'Partner Plan' ($4,367/yr)
    tier_category VARCHAR(20) DEFAULT 'Tier 1', -- Tier 1 (Fine Dining/Steakhouse), Tier 2, Tier 3
    phone_number VARCHAR(20) NOT NULL,
    max_party_auto_book INT DEFAULT 6,         -- Parties > 6 trigger HITL escalation
    status VARCHAR(20) DEFAULT 'Active'
);

-- Table 2: Call Inquiries & AI Voice Logs
CREATE TABLE IF NOT EXISTS call_logs (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    client_id BIGINT REFERENCES restaurant_clients(id) ON DELETE CASCADE,
    caller_phone VARCHAR(20) NOT NULL,
    call_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    intent VARCHAR(50) NOT NULL,              -- 'Reservation', 'Menu Inquiry', 'Special Request', 'Catering'
    party_size INT,
    requested_date TIMESTAMP,
    has_allergies BOOLEAN DEFAULT FALSE,
    special_notes TEXT,
    ai_resolution_status VARCHAR(30) NOT NULL -- 'AUTO_BOOKED', 'ANSWERED_INQUIRY', 'ESCALATED_HITL'
);

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
