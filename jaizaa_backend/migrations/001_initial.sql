-- Neon Postgres schema for Jaizaa MVP

-- Drop old tables if they exist (fresh start)
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS patients CASCADE;

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) DEFAULT '',
    risk_level VARCHAR(50) DEFAULT 'UNKNOWN',
    follow_up_status VARCHAR(50) DEFAULT 'NONE',
    care_gap VARCHAR(50) DEFAULT 'OPEN',
    doctor_awareness VARCHAR(50) DEFAULT 'UNAWARE',
    last_analyzed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE appointments (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id),
    specialty VARCHAR(100),
    scheduled_slot VARCHAR(100),
    reason TEXT,
    priority VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id),
    flagged_values JSONB DEFAULT '{}',
    clinical_pattern VARCHAR(255),
    urgency_level VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id),
    channel VARCHAR(50),
    message_text TEXT,
    status VARCHAR(50) DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed data for demo
INSERT INTO patients (name, phone, risk_level, follow_up_status, care_gap, doctor_awareness) 
VALUES ('Ahmed Khan', '+923001234567', 'UNKNOWN', 'NONE', 'OPEN', 'UNAWARE');
