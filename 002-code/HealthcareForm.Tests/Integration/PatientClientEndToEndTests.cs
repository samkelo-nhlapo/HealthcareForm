using HealthcareForm.Contracts.Clients;
using HealthcareForm.Contracts.Patients;
using System.Data.SqlClient;
using System.Net;
using System.Net.Http.Json;
using System.Threading;

namespace HealthcareForm.Tests.Integration;

public sealed class PatientClientEndToEndTests
{
    private static long _idSeed = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

    [Fact]
    public async Task ClientRegistration_CreatesClient_AndShowsInDirectory()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        var clientCode = $"E2E-CLI-{Guid.NewGuid():N}"[..16];

        try
        {
            using var factory = new TestApplicationFactory(connectionString);
            using var client = factory.CreateClient();

            var createResponse = await client.PostAsJsonAsync("/api/clients", new ClientCreateRequest
            {
                ClientCode = clientCode,
                FirstName = "EndToEnd",
                LastName = "Clinic"
            });

            Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
            var createPayload = await createResponse.Content.ReadFromJsonAsync<ClientCommandResult>();
            Assert.NotNull(createPayload);
            Assert.True(createPayload!.Success);
            Assert.True(createPayload.ClientId.HasValue);

            var directoryResponse = await client.GetAsync($"/api/clients?SearchTerm={Uri.EscapeDataString(clientCode)}&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, directoryResponse.StatusCode);

            var directoryPayload = await directoryResponse.Content.ReadFromJsonAsync<ClientDirectorySnapshotDto>();
            Assert.NotNull(directoryPayload);
            var registeredClient = Assert.Single(directoryPayload!.Clients, (item) => item.ClientCode == clientCode);
            Assert.Equal(0, registeredClient.RegisteredPatientCount);
            Assert.Equal(0, registeredClient.ActivePatientCount);
        }
        finally
        {
            await CleanupClientsAsync(connectionString, [clientCode]);
        }
    }

    [Fact]
    public async Task PatientRegistration_CreatesPatient_WithMultipleClients()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        var primaryClientCode = $"E2E-CP-{Guid.NewGuid():N}"[..16];
        var secondaryClientCode = $"E2E-CS-{Guid.NewGuid():N}"[..16];
        var patientIdNumber = NextSouthAfricanStyleIdNumber();
        var patientPhone = NextPhoneNumber();
        var emergencyPhone = NextPhoneNumber();

        try
        {
            using var factory = new TestApplicationFactory(connectionString);
            using var client = factory.CreateClient();

            var primaryClientId = await CreateClientAsync(client, primaryClientCode, "Primary", "Clinic");
            var secondaryClientId = await CreateClientAsync(client, secondaryClientCode, "Secondary", "Hospital");
            var referenceData = await LoadReferenceDataAsync(connectionString);

            var createPatientResponse = await client.PostAsJsonAsync("/api/patients", new PatientCreateRequest
            {
                PrimaryClientId = primaryClientId,
                SecondaryClientIds = [secondaryClientId],
                FirstName = "E2E",
                LastName = "Patient",
                IdNumber = patientIdNumber,
                DateOfBirth = new DateTime(1990, 1, 1),
                GenderId = referenceData.GenderId,
                PhoneNumber = patientPhone,
                Email = $"{patientIdNumber}@healthcareform.local",
                Line1 = "1 Integration Street",
                Line2 = "Suite 2",
                CityId = referenceData.CityId,
                ProvinceId = referenceData.ProvinceId,
                CountryId = referenceData.CountryId,
                MaritalStatusId = referenceData.MaritalStatusId,
                EmergencyName = "Casey",
                EmergencyLastName = "Contact",
                EmergencyPhoneNumber = emergencyPhone,
                Relationship = "Sibling",
                EmergencyDateOfBirth = new DateTime(1988, 1, 1),
                MedicationList = "Vitamin D"
            });

            Assert.Equal(HttpStatusCode.Created, createPatientResponse.StatusCode);
            var createPatientPayload = await createPatientResponse.Content.ReadFromJsonAsync<PatientCommandResult>();
            Assert.NotNull(createPatientPayload);
            Assert.True(createPatientPayload!.Success);
            Assert.True(createPatientPayload.PatientId.HasValue);

            var getPatientResponse = await client.GetAsync($"/api/patients/{patientIdNumber}");
            Assert.Equal(HttpStatusCode.OK, getPatientResponse.StatusCode);

            var patientPayload = await getPatientResponse.Content.ReadFromJsonAsync<PatientRecordDto>();
            Assert.NotNull(patientPayload);
            Assert.Equal(primaryClientId, patientPayload!.ClientId);
            Assert.Equal(2, patientPayload.Clients.Count);
            Assert.Contains(patientPayload.Clients, (linkedClient) => linkedClient.ClientId == primaryClientId && linkedClient.IsPrimary);
            Assert.Contains(patientPayload.Clients, (linkedClient) => linkedClient.ClientId == secondaryClientId && !linkedClient.IsPrimary);
        }
        finally
        {
            await CleanupPatientAsync(connectionString, patientIdNumber);
            await CleanupClientsAsync(connectionString, [primaryClientCode, secondaryClientCode]);
        }
    }

    [Fact]
    public async Task PatientDirectory_FiltersBySecondaryClientMembership()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        var primaryClientCode = $"E2E-DP-{Guid.NewGuid():N}"[..16];
        var secondaryClientCode = $"E2E-DS-{Guid.NewGuid():N}"[..16];
        var patientIdNumber = NextSouthAfricanStyleIdNumber();
        var patientPhone = NextPhoneNumber();
        var emergencyPhone = NextPhoneNumber();

        try
        {
            using var factory = new TestApplicationFactory(connectionString);
            using var client = factory.CreateClient();

            var primaryClientId = await CreateClientAsync(client, primaryClientCode, "Directory", "Primary");
            var secondaryClientId = await CreateClientAsync(client, secondaryClientCode, "Directory", "Secondary");
            var referenceData = await LoadReferenceDataAsync(connectionString);

            var createPatientResponse = await client.PostAsJsonAsync("/api/patients", new PatientCreateRequest
            {
                PrimaryClientId = primaryClientId,
                SecondaryClientIds = [secondaryClientId],
                FirstName = "Directory",
                LastName = "Patient",
                IdNumber = patientIdNumber,
                DateOfBirth = new DateTime(1992, 2, 2),
                GenderId = referenceData.GenderId,
                PhoneNumber = patientPhone,
                Email = $"{patientIdNumber}@directory.healthcareform.local",
                Line1 = "2 Directory Avenue",
                Line2 = "Block B",
                CityId = referenceData.CityId,
                ProvinceId = referenceData.ProvinceId,
                CountryId = referenceData.CountryId,
                MaritalStatusId = referenceData.MaritalStatusId,
                EmergencyName = "Jordan",
                EmergencyLastName = "Alert",
                EmergencyPhoneNumber = emergencyPhone,
                Relationship = "Parent",
                EmergencyDateOfBirth = new DateTime(1970, 5, 5),
                MedicationList = "None"
            });

            Assert.Equal(HttpStatusCode.Created, createPatientResponse.StatusCode);

            var directoryResponse = await client.GetAsync($"/api/patients/directory?ClientId={secondaryClientId}&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, directoryResponse.StatusCode);

            var directoryPayload = await directoryResponse.Content.ReadFromJsonAsync<PatientDirectorySnapshotDto>();
            Assert.NotNull(directoryPayload);
            var patientRow = Assert.Single(directoryPayload!.Patients, (item) => item.IdNumber == patientIdNumber);
            Assert.Equal(primaryClientId, patientRow.ClientId);
            Assert.Equal(2, patientRow.Clients.Count);
            Assert.Contains(patientRow.Clients, (linkedClient) => linkedClient.ClientId == secondaryClientId && !linkedClient.IsPrimary);
        }
        finally
        {
            await CleanupPatientAsync(connectionString, patientIdNumber);
            await CleanupClientsAsync(connectionString, [primaryClientCode, secondaryClientCode]);
        }
    }

    [Fact]
    public async Task PatientUpdate_Search_Delete_WorksEndToEnd()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        var primaryClientCode = $"E2E-PU-{Guid.NewGuid():N}"[..16];
        var secondaryClientCode = $"E2E-PS-{Guid.NewGuid():N}"[..16];
        var replacementClientCode = $"E2E-PR-{Guid.NewGuid():N}"[..16];
        var patientIdNumber = NextSouthAfricanStyleIdNumber();
        var patientPhone = NextPhoneNumber();
        var emergencyPhone = NextPhoneNumber();
        var updatedPhone = NextPhoneNumber();
        var updatedEmergencyPhone = NextPhoneNumber();

        try
        {
            using var factory = new TestApplicationFactory(connectionString);
            using var client = factory.CreateClient();

            var primaryClientId = await CreateClientAsync(client, primaryClientCode, "Patient", "Primary");
            var secondaryClientId = await CreateClientAsync(client, secondaryClientCode, "Patient", "Secondary");
            var replacementClientId = await CreateClientAsync(client, replacementClientCode, "Patient", "Replacement");
            var referenceData = await LoadReferenceDataAsync(connectionString);

            var createPatientResponse = await client.PostAsJsonAsync("/api/patients", new PatientCreateRequest
            {
                PrimaryClientId = primaryClientId,
                SecondaryClientIds = [secondaryClientId],
                FirstName = "Update",
                LastName = "Before",
                IdNumber = patientIdNumber,
                DateOfBirth = new DateTime(1991, 1, 1),
                GenderId = referenceData.GenderId,
                PhoneNumber = patientPhone,
                Email = $"{patientIdNumber}@patient-update.healthcareform.local",
                Line1 = "10 Start Street",
                Line2 = "Floor 1",
                CityId = referenceData.CityId,
                ProvinceId = referenceData.ProvinceId,
                CountryId = referenceData.CountryId,
                MaritalStatusId = referenceData.MaritalStatusId,
                EmergencyName = "Start",
                EmergencyLastName = "Contact",
                EmergencyPhoneNumber = emergencyPhone,
                Relationship = "Sibling",
                EmergencyDateOfBirth = new DateTime(1985, 5, 5),
                MedicationList = "Medication A"
            });

            Assert.Equal(HttpStatusCode.Created, createPatientResponse.StatusCode);

            var updateResponse = await client.PutAsJsonAsync($"/api/patients/{patientIdNumber}", new PatientUpdateRequest
            {
                PrimaryClientId = replacementClientId,
                SecondaryClientIds = [primaryClientId],
                FirstName = "Update",
                LastName = "After",
                DateOfBirth = new DateTime(1991, 1, 1),
                GenderId = referenceData.GenderId,
                PhoneNumber = updatedPhone,
                Email = $"{patientIdNumber}@patient-updated.healthcareform.local",
                Line1 = "22 Updated Street",
                Line2 = "Ward B",
                CityId = referenceData.CityId,
                ProvinceId = referenceData.ProvinceId,
                CountryId = referenceData.CountryId,
                MaritalStatusId = referenceData.MaritalStatusId,
                EmergencyName = "Updated",
                EmergencyLastName = "Contact",
                EmergencyPhoneNumber = updatedEmergencyPhone,
                Relationship = "Parent",
                EmergencyDateOfBirth = new DateTime(1984, 4, 4),
                MedicationList = "Medication B"
            });

            Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
            var updatePayload = await updateResponse.Content.ReadFromJsonAsync<PatientCommandResult>();
            Assert.NotNull(updatePayload);
            Assert.True(updatePayload!.Success);

            var getPatientResponse = await client.GetAsync($"/api/patients/{patientIdNumber}");
            Assert.Equal(HttpStatusCode.OK, getPatientResponse.StatusCode);

            var patientPayload = await getPatientResponse.Content.ReadFromJsonAsync<PatientRecordDto>();
            Assert.NotNull(patientPayload);
            Assert.Equal("After", patientPayload!.LastName);
            Assert.Equal(FormatPhoneNumber(updatedPhone), patientPayload.PhoneNumber);
            Assert.Equal("Medication B", patientPayload.MedicationList);
            Assert.Equal(replacementClientId, patientPayload.ClientId);
            Assert.Contains(patientPayload.Clients, assignment => assignment.ClientId == replacementClientId && assignment.IsPrimary);
            Assert.Contains(patientPayload.Clients, assignment => assignment.ClientId == primaryClientId && !assignment.IsPrimary);
            Assert.DoesNotContain(patientPayload.Clients, assignment => assignment.ClientId == secondaryClientId);

            var directoryResponse = await client.GetAsync($"/api/patients/directory?SearchTerm={Uri.EscapeDataString(patientIdNumber)}&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, directoryResponse.StatusCode);

            var directoryPayload = await directoryResponse.Content.ReadFromJsonAsync<PatientDirectorySnapshotDto>();
            Assert.NotNull(directoryPayload);
            var patientRow = Assert.Single(directoryPayload!.Patients, item => item.IdNumber == patientIdNumber);
            Assert.Equal("After", patientRow.LastName);
            Assert.Equal(replacementClientId, patientRow.ClientId);

            var deleteResponse = await client.DeleteAsync($"/api/patients/{patientIdNumber}");
            Assert.Equal(HttpStatusCode.OK, deleteResponse.StatusCode);
            var deletePayload = await deleteResponse.Content.ReadFromJsonAsync<PatientCommandResult>();
            Assert.NotNull(deletePayload);
            Assert.True(deletePayload!.Success);

            var deletedPatientLookup = await client.GetAsync($"/api/patients/{patientIdNumber}");
            Assert.Equal(HttpStatusCode.NotFound, deletedPatientLookup.StatusCode);

            var activeDirectoryAfterDelete = await client.GetAsync($"/api/patients/directory?SearchTerm={Uri.EscapeDataString(patientIdNumber)}&IsDeleted=false&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, activeDirectoryAfterDelete.StatusCode);
            var activeDirectoryPayload = await activeDirectoryAfterDelete.Content.ReadFromJsonAsync<PatientDirectorySnapshotDto>();
            Assert.NotNull(activeDirectoryPayload);
            Assert.DoesNotContain(activeDirectoryPayload!.Patients, item => item.IdNumber == patientIdNumber);

            var archivedDirectoryAfterDelete = await client.GetAsync($"/api/patients/directory?SearchTerm={Uri.EscapeDataString(patientIdNumber)}&IsDeleted=true&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, archivedDirectoryAfterDelete.StatusCode);
            var archivedDirectoryPayload = await archivedDirectoryAfterDelete.Content.ReadFromJsonAsync<PatientDirectorySnapshotDto>();
            Assert.NotNull(archivedDirectoryPayload);
            var archivedPatient = Assert.Single(archivedDirectoryPayload!.Patients, item => item.IdNumber == patientIdNumber);
            Assert.True(archivedPatient.IsDeleted);
        }
        finally
        {
            await CleanupPatientAsync(connectionString, patientIdNumber);
            await CleanupClientsAsync(connectionString, [primaryClientCode, secondaryClientCode, replacementClientCode]);
        }
    }

    [Fact]
    public async Task ClientUpdate_Search_Delete_WorksEndToEnd()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        var clientCode = $"E2E-CU-{Guid.NewGuid():N}"[..16];
        var updatedClientCode = $"E2E-CX-{Guid.NewGuid():N}"[..16];

        try
        {
            using var factory = new TestApplicationFactory(connectionString);
            using var client = factory.CreateClient();

            var createResponse = await client.PostAsJsonAsync("/api/clients", new ClientCreateRequest
            {
                ClientCode = clientCode,
                FirstName = "Original",
                LastName = "Clinic"
            });

            Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
            var createPayload = await createResponse.Content.ReadFromJsonAsync<ClientCommandResult>();
            Assert.NotNull(createPayload);
            Assert.True(createPayload!.Success);
            Assert.True(createPayload.ClientId.HasValue);
            var clientId = createPayload.ClientId.Value;

            var initialSearchResponse = await client.GetAsync($"/api/clients?SearchTerm={Uri.EscapeDataString(clientCode)}&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, initialSearchResponse.StatusCode);
            var initialSearchPayload = await initialSearchResponse.Content.ReadFromJsonAsync<ClientDirectorySnapshotDto>();
            Assert.NotNull(initialSearchPayload);
            var createdClient = Assert.Single(initialSearchPayload!.Clients, item => item.ClientCode == clientCode);
            Assert.Equal("Original", createdClient.FirstName);

            var updateResponse = await client.PutAsJsonAsync($"/api/clients/{clientId}", new ClientUpdateRequest
            {
                ClientCode = updatedClientCode,
                FirstName = "Updated",
                LastName = "Hospital",
                Email = "updated.client@healthcareform.local",
                PhoneNumber = "0123456789",
                IsActive = true
            });

            Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
            var updatePayload = await updateResponse.Content.ReadFromJsonAsync<ClientCommandResult>();
            Assert.NotNull(updatePayload);
            Assert.True(updatePayload!.Success);

            var getClientResponse = await client.GetAsync($"/api/clients/{clientId}?includeDeleted=true");
            Assert.Equal(HttpStatusCode.OK, getClientResponse.StatusCode);
            var clientPayload = await getClientResponse.Content.ReadFromJsonAsync<ClientRecordDto>();
            Assert.NotNull(clientPayload);
            Assert.Equal(updatedClientCode, clientPayload!.ClientCode);
            Assert.Equal("Updated", clientPayload.FirstName);
            Assert.Equal("Hospital", clientPayload.LastName);
            Assert.Equal("updated.client@healthcareform.local", clientPayload.Email);
            Assert.Equal("012-345-6789", clientPayload.PhoneNumber);
            Assert.False(clientPayload.IsDeleted);

            var updatedSearchResponse = await client.GetAsync($"/api/clients?SearchTerm={Uri.EscapeDataString(updatedClientCode)}&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, updatedSearchResponse.StatusCode);
            var updatedSearchPayload = await updatedSearchResponse.Content.ReadFromJsonAsync<ClientDirectorySnapshotDto>();
            Assert.NotNull(updatedSearchPayload);
            var updatedClient = Assert.Single(updatedSearchPayload!.Clients, item => item.ClientCode == updatedClientCode);
            Assert.Equal(clientId, updatedClient.ClientId);

            var deleteResponse = await client.DeleteAsync($"/api/clients/{clientId}");
            Assert.Equal(HttpStatusCode.OK, deleteResponse.StatusCode);
            var deletePayload = await deleteResponse.Content.ReadFromJsonAsync<ClientCommandResult>();
            Assert.NotNull(deletePayload);
            Assert.True(deletePayload!.Success);

            var activeLookupAfterDelete = await client.GetAsync($"/api/clients/{clientId}?includeDeleted=false");
            Assert.Equal(HttpStatusCode.NotFound, activeLookupAfterDelete.StatusCode);

            var deletedLookupResponse = await client.GetAsync($"/api/clients/{clientId}?includeDeleted=true");
            Assert.Equal(HttpStatusCode.OK, deletedLookupResponse.StatusCode);
            var deletedClient = await deletedLookupResponse.Content.ReadFromJsonAsync<ClientRecordDto>();
            Assert.NotNull(deletedClient);
            Assert.True(deletedClient!.IsDeleted);

            var activeSearchAfterDelete = await client.GetAsync($"/api/clients?SearchTerm={Uri.EscapeDataString(updatedClientCode)}&IsDeleted=false&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, activeSearchAfterDelete.StatusCode);
            var activeSearchPayload = await activeSearchAfterDelete.Content.ReadFromJsonAsync<ClientDirectorySnapshotDto>();
            Assert.NotNull(activeSearchPayload);
            Assert.DoesNotContain(activeSearchPayload!.Clients, item => item.ClientId == clientId);

            var deletedSearchResponse = await client.GetAsync($"/api/clients?SearchTerm={Uri.EscapeDataString(updatedClientCode)}&IsDeleted=true&PageSize=25");
            Assert.Equal(HttpStatusCode.OK, deletedSearchResponse.StatusCode);
            var deletedSearchPayload = await deletedSearchResponse.Content.ReadFromJsonAsync<ClientDirectorySnapshotDto>();
            Assert.NotNull(deletedSearchPayload);
            var deletedSearchClient = Assert.Single(deletedSearchPayload!.Clients, item => item.ClientId == clientId);
            Assert.True(deletedSearchClient.IsDeleted);
        }
        finally
        {
            await CleanupClientsAsync(connectionString, [clientCode, updatedClientCode]);
        }
    }

    private static async Task<Guid> CreateClientAsync(
        HttpClient httpClient,
        string clientCode,
        string firstName,
        string lastName)
    {
        var response = await httpClient.PostAsJsonAsync("/api/clients", new ClientCreateRequest
        {
            ClientCode = clientCode,
            FirstName = firstName,
            LastName = lastName
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var payload = await response.Content.ReadFromJsonAsync<ClientCommandResult>();
        Assert.NotNull(payload);
        Assert.True(payload!.Success);
        Assert.True(payload.ClientId.HasValue);
        return payload.ClientId!.Value;
    }

    private static async Task<ReferenceData> LoadReferenceDataAsync(string connectionString)
    {
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            """
            SELECT TOP (1)
                G.GenderId,
                M.MaritalStatusId,
                C.CityId,
                P.ProvinceId,
                CO.CountryId
            FROM Profile.Gender G
            CROSS JOIN Profile.MaritalStatus M
            CROSS JOIN Location.Cities C
            INNER JOIN Location.Provinces P ON P.ProvinceId = C.ProvinceIDFK
            INNER JOIN Location.Countries CO ON CO.CountryId = P.CountryIDFK
            ORDER BY G.GenderId, M.MaritalStatusId, C.CityId;
            """,
            connection);

        await using var reader = await command.ExecuteReaderAsync();
        Assert.True(await reader.ReadAsync(), "Expected reference data for gender, marital status, city, province, and country.");

        return new ReferenceData(
            reader.GetInt32(reader.GetOrdinal("GenderId")),
            reader.GetInt32(reader.GetOrdinal("MaritalStatusId")),
            reader.GetInt32(reader.GetOrdinal("CityId")),
            reader.GetInt32(reader.GetOrdinal("ProvinceId")),
            reader.GetInt32(reader.GetOrdinal("CountryId")));
    }

    private static async Task CleanupPatientAsync(string connectionString, string idNumber)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return;
        }

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            """
            DECLARE @PatientId UNIQUEIDENTIFIER;
            DECLARE @AddressId UNIQUEIDENTIFIER;
            DECLARE @EmergencyId UNIQUEIDENTIFIER;

            SELECT
                @PatientId = PatientId,
                @AddressId = AddressIDFK,
                @EmergencyId = EmergencyIDFK
            FROM Profile.Patient
            WHERE ID_Number = @IDNumber;

            IF @PatientId IS NULL
                RETURN;

            DECLARE @EmailIds TABLE (EmailId UNIQUEIDENTIFIER PRIMARY KEY);
            DECLARE @PhoneIds TABLE (PhoneId UNIQUEIDENTIFIER PRIMARY KEY);

            INSERT INTO @EmailIds (EmailId)
            SELECT DISTINCT EmailIdFK
            FROM Contacts.PatientEmails
            WHERE PatientIdFK = @PatientId;

            INSERT INTO @PhoneIds (PhoneId)
            SELECT DISTINCT PhoneIdFK
            FROM Contacts.PatientPhones
            WHERE PatientIdFK = @PatientId;

            UPDATE Profile.Patient
            SET IsDeleted = 1,
                ClientIdFK = NULL,
                AddressIDFK = NULL,
                EmergencyIDFK = NULL,
                UpdatedDate = GETDATE(),
                UpdatedBy = 'E2E'
            WHERE PatientId = @PatientId;

            DELETE FROM Profile.PatientClients WHERE PatientIdFK = @PatientId;
            DELETE FROM Contacts.PatientEmails WHERE PatientIdFK = @PatientId;
            DELETE FROM Contacts.PatientPhones WHERE PatientIdFK = @PatientId;

            IF @EmergencyId IS NOT NULL
                DELETE FROM Contacts.EmergencyContacts WHERE EmergencyId = @EmergencyId;

            IF @AddressId IS NOT NULL
                DELETE FROM Location.Address WHERE AddressId = @AddressId;

            DELETE E
            FROM Contacts.Emails E
            INNER JOIN @EmailIds EmailIds ON EmailIds.EmailId = E.EmailId;

            DELETE P
            FROM Contacts.Phones P
            INNER JOIN @PhoneIds PhoneIds ON PhoneIds.PhoneId = P.PhoneId;
            """,
            connection);

        command.Parameters.AddWithValue("@IDNumber", idNumber);
        await command.ExecuteNonQueryAsync();
    }

    private static async Task CleanupClientsAsync(string connectionString, IReadOnlyList<string> clientCodes)
    {
        var codes = clientCodes
            .Where((code) => !string.IsNullOrWhiteSpace(code))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (codes.Length == 0)
        {
            return;
        }

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        var parameterNames = codes.Select((_, index) => $"@ClientCode{index}").ToArray();
        await using var command = new SqlCommand(
            $"""
            DELETE FROM Profile.PatientClients
            WHERE ClientIdFK IN
            (
                SELECT ClientId
                FROM Profile.Clients
                WHERE ClientCode IN ({string.Join(", ", parameterNames)})
            );

            DELETE FROM Profile.Clients
            WHERE ClientCode IN ({string.Join(", ", parameterNames)});
            """,
            connection);

        for (var index = 0; index < codes.Length; index += 1)
        {
            command.Parameters.AddWithValue(parameterNames[index], codes[index]);
        }

        await command.ExecuteNonQueryAsync();
    }

    private static string NextSouthAfricanStyleIdNumber()
        => Interlocked.Increment(ref _idSeed).ToString("0000000000000");

    private static string NextPhoneNumber()
        => (Interlocked.Increment(ref _idSeed) % 1_000_000_000L + 1_000_000_000L).ToString("0000000000");

    private static string FormatPhoneNumber(string phoneNumber)
        => $"{phoneNumber[..3]}-{phoneNumber[3..6]}-{phoneNumber[6..]}";

    private sealed record ReferenceData(
        int GenderId,
        int MaritalStatusId,
        int CityId,
        int ProvinceId,
        int CountryId);
}
