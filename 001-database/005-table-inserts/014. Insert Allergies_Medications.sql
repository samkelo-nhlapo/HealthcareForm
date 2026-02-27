USE HealthcareForm
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Lookup')
BEGIN
    EXEC('CREATE SCHEMA Lookup');
END
GO

IF OBJECT_ID('Lookup.Allergies', 'U') IS NULL
BEGIN
    CREATE TABLE Lookup.Allergies
    (
        AllergyId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        AllergyName VARCHAR(250) NOT NULL,
        AllergyCategory VARCHAR(50) NOT NULL,
        Severity VARCHAR(50) NOT NULL,
        ReactionDescription VARCHAR(MAX) NULL,
        IsCritical BIT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedBy VARCHAR(250) NULL,
        PRIMARY KEY (AllergyId)
    );
END
GO

IF OBJECT_ID('Lookup.Medications', 'U') IS NULL
BEGIN
    CREATE TABLE Lookup.Medications
    (
        MedicationId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        MedicationName VARCHAR(250) NOT NULL,
        MedicationGenericName VARCHAR(250) NULL,
        MedicationCategory VARCHAR(100) NULL,
        Strength VARCHAR(50) NULL,
        Unit VARCHAR(50) NULL,
        RouteOfAdministration VARCHAR(50) NULL,
        ManufacturerName VARCHAR(250) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedBy VARCHAR(250) NULL,
        PRIMARY KEY (MedicationId)
    );
END
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Lookup.Allergies (AllergyName, AllergyCategory, Severity, ReactionDescription, IsCritical, IsActive, CreatedDate, CreatedBy)
SELECT V.AllergyName, V.AllergyCategory, V.Severity, V.ReactionDescription, V.IsCritical, 1, @DefaultDate, 'SYSTEM'
FROM (
    VALUES
        ('Penicillin', 'MEDICATION', 'HIGH', 'Anaphylaxis - severe respiratory distress', 1),
        ('Cephalosporin', 'MEDICATION', 'HIGH', 'Anaphylaxis - hives and throat swelling', 1),
        ('Aspirin', 'MEDICATION', 'MEDIUM', 'Rash and gastrointestinal upset', 0),
        ('NSAIDs', 'MEDICATION', 'MEDIUM', 'Gastric ulcers and bleeding', 0),
        ('Sulfonamides', 'MEDICATION', 'HIGH', 'Stevens-Johnson Syndrome risk', 1),
        ('Peanuts', 'FOOD', 'HIGH', 'Anaphylaxis - throat closing', 1),
        ('Tree Nuts', 'FOOD', 'HIGH', 'Anaphylaxis and airway obstruction', 1),
        ('Shellfish', 'FOOD', 'HIGH', 'Anaphylaxis - cardiovascular collapse risk', 1),
        ('Milk', 'FOOD', 'MEDIUM', 'Lactose intolerance and digestive issues', 0),
        ('Eggs', 'FOOD', 'MEDIUM', 'Urticaria and gastrointestinal symptoms', 0),
        ('Latex', 'ENVIRONMENTAL', 'HIGH', 'Anaphylaxis - respiratory compromise', 1),
        ('Iodine', 'MEDICATION', 'MEDIUM', 'Angioedema and rash', 0),
        ('Codeine', 'MEDICATION', 'MEDIUM', 'Respiratory depression and hypersensitivity', 0),
        ('ACE Inhibitors', 'MEDICATION', 'MEDIUM', 'Persistent cough and angioedema', 0),
        ('Statins', 'MEDICATION', 'LOW', 'Muscle pain and elevated liver enzymes', 0)
) V(AllergyName, AllergyCategory, Severity, ReactionDescription, IsCritical)
WHERE NOT EXISTS (SELECT 1 FROM Lookup.Allergies A WHERE A.AllergyName = V.AllergyName);
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Lookup.Medications (MedicationName, MedicationGenericName, MedicationCategory, Strength, Unit, RouteOfAdministration, ManufacturerName, IsActive, CreatedDate, CreatedBy)
SELECT V.MedicationName, V.MedicationGenericName, V.MedicationCategory, V.Strength, V.Unit, V.RouteOfAdministration, V.ManufacturerName, 1, @DefaultDate, 'SYSTEM'
FROM (
    VALUES
        ('Amoxicillin', 'Amoxicillin', 'ANTIBIOTIC', '500', 'mg', 'ORAL', 'Various Manufacturers'),
        ('Lisinopril', 'Lisinopril', 'ACE_INHIBITOR', '10', 'mg', 'ORAL', 'Various Manufacturers'),
        ('Metformin', 'Metformin', 'ANTIDIABETIC', '500', 'mg', 'ORAL', 'Various Manufacturers'),
        ('Atorvastatin', 'Atorvastatin', 'STATIN', '20', 'mg', 'ORAL', 'Pfizer'),
        ('Omeprazole', 'Omeprazole', 'PROTON_PUMP_INHIBITOR', '20', 'mg', 'ORAL', 'Various Manufacturers'),
        ('Sertraline', 'Sertraline', 'ANTIDEPRESSANT', '50', 'mg', 'ORAL', 'Pfizer'),
        ('Ibuprofen', 'Ibuprofen', 'NSAID', '400', 'mg', 'ORAL', 'Various Manufacturers'),
        ('Albuterol', 'Salbutamol', 'BRONCHODILATOR', '100', 'mcg', 'INHALED', 'Various Manufacturers'),
        ('Insulin Glargine', 'Insulin Glargine', 'INSULIN', '100', 'IU/mL', 'SUBCUTANEOUS', 'Sanofi'),
        ('Levothyroxine', 'Levothyroxine', 'THYROID_HORMONE', '50', 'mcg', 'ORAL', 'Various Manufacturers'),
        ('Potassium Chloride', 'Potassium Chloride', 'ELECTROLYTE', '20', 'mEq', 'ORAL', 'Various Manufacturers'),
        ('Metoprolol', 'Metoprolol', 'BETA_BLOCKER', '50', 'mg', 'ORAL', 'Various Manufacturers'),
        ('Warfarin', 'Warfarin', 'ANTICOAGULANT', '5', 'mg', 'ORAL', 'Various Manufacturers'),
        ('Amlodipine', 'Amlodipine', 'CALCIUM_CHANNEL_BLOCKER', '5', 'mg', 'ORAL', 'Various Manufacturers'),
        ('Clopidogrel', 'Clopidogrel', 'ANTIPLATELET', '75', 'mg', 'ORAL', 'Sanofi')
) V(MedicationName, MedicationGenericName, MedicationCategory, Strength, Unit, RouteOfAdministration, ManufacturerName)
WHERE NOT EXISTS (SELECT 1 FROM Lookup.Medications M WHERE M.MedicationName = V.MedicationName);
GO

PRINT 'Lookup allergies and medications inserted/verified successfully';
GO
