USE HealthcareForm
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

SET ANSI_PADDING ON;
GO

SET ANSI_WARNINGS ON;
GO

SET ARITHABORT ON;
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO

SET NUMERIC_ROUNDABORT OFF;
GO

SET NOCOUNT ON;
GO

--================================================================================================
-- Author:        HealthcareForm
-- Create date:   22/04/2026
-- Description:   Seed realistic dummy client-staff data for development/UAT.
-- Notes:         Idempotent. Adds common healthcare and facilities roles such as
--                doctors, nurses, receptionists, matrons, admins, cleaners, and janitors.
--================================================================================================

IF OBJECT_ID(N'[Profile].[Clients]', N'U') IS NULL
   OR OBJECT_ID(N'[Profile].[ClientStaff]', N'U') IS NULL
   OR OBJECT_ID(N'[Profile].[StaffDesignations]', N'U') IS NULL
   OR OBJECT_ID(N'[Profile].[ClientDepartments]', N'U') IS NULL
BEGIN
    PRINT 'Skipped staff dummy-data seed: required client/staff tables are missing.';
    RETURN;
END

DECLARE @Now DATETIME = GETDATE();
DECLARE @SeedActor VARCHAR(250) = 'SYSTEM_DUMMY_STAFF_SEED';
DECLARE @MaxClients INT = 25;
DECLARE @DesignationsInserted INT = 0;
DECLARE @DepartmentsInserted INT = 0;
DECLARE @StaffInserted INT = 0;
DECLARE @AppointmentsInserted INT = 0;
DECLARE @PatientClientsHasIsDeleted BIT = CASE
    WHEN COL_LENGTH('Profile.PatientClients', 'IsDeleted') IS NULL THEN 0
    ELSE 1
END;
DECLARE @ResolveSeedClientSql NVARCHAR(MAX) = N'';

-- Step 1: Expand baseline designation lookup values used by seeded staff records.
INSERT INTO [Profile].[StaffDesignations]
(
    [StaffDesignationId],
    [DesignationName],
    [Category],
    [Description],
    [IsActive],
    [CreatedDate],
    [CreatedBy],
    [UpdatedDate],
    [UpdatedBy]
)
SELECT
    NEWID(),
    V.DesignationName,
    V.Category,
    V.Description,
    1,
    @Now,
    @SeedActor,
    @Now,
    @SeedActor
FROM
(
    VALUES
        ('Doctor', 'Clinical', 'Medical doctor responsible for diagnosis and treatment'),
        ('Nurse', 'Clinical', 'Registered or enrolled nurse for bedside care'),
        ('Matron', 'Management', 'Senior nursing manager overseeing wards and nursing teams'),
        ('Receptionist', 'Administrative', 'Front-desk coordinator for appointments and patient flow'),
        ('Administrator', 'Administrative', 'Administrative coordinator supporting operations and records'),
        ('Cleaner', 'Support', 'Housekeeping staff responsible for cleanliness and infection control'),
        ('Janitor', 'Support', 'Facilities support staff maintaining non-clinical spaces'),
        ('Pharmacist', 'Allied', 'Licensed pharmacist supporting medication workflows')
) V(DesignationName, Category, Description)
WHERE NOT EXISTS
(
    SELECT 1
    FROM [Profile].[StaffDesignations] SD
    WHERE SD.[DesignationName] = V.DesignationName
);

SET @DesignationsInserted = @@ROWCOUNT;

-- Step 2: Select active clients with the sparsest staff coverage first.
DECLARE @SeedClients TABLE
(
    ClientId UNIQUEIDENTIFIER PRIMARY KEY,
    ClientCode VARCHAR(50) NOT NULL
);

INSERT INTO @SeedClients
(
    ClientId,
    ClientCode
)
SELECT TOP (@MaxClients)
    C.ClientId,
    COALESCE(NULLIF(LTRIM(RTRIM(C.ClientCode)), ''), 'CLIENT')
FROM Profile.Clients C
OUTER APPLY
(
    SELECT COUNT(1) AS StaffCount
    FROM Profile.ClientStaff CS
    WHERE CS.ClientIdFK = C.ClientId
      AND CS.IsDeleted = 0
) ExistingStaff
WHERE C.IsDeleted = 0
  AND C.IsActive = 1
ORDER BY ISNULL(ExistingStaff.StaffCount, 0) ASC, C.CreatedDate ASC, C.ClientCode ASC;

IF NOT EXISTS (SELECT 1 FROM @SeedClients)
BEGIN
    PRINT 'Skipped staff dummy-data seed: no active client records were found.';
    RETURN;
END

-- Step 3: Ensure each selected client has core departments used by the seeded staff set.
;WITH DepartmentBlueprint AS
(
    SELECT *
    FROM
    (
        VALUES
            ('CLIN', 'Clinical Services', 'Clinical'),
            ('NURS', 'Nursing Services', 'Clinical'),
            ('PHRM', 'Pharmacy', 'Clinical'),
            ('FRNT', 'Front Desk', 'Administrative'),
            ('ADMN', 'Administration', 'Administrative'),
            ('FACI', 'Facilities', 'Support'),
            ('HSKP', 'Housekeeping', 'Support'),
            ('OPS', 'Operations', 'Management')
    ) D(DepartmentCode, DepartmentName, DepartmentType)
),
DepartmentSeed AS
(
    SELECT
        SC.ClientId,
        SC.ClientCode,
        DB.DepartmentCode,
        DB.DepartmentName,
        DB.DepartmentType
    FROM @SeedClients SC
    CROSS JOIN DepartmentBlueprint DB
)
INSERT INTO Profile.ClientDepartments
(
    ClientDepartmentId,
    ClientIdFK,
    DepartmentCode,
    DepartmentName,
    DepartmentType,
    IsActive,
    IsDeleted,
    CreatedDate,
    CreatedBy,
    UpdatedDate,
    UpdatedBy
)
SELECT
    NEWID(),
    DS.ClientId,
    CONCAT(
        LEFT(
            REPLACE(REPLACE(REPLACE(REPLACE(UPPER(DS.ClientCode), ' ', ''), '-', ''), '_', ''), '/', ''),
            12
        ),
        '-',
        DS.DepartmentCode
    ),
    DS.DepartmentName,
    DS.DepartmentType,
    1,
    0,
    @Now,
    @SeedActor,
    @Now,
    @SeedActor
FROM DepartmentSeed DS
WHERE NOT EXISTS
(
    SELECT 1
    FROM Profile.ClientDepartments ExistingDepartment
    WHERE ExistingDepartment.ClientIdFK = DS.ClientId
      AND ExistingDepartment.DepartmentName = DS.DepartmentName
      AND ExistingDepartment.IsDeleted = 0
);

SET @DepartmentsInserted = @@ROWCOUNT;

-- Step 4: Seed realistic staff profiles across clinical, admin, management, and support roles.
;WITH StaffBlueprint AS
(
    SELECT *
    FROM
    (
        VALUES
            (1, 'DOC',  'Lerato',  'Mokoena', 'Doctor',       'Medical Doctor',         'Clinical Services', 'Clinical',      'Full-Time', 'DOCTOR',       0),
            (2, 'NUR',  'Ayanda',  'Khumalo', 'Nurse',        'Registered Nurse',       'Nursing Services',  'Clinical',      'Full-Time', 'NURSE',        0),
            (3, 'MAT',  'Nomsa',   'Dlamini', 'Matron',       'Ward Matron',            'Operations',        'Management',    'Full-Time', NULL,           0),
            (4, 'REC',  'Thandi',  'Nkosi',   'Receptionist', 'Receptionist',           'Front Desk',        'Administrative', 'Full-Time', 'RECEPTIONIST', 1),
            (5, 'ADM',  'Mandla',  'Pillay',  'Administrator','Clinic Administrator',   'Administration',    'Administrative', 'Full-Time', 'ADMIN',        0),
            (6, 'CLN',  'Zanele',  'Sithole', 'Cleaner',      'Facility Cleaner',       'Housekeeping',      'Support',       'Contract',  NULL,           0),
            (7, 'JAN',  'Sipho',   'Naidoo',  'Janitor',      'Janitor',                'Facilities',        'Support',       'Full-Time', NULL,           0),
            (8, 'PHA',  'Kagiso',  'Mabena',  'Pharmacist',   'Clinical Pharmacist',    'Pharmacy',          'Clinical',      'Full-Time', 'PHARMACIST',   0)
    ) S(
        SortOrder,
        RoleCode,
        FirstName,
        LastName,
        DesignationName,
        JobTitle,
        DepartmentName,
        StaffType,
        EmploymentType,
        RoleName,
        IsPrimaryContactCandidate
    )
),
CandidateStaff AS
(
    SELECT
        SC.ClientId,
        RoleMap.RoleId AS RoleIdFK,
        CASE
            WHEN SB.RoleName = 'DOCTOR' THEN ProviderSelection.ProviderId
            ELSE NULL
        END AS ProviderIdFK,
        StaffDesignations.StaffDesignationId AS StaffDesignationIdFK,
        Departments.ClientDepartmentId AS PrimaryDepartmentIdFK,
        CONCAT(
            'DUMMY-',
            LEFT(
                REPLACE(REPLACE(REPLACE(REPLACE(UPPER(SC.ClientCode), ' ', ''), '-', ''), '_', ''), '/', ''),
                8
            ),
            '-',
            SB.RoleCode,
            '-',
            RIGHT(REPLACE(CONVERT(VARCHAR(36), SC.ClientId), '-', ''), 4)
        ) AS StaffCode,
        SB.FirstName,
        SB.LastName,
        LOWER(CONCAT(SB.RoleCode, '.', RIGHT(REPLACE(CONVERT(VARCHAR(36), SC.ClientId), '-', ''), 8), '@healthcareform.test')) AS Email,
        CONCAT(
            '+27 10 ',
            RIGHT(CONCAT('000', CAST(100 + SB.SortOrder AS VARCHAR(3))), 3),
            ' ',
            RIGHT(REPLACE(CONVERT(VARCHAR(36), SC.ClientId), '-', ''), 4)
        ) AS PhoneNumber,
        SB.JobTitle,
        SB.DepartmentName AS Department,
        SB.StaffType,
        SB.EmploymentType,
        DATEADD(DAY, -(SB.SortOrder * 35), @Now) AS HireDate,
        CASE
            WHEN SB.IsPrimaryContactCandidate = 1
             AND NOT EXISTS
             (
                 SELECT 1
                 FROM Profile.ClientStaff ExistingPrimary
                 WHERE ExistingPrimary.ClientIdFK = SC.ClientId
                   AND ExistingPrimary.IsDeleted = 0
                   AND ExistingPrimary.IsPrimaryContact = 1
             )
                THEN 1
            ELSE 0
        END AS IsPrimaryContact
    FROM @SeedClients SC
    CROSS JOIN StaffBlueprint SB
    LEFT JOIN Auth.Roles RoleMap
        ON RoleMap.RoleName = SB.RoleName
    LEFT JOIN Profile.StaffDesignations StaffDesignations
        ON StaffDesignations.DesignationName = SB.DesignationName
    LEFT JOIN Profile.ClientDepartments Departments
        ON Departments.ClientIdFK = SC.ClientId
       AND Departments.DepartmentName = SB.DepartmentName
       AND Departments.IsDeleted = 0
    OUTER APPLY
    (
        SELECT TOP 1 HP.ProviderId
        FROM Profile.HealthcareProviders HP
        WHERE HP.IsActive = 1
        ORDER BY ABS(CHECKSUM(CONCAT(CONVERT(VARCHAR(36), SC.ClientId), '|', CONVERT(VARCHAR(36), HP.ProviderId))))
    ) ProviderSelection
)
INSERT INTO Profile.ClientStaff
(
    ClientStaffId,
    ClientIdFK,
    RoleIdFK,
    UserIdFK,
    ProviderIdFK,
    StaffDesignationIdFK,
    PrimaryDepartmentIdFK,
    StaffCode,
    FirstName,
    LastName,
    Email,
    PhoneNumber,
    JobTitle,
    Department,
    StaffType,
    EmploymentType,
    HireDate,
    TerminationDate,
    IsPrimaryContact,
    IsActive,
    IsDeleted,
    CreatedDate,
    CreatedBy,
    UpdatedDate,
    UpdatedBy
)
SELECT
    NEWID(),
    CS.ClientId,
    CS.RoleIdFK,
    NULL,
    CS.ProviderIdFK,
    CS.StaffDesignationIdFK,
    CS.PrimaryDepartmentIdFK,
    CS.StaffCode,
    CS.FirstName,
    CS.LastName,
    CS.Email,
    CS.PhoneNumber,
    CS.JobTitle,
    CS.Department,
    CS.StaffType,
    CS.EmploymentType,
    CS.HireDate,
    NULL,
    CS.IsPrimaryContact,
    1,
    0,
    @Now,
    @SeedActor,
    @Now,
    @SeedActor
FROM CandidateStaff CS
WHERE NOT EXISTS
(
    SELECT 1
    FROM Profile.ClientStaff ExistingByCode
    WHERE ExistingByCode.StaffCode = CS.StaffCode
)
AND NOT EXISTS
(
    SELECT 1
    FROM Profile.ClientStaff ExistingByEmail
    WHERE ExistingByEmail.ClientIdFK = CS.ClientId
      AND ExistingByEmail.Email = CS.Email
      AND ExistingByEmail.IsDeleted = 0
);

SET @StaffInserted = @@ROWCOUNT;

-- Step 5: Ensure at least one same-day appointment exists for live scheduling snapshots.
IF OBJECT_ID(N'[Profile].[Appointments]', N'U') IS NOT NULL
   AND OBJECT_ID(N'[Profile].[Patient]', N'U') IS NOT NULL
   AND OBJECT_ID(N'[Profile].[HealthcareProviders]', N'U') IS NOT NULL
BEGIN
    DECLARE @DayStart DATETIME = CAST(@Now AS DATE);
    DECLARE @SeedAppointmentDateTime DATETIME = DATEADD(HOUR, 12, @DayStart);
    DECLARE @SeedPatientId UNIQUEIDENTIFIER = NULL;
    DECLARE @SeedProviderId UNIQUEIDENTIFIER = NULL;
    DECLARE @SeedClientId UNIQUEIDENTIFIER = NULL;
    DECLARE @SeedAppointmentType VARCHAR(100) = 'Consultation';
    DECLARE @SeedReason VARCHAR(MAX) = 'Seeded same-day scheduling appointment.';
    DECLARE @SeedLocation VARCHAR(250) = 'Main Clinic';
    DECLARE @SeedDurationMinutes INT = 30;

    IF NOT EXISTS
    (
        SELECT 1
        FROM Profile.Appointments A
        WHERE A.AppointmentDateTime >= @DayStart
          AND A.AppointmentDateTime < DATEADD(DAY, 1, @DayStart)
    )
    BEGIN
        SELECT TOP 1
            @SeedPatientId = A.PatientIdFK,
            @SeedProviderId = A.ProviderIdFK,
            @SeedClientId = A.ClientIdFK,
            @SeedAppointmentType = COALESCE(NULLIF(LTRIM(RTRIM(A.AppointmentType)), ''), 'Consultation'),
            @SeedReason = COALESCE(NULLIF(LTRIM(RTRIM(A.Reason)), ''), 'Seeded same-day scheduling appointment.'),
            @SeedLocation = COALESCE(NULLIF(LTRIM(RTRIM(A.Location)), ''), 'Main Clinic'),
            @SeedDurationMinutes = CASE
                                       WHEN ISNULL(A.DurationMinutes, 0) < 5 THEN 30
                                       ELSE A.DurationMinutes
                                   END
        FROM Profile.Appointments A
        ORDER BY COALESCE(A.UpdatedDate, A.CreatedDate, A.AppointmentDateTime) DESC;

        IF @SeedPatientId IS NULL
        BEGIN
            SELECT TOP 1 @SeedPatientId = P.PatientId
            FROM Profile.Patient P
            WHERE P.IsDeleted = 0
            ORDER BY COALESCE(P.UpdatedDate, P.CreatedDate) DESC;
        END

        IF @SeedProviderId IS NULL
        BEGIN
            SELECT TOP 1 @SeedProviderId = HP.ProviderId
            FROM Profile.HealthcareProviders HP
            WHERE HP.IsActive = 1
            ORDER BY HP.LastName, HP.FirstName;
        END

        IF @SeedClientId IS NULL AND OBJECT_ID(N'[Profile].[PatientClients]', N'U') IS NOT NULL AND @SeedPatientId IS NOT NULL
        BEGIN
            SET @ResolveSeedClientSql = N'
                SELECT TOP 1 @ResolvedClientId = PC.ClientIdFK
                FROM Profile.PatientClients PC
                WHERE PC.PatientIdFK = @SeedPatientId'
                + CASE
                    WHEN @PatientClientsHasIsDeleted = 1
                        THEN N' AND (PC.IsDeleted = 0 OR PC.IsDeleted IS NULL)'
                    ELSE N''
                  END
                + N'
                ORDER BY
                    CASE WHEN ISNULL(PC.IsPrimary, 0) = 1 THEN 0 ELSE 1 END,
                    COALESCE(PC.UpdatedDate, PC.CreatedDate) DESC;';

            EXEC sys.sp_executesql
                @ResolveSeedClientSql,
                N'@SeedPatientId UNIQUEIDENTIFIER, @ResolvedClientId UNIQUEIDENTIFIER OUTPUT',
                @SeedPatientId = @SeedPatientId,
                @ResolvedClientId = @SeedClientId OUTPUT;
        END

        IF @SeedClientId IS NULL AND COL_LENGTH('Profile.Patient', 'ClientIdFK') IS NOT NULL AND @SeedPatientId IS NOT NULL
        BEGIN
            SELECT TOP 1 @SeedClientId = P.ClientIdFK
            FROM Profile.Patient P
            WHERE P.PatientId = @SeedPatientId;
        END

        IF @SeedPatientId IS NOT NULL AND @SeedProviderId IS NOT NULL
        BEGIN
            INSERT INTO Profile.Appointments
            (
                AppointmentId,
                PatientIdFK,
                ProviderIdFK,
                AppointmentDateTime,
                DurationMinutes,
                AppointmentType,
                Reason,
                Location,
                Status,
                Reminders,
                Notes,
                CreatedDate,
                CreatedBy,
                UpdatedDate,
                UpdatedBy,
                ClientIdFK
            )
            VALUES
            (
                NEWID(),
                @SeedPatientId,
                @SeedProviderId,
                @SeedAppointmentDateTime,
                @SeedDurationMinutes,
                @SeedAppointmentType,
                @SeedReason,
                @SeedLocation,
                'Scheduled',
                NULL,
                'Auto-seeded same-day row for scheduling dashboard readiness.',
                @Now,
                @SeedActor,
                @Now,
                @SeedActor,
                @SeedClientId
            );

            SET @AppointmentsInserted = @@ROWCOUNT;
        END
    END
END

PRINT 'Client staff dummy-data seed complete.';
PRINT 'Designations inserted: ' + CAST(@DesignationsInserted AS VARCHAR(20));
PRINT 'Departments inserted: ' + CAST(@DepartmentsInserted AS VARCHAR(20));
PRINT 'Staff members inserted: ' + CAST(@StaffInserted AS VARCHAR(20));
PRINT 'Appointments inserted: ' + CAST(@AppointmentsInserted AS VARCHAR(20));
GO
