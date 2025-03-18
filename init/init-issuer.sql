-- Create the database
CREATE DATABASE issuer_db;

-- Create users (renamed `b` to `c` to avoid conflicts)
CREATE USER issuer_mgmt_user WITH PASSWORD 'secret';
CREATE USER issuer_oid4vci_user WITH PASSWORD 'secret';

-- Create role group with NOLOGIN (explicit)
CREATE ROLE issuer_db_writers NOLOGIN;

-- Grant users access to the role
GRANT issuer_db_writers TO issuer_mgmt_user;
GRANT issuer_db_writers TO issuer_oid4vci_user;

-- Allow the role to connect to database issuer_db
GRANT CONNECT ON DATABASE issuer_db TO issuer_db_writers;

-- Switch to database `issuer_db`
\c issuer_db;

-- Ensure schema `public` is accessible before granting privileges
GRANT USAGE ON SCHEMA public TO issuer_db_writers;
GRANT CREATE ON SCHEMA public TO issuer_db_writers;

-- Grant permissions for existing tables and sequences
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO issuer_db_writers;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO issuer_db_writers;

-- Ensure future tables and sequences are also accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO issuer_db_writers;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO issuer_db_writers;
