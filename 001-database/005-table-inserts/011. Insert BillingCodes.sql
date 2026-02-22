USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert billing codes (ICD-10 diagnosis codes and CPT procedure codes)
--	TFS Task:		Initialize billing codes reference data
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE()

-- ICD-10 Diagnosis Codes
INSERT INTO Billing.BillingCodes (CodeType, CodeValue, CodeDescription, CategoryCode, EffectiveDate, IsActive, CreatedDate, CreatedBy)
VALUES	
	-- ICD-10 Common Diagnoses
	('ICD-10', 'E10.9', 'Type 1 diabetes mellitus without complications', 'ENDOCRINE', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'E11.9', 'Type 2 diabetes mellitus without complications', 'ENDOCRINE', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'E78.5', 'Hyperlipidemia, unspecified', 'METABOLIC', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'I10', 'Essential (primary) hypertension', 'CARDIOVASCULAR', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'I21.9', 'ST elevation (STEMI) and non-ST elevation (NSTEMI) of unspecified site', 'CARDIOVASCULAR', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'I50.9', 'Heart failure, unspecified', 'CARDIOVASCULAR', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'J45.901', 'Unspecified asthma with (acute) exacerbation', 'RESPIRATORY', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'J06.9', 'Acute upper respiratory infection, unspecified', 'RESPIRATORY', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'J44.9', 'Chronic obstructive pulmonary disease, unspecified', 'RESPIRATORY', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'F41.1', 'Generalized anxiety disorder', 'PSYCHIATRIC', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'F32.9', 'Major depressive disorder, single episode, unspecified', 'PSYCHIATRIC', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'F33.9', 'Major depressive disorder, recurrent, unspecified', 'PSYCHIATRIC', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'K21.9', 'Unspecified gastro-esophageal reflux disease', 'GASTROINTESTINAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'K29.7', 'Gastritis, unspecified', 'GASTROINTESTINAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'K80.9', 'Unspecified cholelithiasis', 'GASTROINTESTINAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'M79.3', 'Panniculitis, unspecified', 'MUSCULOSKELETAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'M15.9', 'Unspecified osteoarthritis', 'MUSCULOSKELETAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'M17.11', 'Primary osteoarthritis, right knee', 'MUSCULOSKELETAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'M54.5', 'Low back pain', 'MUSCULOSKELETAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('ICD-10', 'N39.0', 'Urinary tract infection, site not specified', 'GENITOURINARY', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	
	-- CPT Procedure Codes
	('CPT', '99213', 'Office visit for established patient - low complexity', 'CONSULTATION', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '99214', 'Office visit for established patient - moderate complexity', 'CONSULTATION', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '99215', 'Office visit for established patient - high complexity', 'CONSULTATION', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '99232', 'Inpatient hospital visit - established patient - low complexity', 'INPATIENT', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '93000', 'Electrocardiogram - complete', 'DIAGNOSTIC', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '70450', 'Computed tomography, head or brain - without contrast', 'DIAGNOSTIC', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '71020', 'Chest X-ray - 2 views', 'DIAGNOSTIC', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '80053', 'Comprehensive metabolic panel', 'LABORATORY', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '85025', 'Complete blood count - automated', 'LABORATORY', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '80061', 'Lipid panel', 'LABORATORY', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '92004', 'Comprehensive eye exam - new patient', 'SPECIALTY', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '29881', 'Arthroscopy, knee - diagnostic', 'SURGICAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '49505', 'Repair initial inguinal hernia', 'SURGICAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('CPT', '47562', 'Laparoscopic cholecystectomy', 'SURGICAL', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	
	-- HCPCS Service Codes
	('HCPCS', 'J1100', 'Injection, dexamethasone sodium phosphate - 4mg', 'INJECTION', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('HCPCS', 'J1110', 'Injection, dihydroergotamine mesylate - per 1mg', 'INJECTION', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('HCPCS', 'J3301', 'Triamcinolone acetonide, preservative-free', 'INJECTION', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('HCPCS', 'E0781', 'Ambulatory infusion pump - stationary or single speed', 'EQUIPMENT', @DefaultDate, 1, @DefaultDate, 'SYSTEM'),
	('HCPCS', 'E1390', 'Oxygen concentrator, portable - rental', 'EQUIPMENT', @DefaultDate, 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Billing codes inserted successfully'
GO
