USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [Profile].[spGetTaskQueueSourceRows]
(
    @MaxRows INT = 300
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MaxRows IS NULL OR @MaxRows < 1
    BEGIN
        SET @MaxRows = 300;
    END

    ;WITH AppointmentQueue AS
    (
        SELECT TOP (@MaxRows)
            TaskId = CASE
                WHEN A.AppointmentId IS NULL THEN 'APT-UNKNOWN'
                ELSE 'APT-' + UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), A.AppointmentId), '-', ''), 8))
            END,
            Title = CASE
                WHEN LTRIM(RTRIM(ISNULL(A.Reason, ''))) = ''
                    THEN
                        CASE
                            WHEN LTRIM(RTRIM(ISNULL(A.AppointmentType, ''))) = '' THEN 'Consultation follow-up'
                            ELSE LTRIM(RTRIM(A.AppointmentType)) + ' follow-up'
                        END
                ELSE
                    CASE
                        WHEN LTRIM(RTRIM(ISNULL(A.AppointmentType, ''))) = ''
                            THEN 'Consultation: '
                            ELSE LTRIM(RTRIM(A.AppointmentType)) + ': '
                    END
                    + CASE
                        WHEN LEN(LTRIM(RTRIM(ISNULL(A.Reason, '')))) > 72
                            THEN LEFT(LTRIM(RTRIM(ISNULL(A.Reason, ''))), 72) + '...'
                        ELSE LTRIM(RTRIM(ISNULL(A.Reason, '')))
                    END
            END,
            Team = CASE
                WHEN UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%MEDICATION%'
                    OR UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%PRESCRIPTION%'
                    OR UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%REFILL%'
                    OR UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%PHARM%'
                    THEN 'Pharmacy'
                WHEN UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%TRIAGE%'
                    OR UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%VITAL%'
                    OR UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%FOLLOW-UP%'
                    OR UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%FOLLOW UP%'
                    OR UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%NURSE%'
                    THEN 'Nursing'
                WHEN UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%LAB%'
                    OR UPPER(CONCAT(ISNULL(A.AppointmentType, ''), ' ', ISNULL(A.Reason, ''), ' ', ISNULL(HP.Specialization, ''))) LIKE '%PATHO%'
                    THEN 'Laboratory'
                ELSE 'Clinical'
            END,
            Owner = CASE
                WHEN LTRIM(RTRIM(
                    CASE
                        WHEN LTRIM(RTRIM(ISNULL(HP.Title, ''))) = ''
                            THEN LTRIM(RTRIM(CONCAT(ISNULL(HP.FirstName, ''), ' ', ISNULL(HP.LastName, ''))))
                        ELSE LTRIM(RTRIM(CONCAT(HP.Title, ' ', ISNULL(HP.FirstName, ''), ' ', ISNULL(HP.LastName, ''))))
                    END
                )) = ''
                    THEN 'Care Team'
                ELSE LTRIM(RTRIM(
                    CASE
                        WHEN LTRIM(RTRIM(ISNULL(HP.Title, ''))) = ''
                            THEN LTRIM(RTRIM(CONCAT(ISNULL(HP.FirstName, ''), ' ', ISNULL(HP.LastName, ''))))
                        ELSE LTRIM(RTRIM(CONCAT(HP.Title, ' ', ISNULL(HP.FirstName, ''), ' ', ISNULL(HP.LastName, ''))))
                    END
                ))
            END,
            Patient = CASE
                WHEN LTRIM(RTRIM(CONCAT(ISNULL(P.FirstName, ''), ' ', ISNULL(P.LastName, '')))) = ''
                    THEN 'Unknown Patient'
                ELSE LTRIM(RTRIM(CONCAT(ISNULL(P.FirstName, ''), ' ', ISNULL(P.LastName, ''))))
            END,
            IdNumber = ISNULL(P.ID_Number, ''),
            SourceStatus = CASE WHEN LTRIM(RTRIM(ISNULL(A.Status, ''))) = '' THEN 'Open' ELSE LTRIM(RTRIM(A.Status)) END,
            DueAt = COALESCE(A.AppointmentDateTime, GETDATE()),
            StartedAt = COALESCE(
                A.UpdatedDate,
                A.CreatedDate,
                DATEADD(MINUTE, -30, COALESCE(A.AppointmentDateTime, GETDATE()))
            ),
            SlaMinutes = CASE
                WHEN ISNULL(A.DurationMinutes, 30) < 15 THEN 15
                ELSE ISNULL(A.DurationMinutes, 30)
            END
        FROM Profile.Appointments A
        INNER JOIN Profile.Patient P
            ON P.PatientId = A.PatientIdFK
        LEFT JOIN Profile.HealthcareProviders HP
            ON HP.ProviderId = A.ProviderIdFK
        WHERE P.IsDeleted = 0
          AND A.AppointmentDateTime >= DATEADD(DAY, -2, GETDATE())
        ORDER BY A.AppointmentDateTime ASC, COALESCE(A.UpdatedDate, A.CreatedDate) DESC
    ),
    LabQueue AS
    (
        SELECT TOP (@MaxRows)
            TaskId = CASE
                WHEN LR.LabResultId IS NULL THEN 'LAB-UNKNOWN'
                ELSE 'LAB-' + UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), LR.LabResultId), '-', ''), 8))
            END,
            Title = CASE
                WHEN LTRIM(RTRIM(ISNULL(LR.Status, ''))) = ''
                    THEN
                        CASE
                            WHEN LTRIM(RTRIM(ISNULL(LR.TestName, ''))) = '' THEN 'Lab result review'
                            ELSE LTRIM(RTRIM(LR.TestName)) + ' review'
                        END
                ELSE
                    CASE
                        WHEN LTRIM(RTRIM(ISNULL(LR.TestName, ''))) = '' THEN 'Lab result'
                        ELSE LTRIM(RTRIM(LR.TestName))
                    END
                    + ' (' + LTRIM(RTRIM(LR.Status)) + ')'
            END,
            Team = 'Laboratory',
            Owner = CASE
                WHEN LTRIM(RTRIM(ISNULL(LR.OrderedBy, ''))) = '' THEN 'Lab Team'
                ELSE LTRIM(RTRIM(LR.OrderedBy))
            END,
            Patient = CASE
                WHEN LTRIM(RTRIM(CONCAT(ISNULL(P.FirstName, ''), ' ', ISNULL(P.LastName, '')))) = ''
                    THEN 'Unknown Patient'
                ELSE LTRIM(RTRIM(CONCAT(ISNULL(P.FirstName, ''), ' ', ISNULL(P.LastName, ''))))
            END,
            IdNumber = ISNULL(P.ID_Number, ''),
            SourceStatus = CASE WHEN LTRIM(RTRIM(ISNULL(LR.Status, ''))) = '' THEN 'Pending' ELSE LTRIM(RTRIM(LR.Status)) END,
            DueAt = COALESCE(LR.ResultDate, LR.CollectionDate, LR.CreatedDate, GETDATE()),
            StartedAt = COALESCE(
                LR.UpdatedDate,
                LR.CreatedDate,
                DATEADD(MINUTE, -60, COALESCE(LR.ResultDate, LR.CollectionDate, LR.CreatedDate, GETDATE()))
            ),
            SlaMinutes = CASE
                WHEN UPPER(ISNULL(LR.Status, '')) LIKE '%CRITIC%' THEN 20
                WHEN UPPER(ISNULL(LR.Status, '')) LIKE '%ABNORMAL%' THEN 45
                ELSE 90
            END
        FROM Profile.LabResults LR
        INNER JOIN Profile.Patient P
            ON P.PatientId = LR.PatientIdFK
        WHERE P.IsDeleted = 0
          AND COALESCE(LR.ResultDate, LR.CollectionDate, LR.CreatedDate) >= DATEADD(DAY, -21, GETDATE())
        ORDER BY COALESCE(LR.ResultDate, LR.CollectionDate, LR.CreatedDate) DESC
    ),
    BillingQueue AS
    (
        SELECT TOP (@MaxRows)
            TaskId = CASE
                WHEN LTRIM(RTRIM(ISNULL(I.InvoiceNumber, ''))) <> '' THEN LTRIM(RTRIM(I.InvoiceNumber))
                WHEN I.InvoiceId IS NULL THEN 'INV-UNKNOWN'
                ELSE 'INV-' + UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), I.InvoiceId), '-', ''), 8))
            END,
            Title =
                (
                    CASE
                        WHEN LTRIM(RTRIM(ISNULL(I.InvoiceNumber, ''))) = '' THEN 'Claim follow-up'
                        ELSE 'Claim ' + LTRIM(RTRIM(I.InvoiceNumber))
                    END
                )
                + CASE
                    WHEN LTRIM(RTRIM(ISNULL(BC.Code, ''))) = '' THEN ''
                    ELSE ' (' + LTRIM(RTRIM(BC.Code)) + ')'
                END
                + CASE
                    WHEN LTRIM(RTRIM(ISNULL(I.Description, ''))) = '' THEN ''
                    WHEN LEN(LTRIM(RTRIM(ISNULL(I.Description, '')))) > 48
                        THEN ': ' + LEFT(LTRIM(RTRIM(ISNULL(I.Description, ''))), 48) + '...'
                    ELSE ': ' + LTRIM(RTRIM(ISNULL(I.Description, '')))
                END,
            Team = 'Billing',
            Owner = CASE
                WHEN LTRIM(RTRIM(ISNULL(I.UpdatedBy, ''))) <> '' THEN LTRIM(RTRIM(I.UpdatedBy))
                WHEN LTRIM(RTRIM(ISNULL(I.CreatedBy, ''))) <> '' THEN LTRIM(RTRIM(I.CreatedBy))
                ELSE 'Revenue Team'
            END,
            Patient = CASE
                WHEN LTRIM(RTRIM(CONCAT(ISNULL(P.FirstName, ''), ' ', ISNULL(P.LastName, '')))) = ''
                    THEN 'Unknown Patient'
                ELSE LTRIM(RTRIM(CONCAT(ISNULL(P.FirstName, ''), ' ', ISNULL(P.LastName, ''))))
            END,
            IdNumber = ISNULL(P.ID_Number, ''),
            SourceStatus = CASE WHEN LTRIM(RTRIM(ISNULL(I.Status, ''))) = '' THEN 'Draft' ELSE LTRIM(RTRIM(I.Status)) END,
            DueAt = COALESCE(I.DueDate, DATEADD(DAY, 7, COALESCE(I.InvoiceDate, CAST(GETDATE() AS DATE)))),
            StartedAt = COALESCE(I.UpdatedDate, I.CreatedDate, COALESCE(I.InvoiceDate, GETDATE())),
            SlaMinutes = CASE
                WHEN UPPER(ISNULL(I.Status, '')) LIKE '%OVERDUE%' THEN 120
                WHEN UPPER(ISNULL(I.Status, '')) LIKE '%DENIED%' THEN 90
                ELSE 180
            END
        FROM Profile.Invoices I
        INNER JOIN Profile.Patient P
            ON P.PatientId = I.PatientIdFK
        LEFT JOIN Profile.BillingCodes BC
            ON BC.BillingCodeId = I.BillingCodeIdFK
        WHERE P.IsDeleted = 0
        ORDER BY COALESCE(I.DueDate, I.InvoiceDate) ASC, COALESCE(I.UpdatedDate, I.InvoiceDate) DESC
    )
    SELECT TaskId, Title, Team, Owner, Patient, IdNumber, SourceStatus, DueAt, StartedAt, SlaMinutes
    FROM AppointmentQueue
    UNION ALL
    SELECT TaskId, Title, Team, Owner, Patient, IdNumber, SourceStatus, DueAt, StartedAt, SlaMinutes
    FROM LabQueue
    UNION ALL
    SELECT TaskId, Title, Team, Owner, Patient, IdNumber, SourceStatus, DueAt, StartedAt, SlaMinutes
    FROM BillingQueue;
END
GO
