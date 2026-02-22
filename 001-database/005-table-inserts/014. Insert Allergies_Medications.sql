USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert allergy and medication reference data
--	TFS Task:		Initialize allergy and medication reference tables
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE()

-- Insert Common Allergies
INSERT INTO Profile.Allergies (AllergyName, AllergyCategory, Severity, ReactionDescription, IsCritical, IsActive, CreatedDate, CreatedBy)
VALUES	
	('Penicillin', 'MEDICATION', 'HIGH', 'Anaphylaxis - severe respiratory distress', 1, 1, @DefaultDate, 'SYSTEM'),
	('Cephalosporin', 'MEDICATION', 'HIGH', 'Anaphylaxis - hives and throat swelling', 1, 1, @DefaultDate, 'SYSTEM'),
	('Aspirin', 'MEDICATION', 'MEDIUM', 'Rash and gastrointestinal upset', 0, 1, @DefaultDate, 'SYSTEM'),
	('NSAIDs', 'MEDICATION', 'MEDIUM', 'Gastric ulcers and bleeding', 0, 1, @DefaultDate, 'SYSTEM'),
	('Sulfonamides', 'MEDICATION', 'HIGH', 'Stevens-Johnson Syndrome risk', 1, 1, @DefaultDate, 'SYSTEM'),
	('Peanuts', 'FOOD', 'HIGH', 'Anaphylaxis - throat closing', 1, 1, @DefaultDate, 'SYSTEM'),
	('Tree Nuts', 'FOOD', 'HIGH', 'Anaphylaxis and airway obstruction', 1, 1, @DefaultDate, 'SYSTEM'),
	('Shellfish', 'FOOD', 'HIGH', 'Anaphylaxis - cardiovascular collapse risk', 1, 1, @DefaultDate, 'SYSTEM'),
	('Milk', 'FOOD', 'MEDIUM', 'Lactose intolerance and digestive issues', 0, 1, @DefaultDate, 'SYSTEM'),
	('Eggs', 'FOOD', 'MEDIUM', 'Urticaria and gastrointestinal symptoms', 0, 1, @DefaultDate, 'SYSTEM'),
	('Latex', 'ENVIRONMENTAL', 'HIGH', 'Anaphylaxis - respiratory compromise', 1, 1, @DefaultDate, 'SYSTEM'),
	('Iodine', 'MEDICATION', 'MEDIUM', 'Angioedema and rash', 0, 1, @DefaultDate, 'SYSTEM'),
	('Codeine', 'MEDICATION', 'MEDIUM', 'Respiratory depression and hypersensitivity', 0, 1, @DefaultDate, 'SYSTEM'),
	('ACE Inhibitors', 'MEDICATION', 'MEDIUM', 'Persistent cough and angioedema', 0, 1, @DefaultDate, 'SYSTEM'),
	('Statins', 'MEDICATION', 'LOW', 'Muscle pain and elevated liver enzymes', 0, 1, @DefaultDate, 'SYSTEM')

GO

-- Insert Common Medications
INSERT INTO Profile.Medications (MedicationName, MedicationGenericName, MedicationCategory, Strength, Unit, RouteOfAdministration, ManufacturerName, IsActive, CreatedDate, CreatedBy)
VALUES	
	('Amoxicillin', 'Amoxicillin', 'ANTIBIOTIC', '500', 'mg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Lisinopril', 'Lisinopril', 'ACE_INHIBITOR', '10', 'mg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Metformin', 'Metformin', 'ANTIDIABETIC', '500', 'mg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Atorvastatin', 'Atorvastatin', 'STATIN', '20', 'mg', 'ORAL', 'Pfizer', 1, @DefaultDate, 'SYSTEM'),
	('Omeprazole', 'Omeprazole', 'PROTON_PUMP_INHIBITOR', '20', 'mg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Sertraline', 'Sertraline', 'ANTIDEPRESSANT', '50', 'mg', 'ORAL', 'Pfizer', 1, @DefaultDate, 'SYSTEM'),
	('Ibuprofen', 'Ibuprofen', 'NSAID', '400', 'mg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Albuterol', 'Salbutamol', 'BRONCHODILATOR', '100', 'mcg', 'INHALED', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Insulin Glargine', 'Insulin Glargine', 'INSULIN', '100', 'IU/mL', 'SUBCUTANEOUS', 'Sanofi', 1, @DefaultDate, 'SYSTEM'),
	('Levothyroxine', 'Levothyroxine', 'THYROID_HORMONE', '50', 'mcg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Potassium Chloride', 'Potassium Chloride', 'ELECTROLYTE', '20', 'mEq', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Metoprolol', 'Metoprolol', 'BETA_BLOCKER', '50', 'mg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Warfarin', 'Warfarin', 'ANTICOAGULANT', '5', 'mg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Amlodipine', 'Amlodipine', 'CALCIUM_CHANNEL_BLOCKER', '5', 'mg', 'ORAL', 'Various Manufacturers', 1, @DefaultDate, 'SYSTEM'),
	('Clopidogrel', 'Clopidogrel', 'ANTIPLATELET', '75', 'mg', 'ORAL', 'Sanofi', 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Allergies and medications reference data inserted successfully'
GO
