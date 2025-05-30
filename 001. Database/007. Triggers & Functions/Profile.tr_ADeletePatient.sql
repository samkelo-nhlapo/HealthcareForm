USE HealthcareForm
GO

-- This Trigger is triggered when a patient data is being deleted 

CREATE OR ALTER TRIGGER Profile.tr_ADeletePatient
ON Profile.Patient
AFTER DELETE
AS
BEGIN
	--CHECKS IF NOTHING IS DELETED
	IF(ROWCOUNT_BIG() = 0)
		RETURN;
	
	SET NOCOUNT ON
		
		IF NOT EXISTS(SELECT 1 FROM deleted)
		RETURN

	--SAVES DATA DELETED AS JSON PATH XML
	INSERT INTO Auth.AuditLog
	(
		ModifiedTime, 
		ModifiedBy, 
		Operation, 
		SchemaName, 
		TableName, 
		TableID, 
		LogData
	)
	SELECT GETDATE(), SYSTEM_USER, 'Deleted', SCHEMA_NAME(), 'Patient', D1.PatientId , D2.LogData
	FROM deleted D1
	CROSS APPLY
	(
		SELECT LogData = (SELECT * FROM deleted WHERE deleted.PatientId = D1.PatientId FOR Json Path, without_Array_wrapper)
	)AS D2

END