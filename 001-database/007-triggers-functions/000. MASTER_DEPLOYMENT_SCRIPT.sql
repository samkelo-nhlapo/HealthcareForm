-- ================================================================================================
-- HealthcareForm - Master Trigger/Function Deployment
-- Deploys helper functions and triggers in dependency order.
-- Safe to re-run: all objects use CREATE OR ALTER.
-- ================================================================================================
USE HealthcareForm
GO

SET NOCOUNT ON;

PRINT '================================================================================================';
PRINT 'HealthcareForm - Trigger/Function Deployment';
PRINT 'Started: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO

IF OBJECT_ID(N'[Contacts].[Emails]', N'U') IS NULL
    THROW 50010, 'Missing table [Contacts].[Emails]. Run DDL deployment first.', 1;
IF OBJECT_ID(N'[Contacts].[Phones]', N'U') IS NULL
    THROW 50010, 'Missing table [Contacts].[Phones]. Run DDL deployment first.', 1;
IF OBJECT_ID(N'[Contacts].[PatientEmails]', N'U') IS NULL
    THROW 50010, 'Missing table [Contacts].[PatientEmails]. Run DDL deployment first.', 1;
IF OBJECT_ID(N'[Contacts].[PatientPhones]', N'U') IS NULL
    THROW 50010, 'Missing table [Contacts].[PatientPhones]. Run DDL deployment first.', 1;
IF OBJECT_ID(N'[Profile].[Patient]', N'U') IS NULL
    THROW 50010, 'Missing table [Profile].[Patient]. Run DDL deployment first.', 1;
IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NULL
    THROW 50010, 'Missing table [Profile].[Appointments]. Run DDL deployment first.', 1;
IF OBJECT_ID(N'[Auth].[AuditLog]', N'U') IS NULL
    THROW 50010, 'Missing table [Auth].[AuditLog]. Run DDL deployment first.', 1;
GO

-- BEGIN FILE: 007-triggers-functions/Capitalize first letter.sql
USE HealthcareForm
GO

CREATE OR ALTER FUNCTION [dbo].[CapitalizeFirstLetter]
(
    @InputString VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @InputString IS NULL
        RETURN NULL;

    DECLARE @Index INT,
            @Char CHAR(1),
            @PrevChar CHAR(1),
            @OutputString VARCHAR(MAX);

    SET @OutputString = LOWER(@InputString);
    SET @Index = 1;

    WHILE @Index <= LEN(@InputString)
    BEGIN
        SET @Char = SUBSTRING(@InputString, @Index, 1);
        SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                             ELSE SUBSTRING(@InputString, @Index - 1, 1)
                        END;

        IF @PrevChar IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
        BEGIN
            IF @PrevChar <> ''''
                SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char));
        END

        SET @Index = @Index + 1;
    END

    RETURN @OutputString;
END
GO
-- END FILE: 007-triggers-functions/Capitalize first letter.sql


-- BEGIN FILE: 007-triggers-functions/Capitalize first letter body.sql
USE HealthcareForm
GO

CREATE OR ALTER FUNCTION [dbo].[CapitalizeFirstLetterBody]
(
    @InputString VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @InputString IS NULL
        RETURN NULL;

    DECLARE @Index INT,
            @Char CHAR(1),
            @PrevChar CHAR(1),
            @OutputString VARCHAR(MAX);

    SET @OutputString = LOWER(@InputString);
    SET @Index = 1;

    WHILE @Index <= LEN(@InputString)
    BEGIN
        SET @Char = SUBSTRING(@InputString, @Index, 1);
        SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                             ELSE SUBSTRING(@InputString, @Index - 1, 1)
                        END;

        IF @PrevChar IN (';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
        BEGIN
            IF @PrevChar <> ''''
                SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char));
        END

        SET @Index = @Index + 1;
    END

    RETURN @OutputString;
END
GO
-- END FILE: 007-triggers-functions/Capitalize first letter body.sql


-- BEGIN FILE: 007-triggers-functions/Format Phone Contact.sql
USE HealthcareForm
GO

CREATE OR ALTER FUNCTION [Contacts].[FormatPhoneNumber]
(
    @PhoneNumber VARCHAR(25)
)
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @Normalized VARCHAR(25);

    IF @PhoneNumber IS NULL
        RETURN NULL;

    SET @Normalized = LTRIM(RTRIM(@PhoneNumber));
    SET @Normalized = REPLACE(@Normalized, '-', '');
    SET @Normalized = REPLACE(@Normalized, ' ', '');
    SET @Normalized = REPLACE(@Normalized, '+', '');
    SET @Normalized = REPLACE(@Normalized, '(', '');
    SET @Normalized = REPLACE(@Normalized, ')', '');

    IF LEN(@Normalized) <> 10 OR @Normalized LIKE '%[^0-9]%'
        RETURN NULL;

    RETURN SUBSTRING(@Normalized, 1, 3) + '-' +
           SUBSTRING(@Normalized, 4, 3) + '-' +
           SUBSTRING(@Normalized, 7, 4);
END
GO
-- END FILE: 007-triggers-functions/Format Phone Contact.sql


-- BEGIN FILE: 007-triggers-functions/Contacts.tr_NormalizeAndValidateEmail.sql
USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_NormalizeAndValidateEmail]
ON [Contacts].[Emails]
AFTER INSERT, UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    DECLARE @Normalized TABLE
    (
        EmailId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        NormalizedEmail VARCHAR(250) NOT NULL
    );

    INSERT INTO @Normalized (EmailId, NormalizedEmail)
    SELECT
        I.EmailId,
        LTRIM(RTRIM(LOWER(I.Email)))
    FROM inserted I;

    IF EXISTS
    (
        SELECT 1
        FROM @Normalized N
        WHERE N.NormalizedEmail = ''
           OR N.NormalizedEmail LIKE '% %'
           OR N.NormalizedEmail NOT LIKE '%_@_%._%'
    )
    BEGIN
        RAISERROR('Invalid email address format.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE E
    SET
        E.Email = N.NormalizedEmail,
        E.UpdateDate = GETDATE(),
        E.UpdatedBy = SYSTEM_USER
    FROM Contacts.Emails E
    INNER JOIN @Normalized N ON N.EmailId = E.EmailId
    WHERE ISNULL(E.Email, '') <> ISNULL(N.NormalizedEmail, '');
END
GO
-- END FILE: 007-triggers-functions/Contacts.tr_NormalizeAndValidateEmail.sql


-- BEGIN FILE: 007-triggers-functions/Contacts.tr_NormalizeAndValidatePhoneNumber.sql
USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_NormalizeAndValidatePhoneNumber]
ON [Contacts].[Phones]
AFTER INSERT, UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    DECLARE @Normalized TABLE
    (
        PhoneId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        FormattedPhone VARCHAR(12) NULL
    );

    INSERT INTO @Normalized (PhoneId, FormattedPhone)
    SELECT
        I.PhoneId,
        [Contacts].[FormatPhoneNumber](I.PhoneNumber)
    FROM inserted I;

    IF EXISTS
    (
        SELECT 1
        FROM @Normalized N
        WHERE N.FormattedPhone IS NULL
    )
    BEGIN
        RAISERROR('Invalid phone number format. Use a 10-digit phone number.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE P
    SET
        P.PhoneNumber = N.FormattedPhone,
        P.UpdateDate = GETDATE(),
        P.UpdatedBy = SYSTEM_USER
    FROM Contacts.Phones P
    INNER JOIN @Normalized N ON N.PhoneId = P.PhoneId
    WHERE ISNULL(P.PhoneNumber, '') <> ISNULL(N.FormattedPhone, '');
END
GO
-- END FILE: 007-triggers-functions/Contacts.tr_NormalizeAndValidatePhoneNumber.sql


-- BEGIN FILE: 007-triggers-functions/Contacts.tr_EnforceSinglePrimaryPatientEmail.sql
USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_EnforceSinglePrimaryPatientEmail]
ON [Contacts].[PatientEmails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    ;WITH AffectedPatients AS
    (
        SELECT DISTINCT PatientIdFK FROM inserted
        UNION
        SELECT DISTINCT PatientIdFK FROM deleted
    ),
    PrimaryRows AS
    (
        SELECT
            PE.PatientEmailId,
            PE.PatientIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PE.PatientIdFK
                ORDER BY
                    CASE WHEN PE.IsPrimary = 1 THEN 0 ELSE 1 END,
                    ISNULL(PE.UpdatedDate, PE.CreatedDate) DESC,
                    PE.PatientEmailId DESC
            ) AS RN,
            SUM(CASE WHEN PE.IsPrimary = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY PE.PatientIdFK) AS PrimaryCount
        FROM Contacts.PatientEmails PE
        INNER JOIN AffectedPatients AP ON AP.PatientIdFK = PE.PatientIdFK
    )
    UPDATE PE
    SET
        IsPrimary = CASE WHEN PR.RN = 1 THEN 1 ELSE 0 END,
        UpdatedDate = GETDATE(),
        UpdatedBy = SYSTEM_USER
    FROM Contacts.PatientEmails PE
    INNER JOIN PrimaryRows PR ON PR.PatientEmailId = PE.PatientEmailId
    WHERE
        (PR.PrimaryCount = 0 OR PR.PrimaryCount > 1)
        OR (PR.RN = 1 AND PE.IsPrimary = 0)
        OR (PR.RN > 1 AND PE.IsPrimary = 1);
END
GO
-- END FILE: 007-triggers-functions/Contacts.tr_EnforceSinglePrimaryPatientEmail.sql


-- BEGIN FILE: 007-triggers-functions/Contacts.tr_EnforceSinglePrimaryPatientPhone.sql
USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Contacts].[tr_EnforceSinglePrimaryPatientPhone]
ON [Contacts].[PatientPhones]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    SET NOCOUNT ON;

    ;WITH AffectedPatients AS
    (
        SELECT DISTINCT PatientIdFK FROM inserted
        UNION
        SELECT DISTINCT PatientIdFK FROM deleted
    ),
    PrimaryRows AS
    (
        SELECT
            PP.PatientPhoneId,
            PP.PatientIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PP.PatientIdFK
                ORDER BY
                    CASE WHEN PP.IsPrimary = 1 THEN 0 ELSE 1 END,
                    ISNULL(PP.UpdatedDate, PP.CreatedDate) DESC,
                    PP.PatientPhoneId DESC
            ) AS RN,
            SUM(CASE WHEN PP.IsPrimary = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY PP.PatientIdFK) AS PrimaryCount
        FROM Contacts.PatientPhones PP
        INNER JOIN AffectedPatients AP ON AP.PatientIdFK = PP.PatientIdFK
    )
    UPDATE PP
    SET
        IsPrimary = CASE WHEN PR.RN = 1 THEN 1 ELSE 0 END,
        UpdatedDate = GETDATE(),
        UpdatedBy = SYSTEM_USER
    FROM Contacts.PatientPhones PP
    INNER JOIN PrimaryRows PR ON PR.PatientPhoneId = PP.PatientPhoneId
    WHERE
        (PR.PrimaryCount = 0 OR PR.PrimaryCount > 1)
        OR (PR.RN = 1 AND PP.IsPrimary = 0)
        OR (PR.RN > 1 AND PP.IsPrimary = 1);
END
GO
-- END FILE: 007-triggers-functions/Contacts.tr_EnforceSinglePrimaryPatientPhone.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_AfterInsertPatient.sql
USE [HealthcareForm]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER TRIGGER [Profile].[tr_AfterInsertPatient]
ON [Profile].[Patient]
AFTER INSERT
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

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
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'Inserted',
        'Profile',
        'Patient',
        I.PatientId,
        J.LogData
    FROM inserted I
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                I.PatientId,
                I.FirstName,
                I.LastName,
                I.ID_Number,
                I.DateOfBirth,
                I.GenderIDFK,
                I.MedicationList,
                I.AddressIDFK,
                I.MaritalStatusIDFK,
                I.EmergencyIDFK,
                I.IsDeleted,
                I.CreatedDate,
                I.CreatedBy,
                I.UpdatedDate,
                I.UpdatedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_AfterInsertPatient.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_AUpdatePatient.sql
USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Profile].[tr_AUpdatePatient]
ON [Profile].[Patient]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    ;WITH ChangedRows AS
    (
        SELECT I.*, D.PatientId AS DPatientId,
               D.FirstName AS DFirstName,
               D.LastName AS DLastName,
               D.ID_Number AS DID_Number,
               D.DateOfBirth AS DDateOfBirth,
               D.GenderIDFK AS DGenderIDFK,
               D.MedicationList AS DMedicationList,
               D.AddressIDFK AS DAddressIDFK,
               D.MaritalStatusIDFK AS DMaritalStatusIDFK,
               D.EmergencyIDFK AS DEmergencyIDFK,
               D.IsDeleted AS DIsDeleted,
               D.CreatedDate AS DCreatedDate,
               D.CreatedBy AS DCreatedBy,
               D.UpdatedDate AS DUpdatedDate,
               D.UpdatedBy AS DUpdatedBy
        FROM inserted I
        INNER JOIN deleted D ON D.PatientId = I.PatientId
        WHERE
            ISNULL(D.FirstName, '') <> ISNULL(I.FirstName, '') OR
            ISNULL(D.LastName, '') <> ISNULL(I.LastName, '') OR
            ISNULL(D.ID_Number, '') <> ISNULL(I.ID_Number, '') OR
            ISNULL(CONVERT(VARCHAR(30), D.DateOfBirth, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.DateOfBirth, 126), '') OR
            ISNULL(D.GenderIDFK, -1) <> ISNULL(I.GenderIDFK, -1) OR
            ISNULL(D.MedicationList, '') <> ISNULL(I.MedicationList, '') OR
            ISNULL(CONVERT(VARCHAR(36), D.AddressIDFK), '') <> ISNULL(CONVERT(VARCHAR(36), I.AddressIDFK), '') OR
            ISNULL(D.MaritalStatusIDFK, -1) <> ISNULL(I.MaritalStatusIDFK, -1) OR
            ISNULL(CONVERT(VARCHAR(36), D.EmergencyIDFK), '') <> ISNULL(CONVERT(VARCHAR(36), I.EmergencyIDFK), '') OR
            ISNULL(D.IsDeleted, 0) <> ISNULL(I.IsDeleted, 0) OR
            ISNULL(CONVERT(VARCHAR(30), D.CreatedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.CreatedDate, 126), '') OR
            ISNULL(D.CreatedBy, '') <> ISNULL(I.CreatedBy, '') OR
            ISNULL(CONVERT(VARCHAR(30), D.UpdatedDate, 126), '') <> ISNULL(CONVERT(VARCHAR(30), I.UpdatedDate, 126), '') OR
            ISNULL(D.UpdatedBy, '') <> ISNULL(I.UpdatedBy, '')
    )
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
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'Updated',
        'Profile',
        'Patient',
        C.PatientId,
        J.LogData
    FROM ChangedRows C
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                [Old] =
                (
                    SELECT
                        C.DPatientId AS PatientId,
                        C.DFirstName AS FirstName,
                        C.DLastName AS LastName,
                        C.DID_Number AS ID_Number,
                        C.DDateOfBirth AS DateOfBirth,
                        C.DGenderIDFK AS GenderIDFK,
                        C.DMedicationList AS MedicationList,
                        C.DAddressIDFK AS AddressIDFK,
                        C.DMaritalStatusIDFK AS MaritalStatusIDFK,
                        C.DEmergencyIDFK AS EmergencyIDFK,
                        C.DIsDeleted AS IsDeleted,
                        C.DCreatedDate AS CreatedDate,
                        C.DCreatedBy AS CreatedBy,
                        C.DUpdatedDate AS UpdatedDate,
                        C.DUpdatedBy AS UpdatedBy
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                [New] =
                (
                    SELECT
                        C.PatientId,
                        C.FirstName,
                        C.LastName,
                        C.ID_Number,
                        C.DateOfBirth,
                        C.GenderIDFK,
                        C.MedicationList,
                        C.AddressIDFK,
                        C.MaritalStatusIDFK,
                        C.EmergencyIDFK,
                        C.IsDeleted,
                        C.CreatedDate,
                        C.CreatedBy,
                        C.UpdatedDate,
                        C.UpdatedBy
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                )
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_AUpdatePatient.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_ADeletePatient.sql
USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Profile].[tr_ADeletePatient]
ON [Profile].[Patient]
INSTEAD OF DELETE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

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
    SELECT
        GETDATE(),
        SYSTEM_USER,
        'DeleteBlocked',
        'Profile',
        'Patient',
        D.PatientId,
        J.LogData
    FROM deleted D
    CROSS APPLY
    (
        SELECT LogData =
        (
            SELECT
                D.PatientId,
                D.FirstName,
                D.LastName,
                D.ID_Number,
                D.DateOfBirth,
                D.GenderIDFK,
                D.MedicationList,
                D.AddressIDFK,
                D.MaritalStatusIDFK,
                D.EmergencyIDFK,
                D.IsDeleted,
                D.CreatedDate,
                D.CreatedBy,
                D.UpdatedDate,
                D.UpdatedBy
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    ) J;

    RAISERROR('Hard delete is not allowed on Profile.Patient. Use soft delete (IsDeleted = 1).', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_ADeletePatient.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_BlockPatientIDNumberUpdate.sql
USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Profile].[tr_BlockPatientIDNumberUpdate]
ON [Profile].[Patient]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.PatientId = I.PatientId
        WHERE ISNULL(I.ID_Number, '') <> ISNULL(D.ID_Number, '')
    )
    BEGIN
        RAISERROR('Updating Profile.Patient.ID_Number is not allowed.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_BlockPatientIDNumberUpdate.sql


-- BEGIN FILE: 007-triggers-functions/Profile.tr_ValidateAppointmentStatusTransition.sql
USE HealthcareForm
GO

CREATE OR ALTER TRIGGER [Profile].[tr_ValidateAppointmentStatusTransition]
ON [Profile].[Appointments]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    -- Prevent invalid status values.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        WHERE I.Status NOT IN ('Scheduled', 'In Progress', 'Completed', 'Cancelled', 'No-show', 'Rescheduled')
    )
    BEGIN
        RAISERROR('Invalid appointment status value.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Do not allow moving away from terminal statuses.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.AppointmentId = I.AppointmentId
        WHERE D.Status IN ('Completed', 'Cancelled', 'No-show')
          AND I.Status <> D.Status
    )
    BEGIN
        RAISERROR('Cannot transition from terminal appointment status.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Require cancellation metadata when cancelling.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.AppointmentId = I.AppointmentId
        WHERE I.Status = 'Cancelled'
          AND D.Status <> 'Cancelled'
          AND (NULLIF(LTRIM(RTRIM(ISNULL(I.CancellationReason, ''))), '') IS NULL
               OR NULLIF(LTRIM(RTRIM(ISNULL(I.CancelledBy, ''))), '') IS NULL
               OR I.CancelledDate IS NULL)
    )
    BEGIN
        RAISERROR('Cancelled appointments require CancellationReason, CancelledBy and CancelledDate.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO
-- END FILE: 007-triggers-functions/Profile.tr_ValidateAppointmentStatusTransition.sql

IF OBJECT_ID(N'[dbo].[CapitalizeFirstLetter]', N'FN') IS NULL
    THROW 50011, 'Expected function [dbo].[CapitalizeFirstLetter] was not created.', 1;
IF OBJECT_ID(N'[dbo].[CapitalizeFirstLetterBody]', N'FN') IS NULL
    THROW 50011, 'Expected function [dbo].[CapitalizeFirstLetterBody] was not created.', 1;
IF OBJECT_ID(N'[Contacts].[FormatPhoneNumber]', N'FN') IS NULL
    THROW 50011, 'Expected function [Contacts].[FormatPhoneNumber] was not created.', 1;

IF OBJECT_ID(N'[Contacts].[tr_NormalizeAndValidateEmail]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Contacts].[tr_NormalizeAndValidateEmail] was not created.', 1;
IF OBJECT_ID(N'[Contacts].[tr_NormalizeAndValidatePhoneNumber]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Contacts].[tr_NormalizeAndValidatePhoneNumber] was not created.', 1;
IF OBJECT_ID(N'[Contacts].[tr_EnforceSinglePrimaryPatientEmail]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Contacts].[tr_EnforceSinglePrimaryPatientEmail] was not created.', 1;
IF OBJECT_ID(N'[Contacts].[tr_EnforceSinglePrimaryPatientPhone]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Contacts].[tr_EnforceSinglePrimaryPatientPhone] was not created.', 1;
IF OBJECT_ID(N'[Profile].[tr_AfterInsertPatient]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Profile].[tr_AfterInsertPatient] was not created.', 1;
IF OBJECT_ID(N'[Profile].[tr_AUpdatePatient]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Profile].[tr_AUpdatePatient] was not created.', 1;
IF OBJECT_ID(N'[Profile].[tr_ADeletePatient]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Profile].[tr_ADeletePatient] was not created.', 1;
IF OBJECT_ID(N'[Profile].[tr_BlockPatientIDNumberUpdate]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Profile].[tr_BlockPatientIDNumberUpdate] was not created.', 1;
IF OBJECT_ID(N'[Profile].[tr_ValidateAppointmentStatusTransition]', N'TR') IS NULL
    THROW 50012, 'Expected trigger [Profile].[tr_ValidateAppointmentStatusTransition] was not created.', 1;
GO

PRINT '================================================================================================';
PRINT 'Trigger/function deployment complete: ' + CONVERT(VARCHAR(25), GETDATE(), 121);
PRINT '================================================================================================';
GO
