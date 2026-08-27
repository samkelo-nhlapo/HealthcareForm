using System.Data.SqlClient;

namespace HealthcareForm.Tests.Integration;

public sealed class IntegrationDatabaseFixture : IAsyncLifetime
{
    public async Task InitializeAsync()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            """
            SET NOCOUNT ON;
            SET XACT_ABORT ON;
            SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

            BEGIN TRANSACTION;

            DECLARE @Now DATETIME = GETDATE();
            DECLARE @CountryId INT;
            DECLARE @ProvinceId INT;
            DECLARE @CityId INT;
            DECLARE @GenderId INT;
            DECLARE @MaritalStatusId INT;
            DECLARE @RoleId UNIQUEIDENTIFIER;
            DECLARE @ProviderId UNIQUEIDENTIFIER;
            DECLARE @ClientId UNIQUEIDENTIFIER;
            DECLARE @PatientId UNIQUEIDENTIFIER;
            DECLARE @ClientStaffId UNIQUEIDENTIFIER;

            IF NOT EXISTS (SELECT 1 FROM Location.Countries WHERE CountryName = 'Integration Test Country')
            BEGIN
                INSERT INTO Location.Countries
                (
                    CountryName,
                    Alpha2Code,
                    Alpha3Code,
                    Numeric,
                    IsActive,
                    UpdateDate
                )
                VALUES ('Integration Test Country', 'QX', 'QXT', 998, 1, @Now);
            END

            UPDATE Location.Countries
            SET IsActive = 1,
                UpdateDate = @Now
            WHERE CountryName = 'Integration Test Country';

            SELECT TOP (1) @CountryId = CountryId
            FROM Location.Countries
            WHERE CountryName = 'Integration Test Country';

            IF NOT EXISTS
            (
                SELECT 1
                FROM Location.Provinces
                WHERE ProvinceName = 'Integration Test Province'
                  AND CountryIDFK = @CountryId
            )
            BEGIN
                INSERT INTO Location.Provinces
                (
                    ProvinceName,
                    CountryIDFK,
                    IsActive,
                    UpdateDate
                )
                VALUES ('Integration Test Province', @CountryId, 1, @Now);
            END

            UPDATE Location.Provinces
            SET IsActive = 1,
                UpdateDate = @Now
            WHERE ProvinceName = 'Integration Test Province'
              AND CountryIDFK = @CountryId;

            SELECT TOP (1) @ProvinceId = ProvinceId
            FROM Location.Provinces
            WHERE ProvinceName = 'Integration Test Province'
              AND CountryIDFK = @CountryId;

            IF NOT EXISTS
            (
                SELECT 1
                FROM Location.Cities
                WHERE CityName = 'Integration Test City'
                  AND ProvinceIDFK = @ProvinceId
            )
            BEGIN
                INSERT INTO Location.Cities
                (
                    CityName,
                    ProvinceIDFK,
                    IsActive,
                    UpdateDate
                )
                VALUES ('Integration Test City', @ProvinceId, 1, @Now);
            END

            UPDATE Location.Cities
            SET IsActive = 1,
                UpdateDate = @Now
            WHERE CityName = 'Integration Test City'
              AND ProvinceIDFK = @ProvinceId;

            SELECT TOP (1) @CityId = CityId
            FROM Location.Cities
            WHERE CityName = 'Integration Test City'
              AND ProvinceIDFK = @ProvinceId;

            IF NOT EXISTS (SELECT 1 FROM Profile.Gender WHERE GenderDescription = 'Integration Test Gender')
            BEGIN
                INSERT INTO Profile.Gender (GenderDescription, IsActive, UpdateDate)
                VALUES ('Integration Test Gender', 1, @Now);
            END

            UPDATE Profile.Gender
            SET IsActive = 1,
                UpdateDate = @Now
            WHERE GenderDescription = 'Integration Test Gender';

            SELECT TOP (1) @GenderId = GenderId
            FROM Profile.Gender
            WHERE GenderDescription = 'Integration Test Gender';

            IF NOT EXISTS (SELECT 1 FROM Profile.MaritalStatus WHERE MaritalStatusDescription = 'Integration Test Status')
            BEGIN
                INSERT INTO Profile.MaritalStatus (MaritalStatusDescription, IsActive, UpdateDate)
                VALUES ('Integration Test Status', 1, @Now);
            END

            UPDATE Profile.MaritalStatus
            SET IsActive = 1,
                UpdateDate = @Now
            WHERE MaritalStatusDescription = 'Integration Test Status';

            SELECT TOP (1) @MaritalStatusId = MaritalStatusId
            FROM Profile.MaritalStatus
            WHERE MaritalStatusDescription = 'Integration Test Status';

            IF NOT EXISTS (SELECT 1 FROM Auth.Roles WHERE RoleName = 'DOCTOR')
            BEGIN
                INSERT INTO Auth.Roles
                (
                    RoleId,
                    RoleName,
                    Description,
                    IsActive,
                    CreatedDate,
                    CreatedBy,
                    UpdatedDate,
                    UpdatedBy
                )
                VALUES
                (
                    '33333333-3333-3333-3333-333333333333',
                    'DOCTOR',
                    'Integration test doctor role.',
                    1,
                    @Now,
                    'INTEGRATION_TEST',
                    @Now,
                    'INTEGRATION_TEST'
                );
            END

            UPDATE Auth.Roles
            SET IsActive = 1,
                UpdatedDate = @Now,
                UpdatedBy = 'INTEGRATION_TEST'
            WHERE RoleName = 'DOCTOR';

            SELECT TOP (1) @RoleId = RoleId
            FROM Auth.Roles
            WHERE RoleName = 'DOCTOR';

            IF NOT EXISTS (SELECT 1 FROM Profile.HealthcareProviders WHERE LicenseNumber = 'HF-TEST-PROVIDER')
            BEGIN
                INSERT INTO Profile.HealthcareProviders
                (
                    ProviderId,
                    FirstName,
                    LastName,
                    Title,
                    Specialization,
                    LicenseNumber,
                    RegistrationBody,
                    ProviderType,
                    Qualifications,
                    YearsOfExperience,
                    OfficeAddressIdFK,
                    IsActive,
                    CreatedDate,
                    CreatedBy,
                    UpdatedDate,
                    UpdatedBy
                )
                VALUES
                (
                    '44444444-4444-4444-4444-444444444444',
                    'Integration',
                    'Provider',
                    'Dr.',
                    'General',
                    'HF-TEST-PROVIDER',
                    'Integration Test Registry',
                    'Doctor',
                    'Integration test provider.',
                    1,
                    NULL,
                    1,
                    @Now,
                    'INTEGRATION_TEST',
                    @Now,
                    'INTEGRATION_TEST'
                );
            END

            UPDATE Profile.HealthcareProviders
            SET IsActive = 1,
                UpdatedDate = @Now,
                UpdatedBy = 'INTEGRATION_TEST'
            WHERE LicenseNumber = 'HF-TEST-PROVIDER';

            SELECT TOP (1) @ProviderId = ProviderId
            FROM Profile.HealthcareProviders
            WHERE LicenseNumber = 'HF-TEST-PROVIDER';

            IF NOT EXISTS (SELECT 1 FROM Profile.Clients WHERE ClientCode = 'HF-TEST-CLIENT')
            BEGIN
                INSERT INTO Profile.Clients
                (
                    ClientId,
                    PatientIdFK,
                    ClientClinicCategoryIDFK,
                    ClientCode,
                    FirstName,
                    LastName,
                    DateOfBirth,
                    ID_Number,
                    Email,
                    PhoneNumber,
                    AddressIDFK,
                    IsActive,
                    IsDeleted,
                    CreatedDate,
                    CreatedBy,
                    UpdatedDate,
                    UpdatedBy
                )
                VALUES
                (
                    '11111111-1111-1111-1111-111111111111',
                    NULL,
                    NULL,
                    'HF-TEST-CLIENT',
                    'Integration',
                    'Clinic',
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    1,
                    0,
                    @Now,
                    'INTEGRATION_TEST',
                    @Now,
                    'INTEGRATION_TEST'
                );
            END

            UPDATE Profile.Clients
            SET IsActive = 1,
                IsDeleted = 0,
                UpdatedDate = @Now,
                UpdatedBy = 'INTEGRATION_TEST'
            WHERE ClientCode = 'HF-TEST-CLIENT';

            SELECT TOP (1) @ClientId = ClientId
            FROM Profile.Clients
            WHERE ClientCode = 'HF-TEST-CLIENT';

            IF NOT EXISTS (SELECT 1 FROM Profile.Patient WHERE ID_Number = '9001010000001')
            BEGIN
                INSERT INTO Profile.Patient
                (
                    PatientId,
                    FirstName,
                    LastName,
                    ID_Number,
                    DateOfBirth,
                    GenderIDFK,
                    MedicationList,
                    AddressIDFK,
                    MaritalStatusIDFK,
                    EmergencyIDFK,
                    IsDeleted,
                    CreatedDate,
                    CreatedBy,
                    UpdatedDate,
                    UpdatedBy,
                    ClientIdFK
                )
                VALUES
                (
                    '22222222-2222-2222-2222-222222222222',
                    'Integration',
                    'Patient',
                    '9001010000001',
                    '1990-01-01',
                    @GenderId,
                    NULL,
                    NULL,
                    @MaritalStatusId,
                    NULL,
                    0,
                    @Now,
                    'INTEGRATION_TEST',
                    @Now,
                    'INTEGRATION_TEST',
                    @ClientId
                );
            END

            SELECT TOP (1) @PatientId = PatientId
            FROM Profile.Patient
            WHERE ID_Number = '9001010000001';

            UPDATE Profile.Patient
            SET IsDeleted = 0,
                GenderIDFK = @GenderId,
                MaritalStatusIDFK = @MaritalStatusId,
                ClientIdFK = @ClientId,
                UpdatedDate = @Now,
                UpdatedBy = 'INTEGRATION_TEST'
            WHERE PatientId = @PatientId;

            IF NOT EXISTS
            (
                SELECT 1
                FROM Profile.PatientClients
                WHERE PatientIdFK = @PatientId
                  AND ClientIdFK = @ClientId
            )
            BEGIN
                INSERT INTO Profile.PatientClients
                (
                    PatientClientId,
                    PatientIdFK,
                    ClientIdFK,
                    IsPrimary,
                    CreatedDate,
                    CreatedBy,
                    UpdatedDate,
                    UpdatedBy
                )
                VALUES
                (
                    '55555555-5555-5555-5555-555555555555',
                    @PatientId,
                    @ClientId,
                    1,
                    @Now,
                    'INTEGRATION_TEST',
                    @Now,
                    'INTEGRATION_TEST'
                );
            END

            UPDATE Profile.PatientClients
            SET IsPrimary = 1,
                UpdatedDate = @Now,
                UpdatedBy = 'INTEGRATION_TEST'
            WHERE PatientIdFK = @PatientId
              AND ClientIdFK = @ClientId;

            IF NOT EXISTS (SELECT 1 FROM Profile.ClientStaff WHERE StaffCode = 'HF-TEST-STAFF')
            BEGIN
                INSERT INTO Profile.ClientStaff
                (
                    ClientStaffId,
                    ClientIdFK,
                    RoleIdFK,
                    UserIdFK,
                    ProviderIdFK,
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
                    UpdatedBy,
                    StaffDesignationIdFK,
                    PrimaryDepartmentIdFK
                )
                VALUES
                (
                    '66666666-6666-6666-6666-666666666666',
                    @ClientId,
                    @RoleId,
                    NULL,
                    @ProviderId,
                    'HF-TEST-STAFF',
                    'Integration',
                    'Doctor',
                    'integration.test.doctor@healthcareform.local',
                    '+27100000000',
                    'Medical Doctor',
                    'Clinical',
                    'Clinical',
                    'Full-Time',
                    @Now,
                    NULL,
                    0,
                    1,
                    0,
                    @Now,
                    'INTEGRATION_TEST',
                    @Now,
                    'INTEGRATION_TEST',
                    NULL,
                    NULL
                );
            END

            UPDATE Profile.ClientStaff
            SET ClientIdFK = @ClientId,
                RoleIdFK = @RoleId,
                ProviderIdFK = @ProviderId,
                IsActive = 1,
                IsDeleted = 0,
                UpdatedDate = @Now,
                UpdatedBy = 'INTEGRATION_TEST'
            WHERE StaffCode = 'HF-TEST-STAFF';

            SELECT TOP (1) @ClientStaffId = ClientStaffId
            FROM Profile.ClientStaff
            WHERE StaffCode = 'HF-TEST-STAFF';

            IF NOT EXISTS
            (
                SELECT 1
                FROM Profile.ClientProviderAffiliations
                WHERE ClientIdFK = @ClientId
                  AND ProviderIdFK = @ProviderId
                  AND IsActive = 1
                  AND EndDate IS NULL
            )
            BEGIN
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
                VALUES
                (
                    '77777777-7777-7777-7777-777777777777',
                    @ClientId,
                    @ProviderId,
                    @ClientStaffId,
                    NULL,
                    'Employee',
                    1,
                    1,
                    @Now,
                    NULL,
                    1,
                    'Integration test affiliation.',
                    @Now,
                    'INTEGRATION_TEST',
                    @Now,
                    'INTEGRATION_TEST'
                );
            END

            UPDATE Profile.ClientProviderAffiliations
            SET ClientStaffIdFK = @ClientStaffId,
                RelationshipType = 'Employee',
                CanBookAppointments = 1,
                CanReceiveReferrals = 1,
                StartDate = @Now,
                EndDate = NULL,
                IsActive = 1,
                UpdatedDate = @Now,
                UpdatedBy = 'INTEGRATION_TEST'
            WHERE ClientIdFK = @ClientId
              AND ProviderIdFK = @ProviderId
              AND IsActive = 1
              AND EndDate IS NULL;

            COMMIT TRANSACTION;
            """,
            connection);

        await command.ExecuteNonQueryAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;
}
