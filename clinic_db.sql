-- clinic_db.sql
-- Clinic Booking & Management System
-- MySQL / MariaDB SQL script
-- Uses InnoDB for FK support and utf8mb4 charset

CREATE DATABASE IF NOT EXISTS clinic_db
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_general_ci;
USE clinic_db;

-- -------------------------------
-- Table: patients
-- -------------------------------
CREATE TABLE patients (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  dob DATE,
  gender ENUM('male','female','other') DEFAULT 'other',
  email VARCHAR(255),
  phone VARCHAR(30),
  address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (email),
  UNIQUE (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: insurance_providers
-- -------------------------------
CREATE TABLE insurance_providers (
  insurance_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL UNIQUE,
  phone VARCHAR(30),
  website VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: patient_insurance (one-to-many: patient -> patient_insurance, many-to-one: insurance -> patient_insurance)
-- (a patient may have multiple policies over time)
-- -------------------------------
CREATE TABLE patient_insurance (
  patient_insurance_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  insurance_id INT NOT NULL,
  policy_number VARCHAR(100) NOT NULL,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (patient_id, policy_number),
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (insurance_id) REFERENCES insurance_providers(insurance_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: doctors
-- -------------------------------
CREATE TABLE doctors (
  doctor_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(30),
  hire_date DATE,
  bio TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (email),
  UNIQUE (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: specialties
-- -------------------------------
CREATE TABLE specialties (
  specialty_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  description TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: doctor_specialties (many-to-many: doctors <-> specialties)
-- -------------------------------
CREATE TABLE doctor_specialties (
  doctor_id INT NOT NULL,
  specialty_id INT NOT NULL,
  PRIMARY KEY (doctor_id, specialty_id),
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: rooms
-- -------------------------------
CREATE TABLE rooms (
  room_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  location VARCHAR(255),
  capacity INT DEFAULT 1,
  notes TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: appointments
-- - One-to-many: patient -> appointments
-- - One-to-many: doctor -> appointments
-- - Optional one-to-one-ish: appointment -> room (room can be used by many appointments over time)
-- -------------------------------
CREATE TABLE appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  doctor_id INT NOT NULL,
  room_id INT, -- optional
  appointment_start DATETIME NOT NULL,
  appointment_end DATETIME NOT NULL,
  status ENUM('scheduled','checked_in','in_progress','completed','cancelled','no_show') DEFAULT 'scheduled',
  reason VARCHAR(255),
  created_by VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (room_id) REFERENCES rooms(room_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  -- Prevent the same doctor from having two appointments that start at the same time
  UNIQUE KEY ux_doctor_time (doctor_id, appointment_start),
  -- Prevent same room double-booking at the exact start time
  UNIQUE KEY ux_room_time (room_id, appointment_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Note: The UNIQUE constraints on (doctor_id, appointment_start) and (room_id, appointment_start)
-- are simple protections; more complex overlap checks (partial overlaps) should be enforced at application level or by triggers.

-- -------------------------------
-- Table: consultations (one-to-one with appointments -> optional detailed record)
-- Example of one-to-one relationship: each appointment may have one consultation record
-- -------------------------------
CREATE TABLE consultations (
  consultation_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL UNIQUE,
  diagnosis TEXT,
  examination_notes TEXT,
  follow_up_in_days INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: medications
-- -------------------------------
CREATE TABLE medications (
  medication_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  manufacturer VARCHAR(200),
  unit VARCHAR(50), -- e.g., mg, ml, tablet
  UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: prescriptions
-- - one-to-many: appointment -> prescriptions (an appointment can result in multiple prescriptions)
-- -------------------------------
CREATE TABLE prescriptions (
  prescription_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT, -- optional, but usually tied to an appointment
  prescribed_date DATE NOT NULL DEFAULT CURRENT_DATE,
  prescriber_id INT, -- doctor who prescribed
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (prescriber_id) REFERENCES doctors(doctor_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: prescription_items (many-to-many: prescriptions <-> medications with extra attributes)
-- -------------------------------
CREATE TABLE prescription_items (
  prescription_item_id INT AUTO_INCREMENT PRIMARY KEY,
  prescription_id INT NOT NULL,
  medication_id INT NOT NULL,
  dosage VARCHAR(100) NOT NULL, -- e.g., "500 mg"
  frequency VARCHAR(100), -- e.g., "twice a day"
  duration_days INT,
  instructions TEXT,
  FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (medication_id) REFERENCES medications(medication_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: invoices
-- - one-to-one or one-to-many relation with appointment (an appointment may produce invoice(s))
-- -------------------------------
CREATE TABLE invoices (
  invoice_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT,
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  tax DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  paid BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Table: payments
-- - many payments may map to one invoice
-- -------------------------------
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  amount DECIMAL(12,2) NOT NULL,
  method ENUM('cash','card','bank_transfer','insurance','other') DEFAULT 'cash',
  reference VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------
-- Useful indexes (performance helpers)
-- -------------------------------
CREATE INDEX idx_patient_name ON patients(last_name, first_name);
CREATE INDEX idx_doctor_name ON doctors(last_name, first_name);
CREATE INDEX idx_appointment_start ON appointments(appointment_start);
CREATE INDEX idx_appointment_patient ON appointments(patient_id);
CREATE INDEX idx_prescription_date ON prescriptions(prescribed_date);
CREATE INDEX idx_invoice_date ON invoices(invoice_date);

-- -------------------------------
-- Example triggers (optional): update invoice.total when subtotal/tax change
-- (Uncomment if you want to create triggers; MySQL user must have privileges)
-- -------------------------------
/*
DELIMITER $$
CREATE TRIGGER trg_invoice_before_insert
BEFORE INSERT ON invoices
FOR EACH ROW
BEGIN
  SET NEW.total = COALESCE(NEW.subtotal, 0) + COALESCE(NEW.tax, 0);
END$$

CREATE TRIGGER trg_invoice_before_update
BEFORE UPDATE ON invoices
FOR EACH ROW
BEGIN
  SET NEW.total = COALESCE(NEW.subtotal, 0) + COALESCE(NEW.tax, 0);
END$$
DELIMITER ;
*/

-- -------------------------------
-- Sample inserted rows (optional demo data)
-- Uncomment to insert demos
-- -------------------------------
/*
INSERT INTO specialties (name) VALUES ('General Practice'), ('Pediatrics'), ('Cardiology');

INSERT INTO doctors (first_name,last_name,email,phone,hire_date) VALUES
('Mulu','Getnet','mulu@getclinic.example','+251900000001','2018-06-01'),
('Amanuel','Bekele','amanuel@getclinic.example','+251900000002','2019-09-15');

INSERT INTO doctor_specialties (doctor_id, specialty_id) VALUES (1,1), (2,1), (2,3);

INSERT INTO patients (first_name,last_name,email,phone,dob) VALUES
('Hayu','Yonatan','hayu@example.com','+251900000010','2000-05-20'),
('Selam','Kebede','selam@example.com','+251900000011','1995-07-12');

INSERT INTO rooms (name,location) VALUES ('Room A','First Floor'), ('Room B','Second Floor');

INSERT INTO appointments (patient_id, doctor_id, room_id, appointment_start, appointment_end, reason)
VALUES (1,1,1,'2025-10-10 09:00:00','2025-10-10 09:30:00','Routine checkup');
*/

