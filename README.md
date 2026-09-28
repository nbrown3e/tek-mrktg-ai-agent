# TekMRKTG (Isabella AI) — Voice Operations & HITL Routing Engine

## Overview
Engineered a PostgreSQL database architecture, custom procedural trigger functions, and Row Level Security (RLS) policies in Supabase for **Isabella AI**, an automated voice routing and reservation management engine designed for high-volume, phone-only restaurant operations[cite: 1, 2, 4, 5].

## Key Features & System Logic
* **Automated Call Classification**: Categorizes incoming customer inquiries into reservations, modifications, and private dining requests[cite: 4, 5].
* **Human-in-the-Loop (HITL) Guardrails**: Implemented PL/pgSQL trigger logic (`process_isabella_routing()`) that automatically intercepts high-risk edge cases (party sizes > 6, severe dietary allergies, catering requests) and routes them to a human escalation queue[cite: 1, 2, 4, 5].
* **Prospect Classification Engine**: Tracks high-ticket hospitality leads (Green, Yellow, Red zones) alongside custom client onboarding metrics[cite: 3].
* **Row Level Security (RLS)**: Enforces access control policies securing client contact info and call log privacy.

## Data Privacy & Compliance
* **Data Sanitization**: Business entities reflect real-world operational targets; all phone numbers, contact details, and personal identifiers have been sanitized with synthetic mock data (`+1-555-555-01XX`) to ensure strict PII protection.

## Repository Structure
* `schema.sql` — PostgreSQL DDL scripts, procedural triggers, RLS policies, and prospecting sample data[cite: 3, 5].
