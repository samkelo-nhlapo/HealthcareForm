-- V26__client_provider_affiliations_backfill.sql
-- Phase 2 data alignment for the client-provider affiliation model.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Profile].[ClientStaff]')
      AND name = N'IX_ClientStaff_ProviderIdFK'
)
BEGIN
    CREATE INDEX IX_ClientStaff_ProviderIdFK ON [Profile].[ClientStaff]([ProviderIdFK]);
END
GO

IF OBJECT_ID(N'[Profile].[ClientProviderAffiliations]', N'U') IS NOT NULL
AND OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NOT NULL
BEGIN
    DECLARE @MissingBefore INT = 0;
    DECLARE @InsertedCount INT = 0;
    DECLARE @MissingAfter INT = 0;

    SELECT @MissingBefore = COUNT(*)
    FROM
    (
        SELECT DISTINCT
            A.ClientIdFK,
            A.ProviderIdFK
        FROM Profile.Appointments A
        WHERE A.ClientIdFK IS NOT NULL
          AND A.ProviderIdFK IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM Profile.ClientProviderAffiliations CPA
              WHERE CPA.ClientIdFK = A.ClientIdFK
                AND CPA.ProviderIdFK = A.ProviderIdFK
          )
    ) MissingPairsBefore;

    ;WITH RankedStaff AS
    (
        SELECT
            CS.ClientStaffId,
            CS.ClientIdFK,
            CS.ProviderIdFK,
            CS.PrimaryDepartmentIdFK,
            CS.IsActive,
            CS.HireDate,
            CS.TerminationDate,
            CS.CreatedDate,
            CS.CreatedBy,
            CS.UpdatedDate,
            CS.UpdatedBy,
            IsSyntheticAppointmentStaff = CASE
                WHEN ISNULL(CS.CreatedBy, '') = 'V24_APPOINTMENT_CLIENTSTAFF'
                  OR ISNULL(CS.UpdatedBy, '') = 'V24_APPOINTMENT_CLIENTSTAFF'
                    THEN 1
                ELSE 0
            END,
            RN = ROW_NUMBER() OVER
            (
                PARTITION BY CS.ClientIdFK, CS.ProviderIdFK
                ORDER BY
                    CASE
                        WHEN
                            (
                                ISNULL(CS.CreatedBy, '') <> 'V24_APPOINTMENT_CLIENTSTAFF'
                                AND ISNULL(CS.UpdatedBy, '') <> 'V24_APPOINTMENT_CLIENTSTAFF'
                                AND CS.IsActive = 1
                            )
                            THEN 0
                        WHEN CS.IsActive = 1
                            THEN 1
                        WHEN
                            (
                                ISNULL(CS.CreatedBy, '') <> 'V24_APPOINTMENT_CLIENTSTAFF'
                                AND ISNULL(CS.UpdatedBy, '') <> 'V24_APPOINTMENT_CLIENTSTAFF'
                            )
                            THEN 2
                        ELSE 3
                    END,
                    COALESCE(CS.UpdatedDate, CS.CreatedDate, GETDATE()) DESC,
                    CS.ClientStaffId DESC
            )
        FROM Profile.ClientStaff CS
        WHERE CS.ClientIdFK IS NOT NULL
          AND CS.ProviderIdFK IS NOT NULL
          AND CS.IsDeleted = 0
    ),
    AffiliationSource AS
    (
        SELECT
            ClientProviderAffiliationId = NEWID(),
            RS.ClientIdFK,
            RS.ProviderIdFK,
            ClientStaffIdFK = CASE
                WHEN RS.IsSyntheticAppointmentStaff = 1 THEN NULL
                ELSE RS.ClientStaffId
            END,
            RS.PrimaryDepartmentIdFK,
            RelationshipType = CASE
                WHEN RS.IsSyntheticAppointmentStaff = 1 THEN 'Visiting'
                ELSE 'Employee'
            END,
            CanBookAppointments = CAST(1 AS bit),
            CanReceiveReferrals = CAST(1 AS bit),
            StartDate = COALESCE(RS.HireDate, RS.CreatedDate, RS.UpdatedDate, GETDATE()),
            EndDate = CASE
                WHEN RS.IsSyntheticAppointmentStaff = 1 THEN NULL
                WHEN RS.TerminationDate IS NOT NULL THEN RS.TerminationDate
                WHEN RS.IsActive = 0 THEN COALESCE(RS.UpdatedDate, RS.CreatedDate, GETDATE())
                ELSE NULL
            END,
            IsActive = CAST(RS.IsActive AS bit),
            Notes = CASE
                WHEN RS.IsSyntheticAppointmentStaff = 1
                    THEN 'Backfilled from appointment-generated client staff row during V26.'
                ELSE 'Backfilled from client staff row during V26.'
            END,
            CreatedDate = COALESCE(RS.CreatedDate, GETDATE()),
            CreatedBy = COALESCE(NULLIF(RS.CreatedBy, ''), 'V26_CLIENT_PROVIDER_AFFILIATIONS'),
            UpdatedDate = COALESCE(RS.UpdatedDate, RS.CreatedDate, GETDATE()),
            UpdatedBy = COALESCE(NULLIF(RS.UpdatedBy, ''), NULLIF(RS.CreatedBy, ''), 'V26_CLIENT_PROVIDER_AFFILIATIONS')
        FROM RankedStaff RS
        WHERE RS.RN = 1
    )
    INSERT INTO Profile.ClientProviderAffiliations
    (
        ClientProviderAffiliationId,
        ClientIdFK,
        ProviderIdFK,
        ClientStaffIdFK,
        PrimaryDepartmentIdFK,
        RelationshipType,
        CanBookAppointments,
        CanReceiveReferrals,
        StartDate,
        EndDate,
        IsActive,
        Notes,
        CreatedDate,
        CreatedBy,
        UpdatedDate,
        UpdatedBy
    )
    SELECT
        SRC.ClientProviderAffiliationId,
        SRC.ClientIdFK,
        SRC.ProviderIdFK,
        SRC.ClientStaffIdFK,
        SRC.PrimaryDepartmentIdFK,
        SRC.RelationshipType,
        SRC.CanBookAppointments,
        SRC.CanReceiveReferrals,
        SRC.StartDate,
        SRC.EndDate,
        SRC.IsActive,
        SRC.Notes,
        SRC.CreatedDate,
        SRC.CreatedBy,
        SRC.UpdatedDate,
        SRC.UpdatedBy
    FROM AffiliationSource SRC
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM Profile.ClientProviderAffiliations Existing
        WHERE Existing.ClientIdFK = SRC.ClientIdFK
          AND Existing.ProviderIdFK = SRC.ProviderIdFK
    );

    SET @InsertedCount = @@ROWCOUNT;

    SELECT @MissingAfter = COUNT(*)
    FROM
    (
        SELECT DISTINCT
            A.ClientIdFK,
            A.ProviderIdFK
        FROM Profile.Appointments A
        WHERE A.ClientIdFK IS NOT NULL
          AND A.ProviderIdFK IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM Profile.ClientProviderAffiliations CPA
              WHERE CPA.ClientIdFK = A.ClientIdFK
                AND CPA.ProviderIdFK = A.ProviderIdFK
          )
    ) MissingPairsAfter;

    PRINT 'V26 ClientProviderAffiliations backfill complete.';
    PRINT 'Missing appointment client/provider pairs before backfill: ' + CAST(@MissingBefore AS VARCHAR(20));
    PRINT 'Affiliations inserted in V26: ' + CAST(@InsertedCount AS VARCHAR(20));
    PRINT 'Missing appointment client/provider pairs after backfill: ' + CAST(@MissingAfter AS VARCHAR(20));
END
GO
