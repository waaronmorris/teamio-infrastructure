-- TeamIO Seed Data Script
-- Run this after migrations to populate sample data for development/testing
-- Usage: make db-seed (from dev/ directory)

-- ============================================================================
-- USERS (password is 'password123' hashed with argon2)
-- ============================================================================
INSERT INTO users (id, email, password_hash, first_name, last_name, phone, role, is_active, created_at, updated_at) VALUES
-- Admin user
('a0000001-0000-0000-0000-000000000001', 'admin@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Admin', 'User', '555-0100', 'admin', true, NOW(), NOW()),
-- Commissioner
('a0000002-0000-0000-0000-000000000001', 'commissioner@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'League', 'Commissioner', '555-0101', 'commissioner', true, NOW(), NOW()),
-- Coaches
('a0000010-0000-0000-0000-000000000001', 'coach.smith@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'John', 'Smith', '555-0110', 'coach', true, NOW(), NOW()),
('a0000011-0000-0000-0000-000000000001', 'coach.johnson@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Sarah', 'Johnson', '555-0111', 'coach', true, NOW(), NOW()),
('a0000012-0000-0000-0000-000000000001', 'coach.williams@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Mike', 'Williams', '555-0112', 'coach', true, NOW(), NOW()),
('a0000013-0000-0000-0000-000000000001', 'coach.brown@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Emily', 'Brown', '555-0113', 'coach', true, NOW(), NOW()),
-- Parents/Guardians
('a0000020-0000-0000-0000-000000000001', 'parent.jones@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Robert', 'Jones', '555-0120', 'guardian', true, NOW(), NOW()),
('a0000021-0000-0000-0000-000000000001', 'parent.davis@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Jennifer', 'Davis', '555-0121', 'guardian', true, NOW(), NOW()),
('a0000022-0000-0000-0000-000000000001', 'parent.miller@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'David', 'Miller', '555-0122', 'guardian', true, NOW(), NOW()),
('a0000023-0000-0000-0000-000000000001', 'parent.wilson@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Lisa', 'Wilson', '555-0123', 'guardian', true, NOW(), NOW()),
-- Players (these are users who play)
('a0000030-0000-0000-0000-000000000001', 'player1@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Jake', 'Jones', NULL, 'player', true, NOW(), NOW()),
('a0000031-0000-0000-0000-000000000001', 'player2@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Emma', 'Davis', NULL, 'player', true, NOW(), NOW()),
('a0000032-0000-0000-0000-000000000001', 'player3@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Liam', 'Miller', NULL, 'player', true, NOW(), NOW()),
('a0000033-0000-0000-0000-000000000001', 'player4@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Sophia', 'Wilson', NULL, 'player', true, NOW(), NOW()),
('a0000034-0000-0000-0000-000000000001', 'player5@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Noah', 'Taylor', NULL, 'player', true, NOW(), NOW()),
('a0000035-0000-0000-0000-000000000001', 'player6@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Olivia', 'Anderson', NULL, 'player', true, NOW(), NOW()),
('a0000036-0000-0000-0000-000000000001', 'player7@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Mason', 'Thomas', NULL, 'player', true, NOW(), NOW()),
('a0000037-0000-0000-0000-000000000001', 'player8@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Ava', 'Jackson', NULL, 'player', true, NOW(), NOW()),
('a0000038-0000-0000-0000-000000000001', 'player9@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Ethan', 'White', NULL, 'player', true, NOW(), NOW()),
('a0000039-0000-0000-0000-000000000001', 'player10@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Isabella', 'Harris', NULL, 'player', true, NOW(), NOW()),
('a0000040-0000-0000-0000-000000000001', 'player11@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Aiden', 'Martin', NULL, 'player', true, NOW(), NOW()),
('a0000041-0000-0000-0000-000000000001', 'player12@teamio.local', '$argon2id$v=19$m=19456,t=2,p=1$PuvgXS+7WnX9hTsGPhjfhQ$/pxhEjh9AAacX1zCyBq4C6aVN18dajrmCN2U+3K5+gM', 'Mia', 'Garcia', NULL, 'player', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- ORGANIZATION
-- ============================================================================
INSERT INTO organizations (id, name, org_type, description, address, city, state, zip_code, phone, email, website, is_active, created_at, updated_at) VALUES
('b0000001-0000-0000-0000-000000000001', 'Riverside Parks & Recreation', 'recreation', 'Community sports programs for all ages', '123 Main Street', 'Riverside', 'CA', '92501', '555-1000', 'info@riversideparks.local', 'https://riversideparks.local', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- FIELDS
-- ============================================================================
INSERT INTO fields (id, organization_id, name, description, address, city, state, zip_code, field_type, field_size, surface_type, has_lights, is_active, created_at, updated_at) VALUES
('c0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Central Park Field 1', 'Main soccer field', '500 Park Avenue', 'Riverside', 'CA', '92501', 'soccer', 'full', 'grass', true, true, NOW(), NOW()),
('c0000002-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Central Park Field 2', 'Secondary soccer field', '500 Park Avenue', 'Riverside', 'CA', '92501', 'soccer', 'full', 'grass', true, true, NOW(), NOW()),
('c0000003-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Riverside Sports Complex A', 'Multi-purpose turf field', '800 Sports Drive', 'Riverside', 'CA', '92502', 'multi-purpose', 'full', 'turf', true, true, NOW(), NOW()),
('c0000004-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Riverside Sports Complex B', 'Multi-purpose turf field', '800 Sports Drive', 'Riverside', 'CA', '92502', 'multi-purpose', 'full', 'turf', true, true, NOW(), NOW()),
('c0000005-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Community Center Gym', 'Indoor basketball court', '300 Community Way', 'Riverside', 'CA', '92503', 'basketball', 'full', 'hardwood', true, true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- LEAGUES
-- ============================================================================
INSERT INTO leagues (id, organization_id, name, sport, description, commissioner_id, status, max_teams, min_players, max_players, created_at, updated_at) VALUES
('d0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Youth Soccer League', 'soccer', 'Recreational soccer for kids ages 8-12', 'a0000002-0000-0000-0000-000000000001', 'active', 8, 6, 12, NOW(), NOW()),
('d0000002-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Adult Basketball League', 'basketball', 'Competitive basketball for adults 18+', 'a0000002-0000-0000-0000-000000000001', 'active', 6, 5, 10, NOW(), NOW()),
('d0000003-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'Teen Flag Football', 'football', 'Flag football for teens 13-17', 'a0000002-0000-0000-0000-000000000001', 'draft', 8, 7, 15, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- DIVISIONS
-- ============================================================================
INSERT INTO divisions (id, league_id, name, age_group, min_age, max_age, skill_level, is_active, created_at, updated_at) VALUES
('f0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'U10 Division', '8-10', 8, 10, 'recreational', true, NOW(), NOW()),
('f0000002-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'U12 Division', '10-12', 10, 12, 'recreational', true, NOW(), NOW()),
('f0000003-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001', 'Open Division', '18+', 18, 99, 'competitive', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SEASONS
-- ============================================================================
INSERT INTO seasons (id, league_id, name, year, season_type, status, registration_start, registration_end, season_start, season_end, created_at, updated_at) VALUES
('e0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'Spring 2026', 2026, 'spring', 'active', '2026-01-01 00:00:00+00', '2026-03-01 00:00:00+00', '2026-03-15 00:00:00+00', '2026-06-15 00:00:00+00', NOW(), NOW()),
('e0000002-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'Fall 2026', 2026, 'fall', 'planning', '2026-07-01 00:00:00+00', '2026-08-15 00:00:00+00', '2026-09-01 00:00:00+00', '2026-11-30 00:00:00+00', NOW(), NOW()),
('e0000003-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001', 'Winter 2026', 2026, 'winter', 'active', '2025-11-01 00:00:00+00', '2026-01-01 00:00:00+00', '2026-01-15 00:00:00+00', '2026-03-30 00:00:00+00', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- COACHES
-- ============================================================================
INSERT INTO coaches (id, user_id, certification_level, years_experience, status, willing_to_head_coach, willing_to_assistant, created_at, updated_at) VALUES
('10000001-0000-0000-0000-000000000001', 'a0000010-0000-0000-0000-000000000001', 'level2', 5, 'approved', true, true, NOW(), NOW()),
('10000002-0000-0000-0000-000000000001', 'a0000011-0000-0000-0000-000000000001', 'level1', 3, 'approved', true, true, NOW(), NOW()),
('10000003-0000-0000-0000-000000000001', 'a0000012-0000-0000-0000-000000000001', 'level2', 7, 'approved', true, false, NOW(), NOW()),
('10000004-0000-0000-0000-000000000001', 'a0000013-0000-0000-0000-000000000001', 'level1', 2, 'approved', false, true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- TEAMS
-- ============================================================================
INSERT INTO teams (id, league_id, division_id, season_id, coach_id, name, home_field_id, color_primary, color_secondary, created_at, updated_at) VALUES
-- U10 Soccer Teams
('11000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000001', 'Riverside Eagles', 'c0000001-0000-0000-0000-000000000001', '#1E40AF', '#FBBF24', NOW(), NOW()),
('11000002-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', '10000002-0000-0000-0000-000000000001', 'Thunder FC', 'c0000002-0000-0000-0000-000000000001', '#DC2626', '#FFFFFF', NOW(), NOW()),
('11000003-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', NULL, 'Green Machine', 'c0000003-0000-0000-0000-000000000001', '#16A34A', '#000000', NOW(), NOW()),
('11000004-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', NULL, 'Blue Lightning', 'c0000004-0000-0000-0000-000000000001', '#0EA5E9', '#FFFFFF', NOW(), NOW()),
-- U12 Soccer Teams
('11000005-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'f0000002-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', '10000003-0000-0000-0000-000000000001', 'Strikers United', 'c0000001-0000-0000-0000-000000000001', '#7C3AED', '#F59E0B', NOW(), NOW()),
('11000006-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'f0000002-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', '10000004-0000-0000-0000-000000000001', 'Phoenix Rising', 'c0000002-0000-0000-0000-000000000001', '#F97316', '#1F2937', NOW(), NOW()),
('11000007-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'f0000002-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', NULL, 'Storm Chasers', 'c0000003-0000-0000-0000-000000000001', '#6366F1', '#E5E7EB', NOW(), NOW()),
('11000008-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'f0000002-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', NULL, 'Red Devils', 'c0000004-0000-0000-0000-000000000001', '#B91C1C', '#FAFAFA', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- GUARDIANS
-- ============================================================================
INSERT INTO guardians (id, user_id, relationship_type, is_emergency_contact, created_at, updated_at) VALUES
('12000001-0000-0000-0000-000000000001', 'a0000020-0000-0000-0000-000000000001', 'father', true, NOW(), NOW()),
('12000002-0000-0000-0000-000000000001', 'a0000021-0000-0000-0000-000000000001', 'mother', true, NOW(), NOW()),
('12000003-0000-0000-0000-000000000001', 'a0000022-0000-0000-0000-000000000001', 'father', true, NOW(), NOW()),
('12000004-0000-0000-0000-000000000001', 'a0000023-0000-0000-0000-000000000001', 'mother', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- PLAYERS (link users to teams)
-- ============================================================================
INSERT INTO players (id, user_id, team_id, jersey_number, position, status, created_at, updated_at) VALUES
-- Eagles players
('13000001-0000-0000-0000-000000000001', 'a0000030-0000-0000-0000-000000000001', '11000001-0000-0000-0000-000000000001', '10', 'forward', 'active', NOW(), NOW()),
('13000002-0000-0000-0000-000000000001', 'a0000031-0000-0000-0000-000000000001', '11000001-0000-0000-0000-000000000001', '7', 'midfielder', 'active', NOW(), NOW()),
('13000003-0000-0000-0000-000000000001', 'a0000032-0000-0000-0000-000000000001', '11000001-0000-0000-0000-000000000001', '1', 'goalkeeper', 'active', NOW(), NOW()),
-- Thunder FC players
('13000004-0000-0000-0000-000000000001', 'a0000033-0000-0000-0000-000000000001', '11000002-0000-0000-0000-000000000001', '4', 'defender', 'active', NOW(), NOW()),
('13000005-0000-0000-0000-000000000001', 'a0000034-0000-0000-0000-000000000001', '11000002-0000-0000-0000-000000000001', '9', 'forward', 'active', NOW(), NOW()),
('13000006-0000-0000-0000-000000000001', 'a0000035-0000-0000-0000-000000000001', '11000002-0000-0000-0000-000000000001', '11', 'midfielder', 'active', NOW(), NOW()),
-- Green Machine players
('13000007-0000-0000-0000-000000000001', 'a0000036-0000-0000-0000-000000000001', '11000003-0000-0000-0000-000000000001', '8', 'midfielder', 'active', NOW(), NOW()),
('13000008-0000-0000-0000-000000000001', 'a0000037-0000-0000-0000-000000000001', '11000003-0000-0000-0000-000000000001', '3', 'defender', 'active', NOW(), NOW()),
('13000009-0000-0000-0000-000000000001', 'a0000038-0000-0000-0000-000000000001', '11000003-0000-0000-0000-000000000001', '5', 'defender', 'active', NOW(), NOW()),
-- Blue Lightning players
('13000010-0000-0000-0000-000000000001', 'a0000039-0000-0000-0000-000000000001', '11000004-0000-0000-0000-000000000001', '12', 'forward', 'active', NOW(), NOW()),
('13000011-0000-0000-0000-000000000001', 'a0000040-0000-0000-0000-000000000001', '11000004-0000-0000-0000-000000000001', '6', 'midfielder', 'active', NOW(), NOW()),
('13000012-0000-0000-0000-000000000001', 'a0000041-0000-0000-0000-000000000001', '11000004-0000-0000-0000-000000000001', '2', 'defender', 'active', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- PLAYER-GUARDIAN RELATIONSHIPS
-- ============================================================================
INSERT INTO player_guardians (id, player_id, guardian_id, is_primary, created_at) VALUES
('14000001-0000-0000-0000-000000000001', '13000001-0000-0000-0000-000000000001', '12000001-0000-0000-0000-000000000001', true, NOW()),
('14000002-0000-0000-0000-000000000001', '13000002-0000-0000-0000-000000000001', '12000002-0000-0000-0000-000000000001', true, NOW()),
('14000003-0000-0000-0000-000000000001', '13000003-0000-0000-0000-000000000001', '12000003-0000-0000-0000-000000000001', true, NOW()),
('14000004-0000-0000-0000-000000000001', '13000004-0000-0000-0000-000000000001', '12000004-0000-0000-0000-000000000001', true, NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SCHEDULED EVENTS (Games & Practices)
-- ============================================================================
INSERT INTO scheduled_events (id, season_id, event_type, title, description, start_time, end_time, field_id, home_team_id, away_team_id, status, created_at, updated_at) VALUES
-- Week 1 Games (March 15, 2026)
('15000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'game', 'Eagles vs Thunder FC', 'U10 Division - Week 1', '2026-03-15 10:00:00+00', '2026-03-15 11:30:00+00', 'c0000001-0000-0000-0000-000000000001', '11000001-0000-0000-0000-000000000001', '11000002-0000-0000-0000-000000000001', 'scheduled', NOW(), NOW()),
('15000002-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'game', 'Green Machine vs Blue Lightning', 'U10 Division - Week 1', '2026-03-15 12:00:00+00', '2026-03-15 13:30:00+00', 'c0000002-0000-0000-0000-000000000001', '11000003-0000-0000-0000-000000000001', '11000004-0000-0000-0000-000000000001', 'scheduled', NOW(), NOW()),
('15000003-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'game', 'Strikers vs Phoenix Rising', 'U12 Division - Week 1', '2026-03-15 14:00:00+00', '2026-03-15 15:30:00+00', 'c0000003-0000-0000-0000-000000000001', '11000005-0000-0000-0000-000000000001', '11000006-0000-0000-0000-000000000001', 'scheduled', NOW(), NOW()),
('15000004-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'game', 'Storm Chasers vs Red Devils', 'U12 Division - Week 1', '2026-03-15 16:00:00+00', '2026-03-15 17:30:00+00', 'c0000004-0000-0000-0000-000000000001', '11000007-0000-0000-0000-000000000001', '11000008-0000-0000-0000-000000000001', 'scheduled', NOW(), NOW()),

-- Week 2 Games (March 22, 2026)
('15000005-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'game', 'Eagles vs Green Machine', 'U10 Division - Week 2', '2026-03-22 10:00:00+00', '2026-03-22 11:30:00+00', 'c0000001-0000-0000-0000-000000000001', '11000001-0000-0000-0000-000000000001', '11000003-0000-0000-0000-000000000001', 'scheduled', NOW(), NOW()),
('15000006-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'game', 'Thunder FC vs Blue Lightning', 'U10 Division - Week 2', '2026-03-22 12:00:00+00', '2026-03-22 13:30:00+00', 'c0000002-0000-0000-0000-000000000001', '11000002-0000-0000-0000-000000000001', '11000004-0000-0000-0000-000000000001', 'scheduled', NOW(), NOW()),

-- Practices
('15000010-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'practice', 'Eagles Practice', 'Weekly team practice', '2026-03-18 17:00:00+00', '2026-03-18 18:30:00+00', 'c0000001-0000-0000-0000-000000000001', '11000001-0000-0000-0000-000000000001', NULL, 'scheduled', NOW(), NOW()),
('15000011-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'practice', 'Thunder FC Practice', 'Weekly team practice', '2026-03-18 17:00:00+00', '2026-03-18 18:30:00+00', 'c0000002-0000-0000-0000-000000000001', '11000002-0000-0000-0000-000000000001', NULL, 'scheduled', NOW(), NOW()),
('15000012-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'practice', 'Green Machine Practice', 'Weekly team practice', '2026-03-19 17:00:00+00', '2026-03-19 18:30:00+00', 'c0000003-0000-0000-0000-000000000001', '11000003-0000-0000-0000-000000000001', NULL, 'scheduled', NOW(), NOW()),
('15000013-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'practice', 'Blue Lightning Practice', 'Weekly team practice', '2026-03-19 17:00:00+00', '2026-03-19 18:30:00+00', 'c0000004-0000-0000-0000-000000000001', '11000004-0000-0000-0000-000000000001', NULL, 'scheduled', NOW(), NOW()),

-- Team meeting
('15000020-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'meeting', 'Season Kickoff Meeting', 'All teams welcome - season overview and Q&A', '2026-03-14 18:00:00+00', '2026-03-14 19:30:00+00', 'c0000005-0000-0000-0000-000000000001', NULL, NULL, 'scheduled', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- CALENDAR SUBSCRIPTIONS (Sample for coach user)
-- ============================================================================
INSERT INTO calendar_subscriptions (id, user_id, token, subscription_type, resource_id, name, event_types, include_cancelled, is_active, access_count, created_at, updated_at) VALUES
('16000001-0000-0000-0000-000000000001', 'a0000010-0000-0000-0000-000000000001', 'demo_coach_team_feed_token_xyz789abc', 'team', '11000001-0000-0000-0000-000000000001', 'Eagles Schedule', '["game", "practice", "scrimmage"]', false, true, 0, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- OUTPUT SUMMARY
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'TeamIO Seed Data Loaded Successfully!';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Test Accounts (password: password123):';
    RAISE NOTICE '  - admin@teamio.local (Admin)';
    RAISE NOTICE '  - commissioner@teamio.local (Commissioner)';
    RAISE NOTICE '  - coach.smith@teamio.local (Coach)';
    RAISE NOTICE '  - parent.jones@teamio.local (Guardian)';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Sample Data:';
    RAISE NOTICE '  - 1 Organization';
    RAISE NOTICE '  - 5 Fields';
    RAISE NOTICE '  - 3 Leagues';
    RAISE NOTICE '  - 3 Seasons';
    RAISE NOTICE '  - 3 Divisions';
    RAISE NOTICE '  - 8 Teams';
    RAISE NOTICE '  - 12 Players';
    RAISE NOTICE '  - 11 Scheduled Events';
    RAISE NOTICE '==========================================';
END $$;
