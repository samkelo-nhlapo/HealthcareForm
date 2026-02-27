USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Profile.BillingCodes (BillingCodeId, CodeType, Code, Description, Category, Cost, EffectiveDate, IsActive, CreatedDate, CreatedBy)
SELECT
    NEWID(),
    V.CodeType,
    V.Code,
    V.Description,
    V.Category,
    V.Cost,
    @DefaultDate,
    1,
    @DefaultDate,
    'SYSTEM'
FROM (
    VALUES
        ('ICD-10', 'E10.9', 'Type 1 diabetes mellitus without complications', 'ENDOCRINE', 0.00),
        ('ICD-10', 'E11.9', 'Type 2 diabetes mellitus without complications', 'ENDOCRINE', 0.00),
        ('ICD-10', 'E78.5', 'Hyperlipidemia, unspecified', 'METABOLIC', 0.00),
        ('ICD-10', 'I10', 'Essential (primary) hypertension', 'CARDIOVASCULAR', 0.00),
        ('ICD-10', 'I21.9', 'ST elevation (STEMI) and non-ST elevation (NSTEMI) of unspecified site', 'CARDIOVASCULAR', 0.00),
        ('ICD-10', 'I50.9', 'Heart failure, unspecified', 'CARDIOVASCULAR', 0.00),
        ('ICD-10', 'J45.901', 'Unspecified asthma with (acute) exacerbation', 'RESPIRATORY', 0.00),
        ('ICD-10', 'J06.9', 'Acute upper respiratory infection, unspecified', 'RESPIRATORY', 0.00),
        ('ICD-10', 'J44.9', 'Chronic obstructive pulmonary disease, unspecified', 'RESPIRATORY', 0.00),
        ('ICD-10', 'F41.1', 'Generalized anxiety disorder', 'PSYCHIATRIC', 0.00),
        ('ICD-10', 'F32.9', 'Major depressive disorder, single episode, unspecified', 'PSYCHIATRIC', 0.00),
        ('ICD-10', 'F33.9', 'Major depressive disorder, recurrent, unspecified', 'PSYCHIATRIC', 0.00),
        ('ICD-10', 'K21.9', 'Unspecified gastro-esophageal reflux disease', 'GASTROINTESTINAL', 0.00),
        ('ICD-10', 'K29.7', 'Gastritis, unspecified', 'GASTROINTESTINAL', 0.00),
        ('ICD-10', 'K80.9', 'Unspecified cholelithiasis', 'GASTROINTESTINAL', 0.00),
        ('ICD-10', 'M79.3', 'Panniculitis, unspecified', 'MUSCULOSKELETAL', 0.00),
        ('ICD-10', 'M15.9', 'Unspecified osteoarthritis', 'MUSCULOSKELETAL', 0.00),
        ('ICD-10', 'M17.11', 'Primary osteoarthritis, right knee', 'MUSCULOSKELETAL', 0.00),
        ('ICD-10', 'M54.5', 'Low back pain', 'MUSCULOSKELETAL', 0.00),
        ('ICD-10', 'N39.0', 'Urinary tract infection, site not specified', 'GENITOURINARY', 0.00),
        ('CPT', '99213', 'Office visit for established patient - low complexity', 'CONSULTATION', 0.00),
        ('CPT', '99214', 'Office visit for established patient - moderate complexity', 'CONSULTATION', 0.00),
        ('CPT', '99215', 'Office visit for established patient - high complexity', 'CONSULTATION', 0.00),
        ('CPT', '99232', 'Inpatient hospital visit - established patient - low complexity', 'INPATIENT', 0.00),
        ('CPT', '93000', 'Electrocardiogram - complete', 'DIAGNOSTIC', 0.00),
        ('CPT', '70450', 'Computed tomography, head or brain - without contrast', 'DIAGNOSTIC', 0.00),
        ('CPT', '71020', 'Chest X-ray - 2 views', 'DIAGNOSTIC', 0.00),
        ('CPT', '80053', 'Comprehensive metabolic panel', 'LABORATORY', 0.00),
        ('CPT', '85025', 'Complete blood count - automated', 'LABORATORY', 0.00),
        ('CPT', '80061', 'Lipid panel', 'LABORATORY', 0.00),
        ('CPT', '92004', 'Comprehensive eye exam - new patient', 'SPECIALTY', 0.00),
        ('CPT', '29881', 'Arthroscopy, knee - diagnostic', 'SURGICAL', 0.00),
        ('CPT', '49505', 'Repair initial inguinal hernia', 'SURGICAL', 0.00),
        ('CPT', '47562', 'Laparoscopic cholecystectomy', 'SURGICAL', 0.00),
        ('HCPCS', 'J1100', 'Injection, dexamethasone sodium phosphate - 4mg', 'INJECTION', 0.00),
        ('HCPCS', 'J1110', 'Injection, dihydroergotamine mesylate - per 1mg', 'INJECTION', 0.00),
        ('HCPCS', 'J3301', 'Triamcinolone acetonide, preservative-free', 'INJECTION', 0.00),
        ('HCPCS', 'E0781', 'Ambulatory infusion pump - stationary or single speed', 'EQUIPMENT', 0.00),
        ('HCPCS', 'E1390', 'Oxygen concentrator, portable - rental', 'EQUIPMENT', 0.00)
) V(CodeType, Code, Description, Category, Cost)
WHERE NOT EXISTS
(
    SELECT 1
    FROM Profile.BillingCodes BC
    WHERE BC.Code = V.Code
);
GO

PRINT 'Billing codes inserted successfully'
GO
