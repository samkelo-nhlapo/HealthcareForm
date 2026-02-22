USE [HealthcareForm]
GO

/****** Object:  Trigger [Profile].[tr_AfterInsertPatient]    Script Date: 17-Aug-22 10:58:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- This Trigger is activated when a patient is added into the database

CREATE OR ALTER TRIGGER [Profile].[tr_AfterInsertPatient]
ON [Profile].[Patient]
AFTER INSERT 
AS
BEGIN

	--CHECK IF ANYTHING IS INSERTED 
	IF(ROWCOUNT_BIG() = 0)
		RETURN;

	SET NOCOUNT ON
	
	IF NOT EXISTS(SELECT 1 FROM inserted)
		RETURN;

	--SAVES DATA INSERTED AS JSON PATH XML
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
	SELECT GETDATE(), SYSTEM_USER, 'Inserted', SCHEMA_NAME(), 'Patient', S1.PatientId , D2.LogData
	FROM inserted S1
	CROSS APPLY
	(
		SELECT LogData = (SELECT * FROM inserted WHERE inserted.PatientId = S1.PatientId FOR Json Path, without_Array_wrapper)
	)AS D2

	SET NOCOUNT OFF
END
GO


