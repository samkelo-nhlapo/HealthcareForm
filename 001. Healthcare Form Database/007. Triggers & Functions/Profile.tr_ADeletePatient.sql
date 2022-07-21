USE PatientEnrollment
GO
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
	--FIX GENDERID TO TABLE ID --ISSUE = TABLE ID IS GUID AND deleted ID IS INT THAT CLASH
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
	SELECT GETDATE(), SYSTEM_USER, 'Deleted', SCHEMA_NAME(), 'Patient', D1.GenderIDFK , D2.LogData
	FROM deleted D1
	CROSS APPLY
	(
		SELECT LogData = (SELECT * FROM deleted WHERE deleted.GenderIDFK = D1.GenderIDFK FOR Json Path, without_Array_wrapper)
	)AS D2

END