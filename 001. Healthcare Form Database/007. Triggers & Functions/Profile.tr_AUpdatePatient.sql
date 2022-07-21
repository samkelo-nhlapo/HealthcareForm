USE PatientEnrollment
GO
CREATE OR ALTER TRIGGER Profile.tr_AUpdatePatient
ON Profile.Patient
AFTER UPDATE 
AS
BEGIN

	--CHECK IF THERES CHANGE IN THE DATA
	IF(ROWCOUNT_BIG() = 0)
		RETURN;

	SET NOCOUNT ON
		
		IF NOT EXISTS(SELECT * FROM deleted EXCEPT SELECT * FROM inserted)
		RETURN

	--INSERTING INTO TEMP TABLE 
	SELECT * INTO #ModifiedData 
	FROM 
	(
		SELECT * FROM deleted EXCEPT SELECT * FROM inserted
	) ModifiedData
	
	

	--INSERTING INTO A AUDIT AND JSON XML
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
	SELECT GETDATE(), SYSTEM_USER, 'Update', 'Profile' , 'Patient', M1.GenderIDFK, M2.OldValues 
	FROM #ModifiedData AS M1
	CROSS APPLY
	(
		SELECT OldValues = (SELECT * FROM #ModifiedData WHERE #ModifiedData.GenderIDFK = M1.GenderIDFK FOR JSON PATH, WITHOUT_ARRAY_WRAPPER ) 
	) M2
END