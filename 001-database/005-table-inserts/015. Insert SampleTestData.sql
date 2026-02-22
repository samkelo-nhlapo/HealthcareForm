USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert comprehensive sample test data - complete patient profile for testing
--	TFS Task:		Create test data for application validation and demonstration
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE(),
		@TestDate DATETIME = DATEADD(YEAR, -1, @DefaultDate),
		@CityId_JNB INT = (SELECT CityId FROM Location.Cities WHERE CityName = 'Johannesburg'),
		@CountryId INT = (SELECT CountryId FROM Location.Countries WHERE CountryCode = 'ZA'),
		@GenderId_MALE INT = (SELECT GenderId FROM Profile.Gender WHERE GenderDescription = 'Male'),
		@MaritalStatusId INT = (SELECT MaritalStatusId FROM Profile.MaritalStatus WHERE MaritalStatusDescription = 'Married'),
		@MaleProviderId INT = (SELECT HealthcareProviderId FROM HealthcareServices.HealthcareProviders WHERE ProviderName = 'Dr. Thabo Mthembu'),
		@AllergyId_Penicillin INT = (SELECT AllergyId FROM Profile.Allergies WHERE AllergyName = 'Penicillin'),
		@MedicationId_Lisinopril INT = (SELECT MedicationId FROM Profile.Medications WHERE MedicationName = 'Lisinopril'),
		@MedicationId_Metformin INT = (SELECT MedicationId FROM Profile.Medications WHERE MedicationName = 'Metformin'),
		@InsuranceProviderId INT = (SELECT InsuranceProviderId FROM HealthcareServices.InsuranceProviders WHERE ProviderName = 'Discovery Health'),
		@AddressId INT,
		@PatientId INT

-- Step 1: Create Address
INSERT INTO Location.Address (StreetAddress, CityIdFK, PostalCode, IsActive, CreatedDate, CreatedBy)
VALUES ('123 Oak Street, Sandton', @CityId_JNB, '2196', 1, @DefaultDate, 'SYSTEM')

SET @AddressId = @@IDENTITY

-- Step 2: Create Patient
INSERT INTO Profile.Patient (
	FirstName, LastName, DateOfBirth, IDNumber, GenderIdFK, MaritalStatusIdFK, AddressIdFK, 
	IsActive, CreatedDate, CreatedBy
)
VALUES (
	'John', 'Anderson', '1975-06-15', '7506150123456', @GenderId_MALE, @MaritalStatusId, @AddressId,
	1, @DefaultDate, 'SYSTEM'
)

SET @PatientId = @@IDENTITY

-- Step 3: Add Patient Phones
INSERT INTO Contacts.PatientPhones (PatientIdFK, PhoneNumber, PhoneType, IsPrimary, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, '+27 11 123 4567', 'MOBILE', 1, 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, '+27 11 555 6789', 'HOME', 0, 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, '+27 11 999 8765', 'WORK', 0, 1, @DefaultDate, 'SYSTEM')

-- Step 4: Add Patient Emails
INSERT INTO Contacts.PatientEmails (PatientIdFK, EmailAddress, EmailType, IsPrimary, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, 'john.anderson@email.com', 'PERSONAL', 1, 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'j.anderson@company.com', 'WORK', 0, 1, @DefaultDate, 'SYSTEM')

-- Step 5: Add Emergency Contact
INSERT INTO Contacts.EmergencyContacts (PatientIdFK, ContactName, Relationship, PhoneNumber, EmailAddress, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, 'Sarah Anderson', 'SPOUSE', '+27 11 222 3333', 'sarah.anderson@email.com', 1, @DefaultDate, 'SYSTEM')

-- Step 6: Add Allergies
INSERT INTO Profile.PatientAllergies (PatientIdFK, AllergyIdFK, ReactionSeverity, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, @AllergyId_Penicillin, 'HIGH', 1, @DefaultDate, 'SYSTEM')

-- Step 7: Add Current Medications
INSERT INTO Profile.PatientMedications (PatientIdFK, MedicationIdFK, Dosage, Frequency, StartDate, EndDate, Reason, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, @MedicationId_Lisinopril, '10mg', 'ONCE_DAILY', @TestDate, NULL, 'Hypertension management', 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, @MedicationId_Metformin, '500mg', 'TWICE_DAILY', @TestDate, NULL, 'Type 2 diabetes management', 1, @DefaultDate, 'SYSTEM')

-- Step 8: Add Medical History
INSERT INTO Profile.MedicalHistory (PatientIdFK, MedicalCondition, DiagnosisDate, DiagnosingProviderIdFK, Status, ICD10Code, Notes, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, 'Type 2 Diabetes Mellitus', DATEADD(YEAR, -5, @DefaultDate), @MaleProviderId, 'CHRONIC', 'E11.9', 'Well-controlled with medication', 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'Essential Hypertension', DATEADD(YEAR, -8, @DefaultDate), @MaleProviderId, 'CHRONIC', 'I10', 'Stage 1 hypertension, stable', 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'Hyperlipidemia', DATEADD(YEAR, -3, @DefaultDate), @MaleProviderId, 'ACTIVE', 'E78.5', 'Monitoring required', 1, @DefaultDate, 'SYSTEM')

-- Step 9: Add Vaccinations
INSERT INTO Profile.Vaccinations (PatientIdFK, VaccineName, VaccinationDate, ExpiryDate, Manufacturer, LotNumber, AdministeredByProviderIdFK, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, 'COVID-19 Vaccine (Pfizer)', DATEADD(MONTH, -3, @DefaultDate), DATEADD(YEAR, 1, DATEADD(MONTH, -3, @DefaultDate)), 'Pfizer', 'LOT123456', @MaleProviderId, 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'Influenza Vaccine', DATEADD(MONTH, -6, @DefaultDate), DATEADD(YEAR, 1, DATEADD(MONTH, -6, @DefaultDate)), 'Sanofi Pasteur', 'LOT789012', @MaleProviderId, 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'Tetanus Booster', DATEADD(YEAR, -3, @DefaultDate), DATEADD(YEAR, 10, DATEADD(YEAR, -3, @DefaultDate)), 'Various', 'LOT345678', @MaleProviderId, 1, @DefaultDate, 'SYSTEM')

-- Step 10: Add Appointment
INSERT INTO HealthcareServices.Appointments (PatientIdFK, ProviderIdFK, AppointmentDateTime, Duration, Status, AppointmentReason, Notes, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, @MaleProviderId, DATEADD(DAY, 7, @DefaultDate), 30, 'SCHEDULED', 'Regular diabetes and hypertension checkup', 'Quarterly follow-up as per treatment plan', 1, @DefaultDate, 'SYSTEM')

-- Step 11: Add Consultation Notes
INSERT INTO HealthcareServices.ConsultationNotes (PatientIdFK, ProviderIdFK, ConsultationDate, ClinicalFindings, Diagnosis, TreatmentPlan, FollowUpRequired, FollowUpDate, Notes, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, @MaleProviderId, DATEADD(MONTH, -1, @DefaultDate), 
	 'BP: 138/88 mmHg, HR: 72 bpm, Weight: 82kg, Height: 178cm. Fasting blood glucose: 118 mg/dL. Patient reports good medication compliance.',
	 'Type 2 Diabetes Mellitus - controlled; Essential Hypertension - controlled; Hyperlipidemia - requires monitoring',
	 'Continue current medications. Lifestyle modifications: increase exercise to 150 min/week, reduce sodium intake. Repeat lab work in 3 months.',
	 1, DATEADD(MONTH, 3, DATEADD(MONTH, -1, @DefaultDate)), 
	 'Patient education provided on diabetes management and cardiovascular risk reduction.', 1, @DefaultDate, 'SYSTEM')

-- Step 12: Add Lab Results
INSERT INTO Profile.LabResults (PatientIdFK, TestName, TestCategory, ResultValue, UnitOfMeasure, ReferenceRange, Status, TestDate, OrderedByProviderIdFK, Notes, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, 'Fasting Blood Glucose', 'HEMATOLOGY', '118', 'mg/dL', '70-100', 'SLIGHTLY_HIGH', DATEADD(MONTH, -1, @DefaultDate), @MaleProviderId, 'Patient fasted 8 hours prior', 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'Hemoglobin A1c', 'HEMATOLOGY', '7.2', '%', '<5.7', 'ACCEPTABLE', DATEADD(MONTH, -1, @DefaultDate), @MaleProviderId, 'Good diabetes control', 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'Total Cholesterol', 'LIPID_PANEL', '245', 'mg/dL', '<200', 'HIGH', DATEADD(MONTH, -1, @DefaultDate), @MaleProviderId, 'Requires monitoring', 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'HDL Cholesterol', 'LIPID_PANEL', '38', 'mg/dL', '>40', 'LOW', DATEADD(MONTH, -1, @DefaultDate), @MaleProviderId, 'Lifestyle modification recommended', 1, @DefaultDate, 'SYSTEM'),
	(@PatientId, 'LDL Cholesterol', 'LIPID_PANEL', '165', 'mg/dL', '<100', 'HIGH', DATEADD(MONTH, -1, @DefaultDate), @MaleProviderId, 'Consider statin therapy', 1, @DefaultDate, 'SYSTEM')

-- Step 13: Add Insurance
INSERT INTO HealthcareServices.PatientInsurance (PatientIdFK, InsuranceProviderIdFK, PolicyNumber, GroupNumber, EffectiveDate, ExpiryDate, CoveragePercentage, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, @InsuranceProviderId, 'POL-20240001', 'GRP-2024', @TestDate, DATEADD(YEAR, 1, @TestDate), 80, 1, @DefaultDate, 'SYSTEM')

-- Step 14: Add Invoice
INSERT INTO Billing.Invoices (PatientIdFK, InvoiceDate, DueDate, TotalAmount, InsuranceCoverageAmount, PatientResponsibilityAmount, Status, PaymentMethod, PaymentDate, Notes, IsActive, CreatedDate, CreatedBy)
VALUES	
	(@PatientId, DATEADD(MONTH, -1, @DefaultDate), DATEADD(DAY, 30, DATEADD(MONTH, -1, @DefaultDate)), 
	 2500.00, 2000.00, 500.00, 'PARTIAL_PAID', 'BANK_TRANSFER', DATEADD(MONTH, -1, @DefaultDate),
	 'Consultation and lab services. Insurance paid ZAR 2000.00, patient paid ZAR 500.00', 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Sample test data for patient John Anderson created successfully'
PRINT 'Patient ID: ' + CAST((SELECT MAX(PatientId) FROM Profile.Patient) AS VARCHAR)
GO
