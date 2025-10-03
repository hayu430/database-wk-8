# Clinic Booking & Management System Database

## 📌 Overview
This project is a **relational database system** built in **MySQL** for managing clinic operations.  
It supports patient records, doctor information, appointments, consultations, prescriptions, invoices, and payments.  
The design follows good database practices with normalization, proper constraints, and different types of relationships.

---

## 🎯 Features
- **Patient Management**: Store demographic details, insurance policies, and contact info.
- **Doctor & Specialties**: Doctors can have multiple specialties (many-to-many relationship).
- **Appointments**: Patients can book appointments with doctors, with room allocation.
- **Consultations**: Each appointment may include a medical consultation record (one-to-one).
- **Medications & Prescriptions**: Track prescribed medications with dosage, frequency, and duration.
- **Invoices & Payments**: Generate invoices for appointments and record multiple payments.
- **Insurance Integration**: Link patients with insurance providers and policies.

---

## 🗂️ Database Schema
- **patients** → Patient information.  
- **insurance_providers** → List of insurance companies.  
- **patient_insurance** → Patient insurance policies (many-to-one with insurance).  
- **doctors** → Doctor information.  
- **specialties** → Medical specialties.  
- **doctor_specialties** → Junction table (many-to-many between doctors and specialties).  
- **rooms** → Clinic rooms for appointments.  
- **appointments** → Patient-doctor meetings (linked to patients, doctors, and rooms).  
- **consultations** → One-to-one with appointments, holds medical details.  
- **medications** → List of medications.  
- **prescriptions** → Prescriptions linked to appointments.  
- **prescription_items** → Medications prescribed in each prescription.  
- **invoices** → Bills for appointments.  
- **payments** → Payment records for invoices.

---

## 🔗 Relationships
- **One-to-Many**:  
  - Patient → Appointments  
  - Doctor → Appointments  
  - Appointment → Prescriptions  
  - Invoice → Payments  

- **One-to-One**:  
  - Appointment → Consultation  

- **Many-to-Many**:  
  - Doctors ↔ Specialties  
  - Prescriptions ↔ Medications  

---

## ⚙️ Installation
1. Make sure you have **MySQL/MariaDB** installed.
2. Clone or download this project.
3. Run the SQL script:
   ```bash
   mysql -u your_user -p < clinic_db.sql
📦 Deliverables

clinic_db.sql → Database schema with constraints and optional demo data.

README.md → Documentation (this file).

👨‍💻 Author

Hayu Yonatan
Software Engineering Student | Web Development & Cybersecurity Enthusiast
