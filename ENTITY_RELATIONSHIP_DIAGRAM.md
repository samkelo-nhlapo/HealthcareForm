# Entity Relationship Diagram & Table Structure Guide

## Complete Database Schema (34 Tables)

### PATIENT HUB - Central Patient Record
```
┌─────────────────────────────────────────────────────┐
│                 Profile.Patient                     │
│─────────────────────────────────────────────────────│
│ PatientId (PK) [GUID]                              │
│ FirstName, LastName, ID_Number (UNIQUE)            │
│ DateOfBirth, GenderIDFK → Profile.Gender           │
│ MedicationList (VARCHAR MAX)                        │
│ AddressIDFK → Location.Address                      │
│ MaritalStatusIDFK → Profile.MaritalStatus           │
│ EmergencyIDFK → Contacts.EmergencyContacts          │
│ IsDeleted, CreatedDate, UpdatedDate, Audit Cols    │
└─────────────────────────────────────────────────────┘
                        │
          ┌─────────────┼─────────────┐
          │             │             │
          ▼             ▼             ▼
    Medical Records  Forms         Services
```

---

## DOMAIN 1: MEDICAL & HEALTH RECORDS

```
Profile.Patient
    │
    ├─→ Profile.MedicalHistory (1:N)
    │   └─ Condition, DiagnosisDate, Status, ICD10Code
    │
    ├─→ Profile.Allergies (1:N)
    │   └─ AllergyType, AllergenName, Reaction, Severity
    │
    ├─→ Profile.Medications (1:N)
    │   └─ MedicationName, Dosage, Frequency, Route, Status, PrescribedBy
    │
    ├─→ Profile.Vaccinations (1:N)
    │   └─ VaccineName, AdministrationDate, Lot, Reaction
    │
    └─→ Profile.LabResults (1:N)
        └─ TestName, ResultValue, Status, Lab, FileAttachmentId
```

### Medical History
- Tracks chronic conditions (Diabetes, Hypertension, etc.)
- Tracks resolved conditions for historical reference
- ICD-10 coding for clinical classification

### Allergies
- Multiple allergies per patient
- Severity tracking (Mild → Life-threatening)
- Verified by healthcare provider

### Medications
- Active, discontinued, and historical records
- Links to prescribing doctor
- Side effects and contraindications
- Dosage and frequency information

### Vaccinations
- Immunization records
- Booster tracking with DueDate
- Lot number for safety tracking
- Adverse reaction documentation

### Lab Results
- Single test result per record
- Reference ranges for comparison
- Status: Normal/Abnormal/Critical/Pending
- Doctor interpretation field

---

## DOMAIN 2: FORMS & SUBMISSIONS

```
Contacts.FormTemplates (1:N) Contacts.FormSubmissions
│                                    │
└─────────────────────────────────────┤
                                      │
                                      ├─→ Contacts.FormFieldValues (1:N)
                                      │   └─ FieldName, FieldValue, FieldType
                                      │
                                      └─→ Contacts.FormAttachments (1:N)
                                          └─ FileName, FileType, DocumentType
```

### Form Templates
- Reusable form definitions
- Versioning support (v1.0, v2.0, etc.)
- Types: Intake, Consent, Medical History, Insurance, Discharge
- Signature requirement flag

### Form Submissions
- Patient → Template mapping
- Status tracking: Draft → Submitted → Approved → Signed
- Review workflow with ReviewedBy/ReviewDate
- IP address and User Agent for compliance

### Form Field Values
- Individual answers to form questions
- Field type validation (Text, Date, Checkbox, Radio, etc.)
- Custom validation rules as JSON
- Display order for correct rendering

### Form Attachments
- Scanned documents, prescriptions, medical records
- File verification (hash-based integrity)
- Document type categorization
- Expiry date tracking for documents

---

## DOMAIN 3: HEALTHCARE SERVICES

```
Profile.HealthcareProviders (Hub)
    │
    ├─→ Profile.Appointments (1:N from both Patient & Provider)
    │   ├─ AppointmentDateTime, DurationMinutes
    │   ├─ Status: Scheduled/In Progress/Completed/Cancelled/No-show
    │   └─ Reminders (JSON array)
    │
    ├─→ Profile.ConsultationNotes (1:N from Patient)
    │   ├─ ChiefComplaint, PresentingSymptoms, History
    │   ├─ Diagnosis, DiagnosisCodes (ICD-10)
    │   ├─ TreatmentPlan, Medications, Procedures
    │   └─ FollowUpDate, ReferralNeeded
    │
    └─→ Profile.Referrals (1:N to other Providers)
        ├─ ReferralType: Specialist, Second Opinion, Procedure
        ├─ Priority: Urgent/Normal/Routine
        ├─ Status: Pending/Accepted/In Progress/Completed
        └─ ReferralCode for insurance authorization
```

### Healthcare Providers
- Doctors, Nurses, Therapists, Specialists
- License number (unique, regulated)
- Specialization and qualifications
- Office location via Address FK

### Appointments
- Bidirectional: Patient has Appointment with Provider
- Types: Consultation, Follow-up, Check-up, Procedure
- Cancellation tracking with reason and date
- Reminder preferences stored as JSON

### Consultation Notes
- Comprehensive visit documentation
- SOAP format support: Subjective/Objective/Assessment/Plan
- Multiple diagnosis support with ICD-10 codes
- Treatment plans with follow-up dates

### Referrals
- Specialist referrals from primary doctor
- Can be assigned to specific provider later
- Insurance authorization codes
- Priority-based routing (urgent vs routine)

---

## DOMAIN 4: INSURANCE & BILLING

```
Profile.InsuranceProviders (1:N) Profile.PatientInsurance
    │                                   │
    │                                   └─→ Profile.Patient
    │
    └─ Contact Info, Address, Phone, Email

Profile.Patient (1:N) Profile.Invoices
                          │
                          ├─→ Profile.HealthcareProviders
                          ├─→ Profile.BillingCodes
                          └─ Status: Draft/Sent/Paid/Overdue
```

### Insurance Providers
- Insurance company details
- Registration/license numbers
- Provider billing codes
- Contact information

### Patient Insurance
- Multiple insurances per patient (primary/secondary)
- Deductible, copay, out-of-pocket max
- Employer information for group plans
- Coverage start/expiry dates
- IsPrimary flag for coordination of benefits

### Billing Codes
- ICD-10 codes for diagnosis
- CPT codes for procedures
- HCPCS codes for services
- Cost database for pricing

### Invoices
- Service-based invoices
- Quantity support (multiple visits)
- Insurance coverage calculation
- Patient responsibility calculation
- Payment tracking: method, date, amount
- Status workflow: Draft → Sent → Partial Paid → Paid/Overdue

---

## DOMAIN 5: SECURITY & ACCESS CONTROL

```
Auth.Users (1:N) Auth.UserRoles (N:M) Auth.Roles
    │                                      │
    │                                      └─→ Auth.RolePermissions (N:M)
    │                                           └─→ Auth.Permissions
    │
    └─→ Auth.UserActivityAudit (1:N)
        └─ Login/Logout/DataAccess/Modification tracking
```

### Users
- Username (unique, indexed)
- Email (unique, indexed)
- Password hash (bcrypt recommended)
- Account status: Active, Locked, Disabled
- Account lock tracking for failed logins
- Last login timestamp
- Super admin flag for system access

### Roles
- 7 Standard Roles: ADMIN, DOCTOR, NURSE, RECEPTIONIST, PATIENT, BILLING, PHARMACIST
- Customizable descriptions
- Enable/disable at role level

### Permissions
- Fine-grained: Patient_Create, Patient_Read, Patient_Update, etc.
- Categorized: Patient, Medication, Appointment, Billing, Admin
- Action-based: Create, Read, Update, Delete, Approve, Print

### User Roles Junction
- User-to-Role mapping (N:M)
- Temporary assignments with expiry dates
- Grant tracking (who assigned when)

### Role Permissions Junction
- Role-to-Permission mapping (N:M)
- Enable entire permission sets per role
- Audit trail of permission grants

### User Activity Audit
- Comprehensive logging: Login, Logout, DataAccess, DataModification
- Table and Record ID tracking for changes
- Old/New value comparison
- IP address and User Agent for forensics
- Success/Failed status with error messages
- Per-second timestamp accuracy

---

## EXISTING TABLES (Not New)

### Profile Schema
- **Gender** - Lookup: Male, Female, Other, Prefer Not to Say
- **MaritalStatus** - Lookup: Single, Married, Divorced, Widowed
- **Patient** - Core patient record (enhanced from original)

### Location Schema
- **Countries** - Country lookup
- **Provinces** - Province/State lookup
- **Cities** - City lookup
- **Address** - Full address records with city FK

### Contacts Schema
- **Phones** - Phone number records
- **Emails** - Email address records
- **EmergencyContacts** - Emergency contact information
- **PatientPhones** - Junction: Patient → Multiple Phones
- **PatientEmails** - Junction: Patient → Multiple Emails

### Auth Schema
- **AuditLog** - Data modification audit (triggers-based)
- **DB_Errors** - Database error logging

### Exceptions Schema
- **Errors** - System exception tracking

---

## Key Indexes (Total: 45+)

### Primary Keys (Clustered)
- All tables use GUID primary keys with IDENTITY not used

### Foreign Key Indexes
- All FKs have corresponding non-clustered indexes

### Search Optimization Indexes
```
Patient: ID_Number, LastName, IsDeleted
Allergies: PatientIdFK, Severity
Medications: PatientIdFK, Status
Appointments: PatientIdFK, ProviderIdFK, DateTime, Status
FormSubmissions: PatientIdFK, Status, SubmissionDate
Invoices: PatientIdFK, Status, InvoiceDate
Users: Username, Email, IsActive
UserActivityAudit: UserIdFK, ActivityType, ActivityDateTime
```

---

## Data Flow Examples

### Patient Registration Workflow
```
1. Create Auth.Users (receptionist or patient)
2. Assign role via Auth.UserRoles
3. Create Profile.Patient
4. Create Location.Address for patient
5. Create Contacts.Phones entries
6. Create Contacts.Emails entries
7. Link via Contacts.PatientPhones and PatientEmails
```

### Form Submission Workflow
```
1. Select FormTemplate
2. Create FormSubmission (status: Draft)
3. Populate FormFieldValues (answers)
4. Upload FormAttachments (if needed)
5. Submit form (status: Submitted)
6. Review by admin (status: Pending Review)
7. Approve/Reject (status: Approved/Rejected)
8. Patient/Doctor signs (status: Signed)
9. Archive in AuditLog
```

### Appointment & Consultation Workflow
```
1. Create Appointment with HealthcareProvider
2. Patient arrives and completes check-in
3. Doctor creates ConsultationNotes
4. Doctor records Diagnosis with ICD-10 codes
5. Doctor orders tests → LabResults created
6. Doctor may create Referral to specialist
7. Medications updated if prescribed
8. Invoice created with BillingCodes
9. Insurance claim sent
10. Audit logged via triggers
```

### Insurance Verification Workflow
```
1. Lookup PatientInsurance by ExpiryDate
2. Check InsuranceProviders contact info
3. Verify coverage via CoverageType and Plan
4. Calculate Deductible, Copay, OOP Max
5. Validate policy is Active (status check)
6. Link to Invoices for claim submission
7. Audit access via UserActivityAudit
```

---

## Normalization Status

All tables are in **3NF (Third Normal Form)**:
- ✓ No repeating groups (junction tables for N:M relationships)
- ✓ All non-key attributes dependent on primary key
- ✓ No transitive dependencies

---

## Total Column Count by Table Type

| Category | Tables | Avg Cols | Typical Cols |
|----------|--------|----------|--------------|
| Medical Records | 5 | 12 | Condition, Date, Status, FK, Audit |
| Forms | 4 | 13 | Template, Fields, Values, Status, Audit |
| Services | 4 | 14 | DateTime, Provider, Notes, Status, Audit |
| Insurance | 4 | 11 | Code, Amount, Status, Dates, Audit |
| Security | 6 | 12 | User, Role, Permission, Activity, Audit |
| **TOTAL** | **34** | **12.4** | **~420 columns** |

---

## Document Information
- **Created**: February 14, 2026
- **Author**: Samkelo Nhlapo
- **Version**: 1.0
- **Database**: HealthcareForm
- **Status**: Production Ready
