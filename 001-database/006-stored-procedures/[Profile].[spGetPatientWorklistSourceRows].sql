USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns a flat patient worklist feed for the clinical dashboard.
-- SQL handles the latest-appointment and medical-summary joins so the API can stay presentation-focused.
CREATE OR ALTER PROC [Profile].[spGetPatientWorklistSourceRows]
(
    @MaxRows INT = 250
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MaxRows IS NULL OR @MaxRows < 1
    BEGIN
        SET @MaxRows = 250;
    END

    IF @MaxRows > 1000
    BEGIN
        SET @MaxRows = 1000;
    END

    -- Keep only the most recent appointment per patient so the worklist reflects
    -- the latest operational touchpoint instead of every historical booking.
    ;WITH LatestAppointmentPerPatient AS
    (
        SELECT
            A.PatientIdFK,
            AppointmentStatus = LTRIM(RTRIM(ISNULL(A.Status, ''))),
            Specialization = LTRIM(RTRIM(ISNULL(HP.Specialization, ''))),
            AppointmentDateTime = A.AppointmentDateTime,
            AppointmentUpdatedDate = COALESCE(A.UpdatedDate, A.CreatedDate, A.AppointmentDateTime),
            RN = ROW_NUMBER() OVER
            (
                PARTITION BY A.PatientIdFK
                ORDER BY
                    COALESCE(A.AppointmentDateTime, CONVERT(DATETIME, '19000101', 112)) DESC,
                    COALESCE(A.UpdatedDate, A.CreatedDate, CONVERT(DATETIME, '19000101', 112)) DESC,
                    A.AppointmentId DESC
            )
        FROM Profile.Appointments A
        LEFT JOIN Profile.HealthcareProviders HP
            ON HP.ProviderId = A.ProviderIdFK
    ),
    -- Roll up active and chronic-condition counts once per patient for the risk label.
    MedicalSummary AS
    (
        SELECT
            MH.PatientIdFK,
            ActiveConditions = SUM(CASE WHEN MH.IsActive = 1 THEN 1 ELSE 0 END),
            ChronicConditions = SUM
            (
                CASE
                    WHEN MH.IsActive = 1
                     AND UPPER(LTRIM(RTRIM(ISNULL(MH.Status, '')))) = 'CHRONIC'
                        THEN 1
                    ELSE 0
                END
            )
        FROM Profile.MedicalHistory MH
        GROUP BY MH.PatientIdFK
    )
    SELECT TOP (@MaxRows)
        IdNumber = ISNULL(P.ID_Number, ''),
        FirstName = ISNULL(P.FirstName, ''),
        LastName = ISNULL(P.LastName, ''),
        DateOfBirth = P.DateOfBirth,
        UpdatedDate = COALESCE(P.UpdatedDate, P.CreatedDate, GETDATE()),
        AppointmentStatus = CASE
            WHEN LTRIM(RTRIM(ISNULL(LA.AppointmentStatus, ''))) = '' THEN 'Scheduled'
            ELSE LA.AppointmentStatus
        END,
        Specialization = CASE
            WHEN LTRIM(RTRIM(ISNULL(LA.Specialization, ''))) = '' THEN 'General Practice'
            ELSE LA.Specialization
        END,
        ActiveConditions = ISNULL(MS.ActiveConditions, 0),
        ChronicConditions = ISNULL(MS.ChronicConditions, 0)
    FROM Profile.Patient P
    LEFT JOIN LatestAppointmentPerPatient LA
        ON LA.PatientIdFK = P.PatientId
       AND LA.RN = 1
    LEFT JOIN MedicalSummary MS
        ON MS.PatientIdFK = P.PatientId
    WHERE P.IsDeleted = 0
    ORDER BY
        COALESCE(LA.AppointmentDateTime, CONVERT(DATETIME, '19000101', 112)) DESC,
        COALESCE(P.UpdatedDate, P.CreatedDate, GETDATE()) DESC,
        P.LastName ASC,
        P.FirstName ASC;
END
GO
