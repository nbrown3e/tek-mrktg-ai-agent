# TekMRKTG — Isabella AI Guest Service & Voice Routing Engine

## Overview
Engineered the database architecture, call-routing engine, and Human-in-the-Loop (HITL) escalation logic for **Isabella AI**, an automated guest service assistant designed to capture missed restaurant revenue from phone inquiries.

## Key Features & Architecture
* **Relational Schema (`restaurant_clients`, `call_logs`, `hitl_escalations`)**: Normalizes client configurations, tier limits, call metadata, and manual staff escalation queues.
* **Human-in-the-Loop (HITL) Guardrails**: Automatically detects operational edge cases (party sizes > 6, severe dietary allergies, catering requests) and flags them for manager review[cite: 1, 2].
* **Performance & ROI Analytics**: Evaluates 24/7 call capture logs to measure guest conversion, speed-to-value SLAs (72-hour deployment guarantee)[cite: 1, 5], and 2x ROI metrics[cite: 1, 5].

## Core Query Logic
Pipes incoming voice call payloads through PostgreSQL `CASE` conditional logic to trigger real-time `AUTO_CONFIRM` vs `ESCALATE` routing decisions.
