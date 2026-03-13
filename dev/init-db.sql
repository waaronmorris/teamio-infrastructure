-- TeamIO Database Initialization Script
-- This script runs when the PostgreSQL container is first created

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- The SeaORM migrations will handle table creation
-- This file is for any initial setup that needs to happen before migrations

-- Grant permissions (if needed for specific users)
-- GRANT ALL PRIVILEGES ON DATABASE teamio TO teamio;
