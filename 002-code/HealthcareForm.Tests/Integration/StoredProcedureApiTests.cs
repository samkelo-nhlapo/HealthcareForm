using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace HealthcareForm.Tests.Integration;

[Collection("Database integration")]
public sealed class StoredProcedureApiTests
{
    [Fact]
    public async Task PatientsWorklist_ReturnsArray()
    {
        await AssertJsonArrayAsync("/api/patients/worklist");
    }

    [Fact]
    public async Task PatientDirectory_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/patients/directory");
    }

    [Fact]
    public async Task Lookups_ReturnArrays()
    {
        await AssertJsonArrayAsync("/api/lookups/genders");
        await AssertJsonArrayAsync("/api/lookups/marital-statuses");
        await AssertJsonArrayAsync("/api/lookups/countries");
        await AssertJsonArrayAsync("/api/lookups/provinces");
        await AssertJsonArrayAsync("/api/lookups/cities");
        await AssertJsonArrayAsync("/api/lookups/allergies");
        await AssertJsonArrayAsync("/api/lookups/medications");
    }

    [Fact]
    public async Task OperationsScheduling_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/operations/scheduling");
    }

    [Fact]
    public async Task OperationsTaskQueue_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/operations/task-queue");
    }

    [Fact]
    public async Task OperationsSchedulingBookingOptions_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/operations/scheduling/booking-options");
    }

    [Fact]
    public async Task OperationsSchedulingAppointmentCreate_InvalidPayload_ReturnsBadRequest()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        using var factory = new TestApplicationFactory(connectionString);
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/operations/scheduling/appointments", new { });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task RevenueClaims_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/revenue/claims");
    }

    [Fact]
    public async Task AdminAccessControl_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/admin/access-control");
    }

    [Fact]
    public async Task AdminAuditLog_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/admin/audit-log");
    }

    [Fact]
    public async Task AdminDataGovernance_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/admin/data-governance");
    }

    [Fact]
    public async Task AdminDbErrors_ReturnsObject()
    {
        await AssertJsonObjectAsync("/api/admin/db-errors");
    }

    [Fact]
    public async Task ClientsDirectory_ReturnsExpectedPayloads()
    {
        await AssertJsonArrayAsync("/api/clients/clinic-categories");
        await AssertJsonObjectAsync("/api/clients");
        await AssertJsonObjectAsync("/api/clients/departments");
        await AssertJsonObjectAsync("/api/clients/staff");
    }

    [Fact]
    public async Task ClientDetail_ReturnsObject_WhenAClientExists()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        using var factory = new TestApplicationFactory(connectionString);
        using var client = factory.CreateClient();

        var clientId = await TryGetAnyClientIdAsync(client);
        if (string.IsNullOrWhiteSpace(clientId))
        {
            return;
        }

        var response = await client.GetAsync($"/api/clients/{clientId}?includeDeleted=true");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var payload = await response.Content.ReadAsStringAsync();
        Assert.True(IsJsonObject(payload), "Expected JSON object payload for /api/clients/{clientId}.");
    }

    [Fact]
    public async Task PatientClinicalHistory_ReturnsArrays()
    {
        const string idNumber = "0000000000000";

        await AssertJsonArrayAsync($"/api/patients/{idNumber}/allergies");
        await AssertJsonArrayAsync($"/api/patients/{idNumber}/medications");
        await AssertJsonObjectAsync($"/api/patients/{idNumber}/orders-results");
        await AssertJsonArrayAsync($"/api/patients/{idNumber}/vaccinations");
        await AssertJsonArrayAsync($"/api/patients/{idNumber}/consultation-notes");
        await AssertJsonArrayAsync($"/api/patients/{idNumber}/referrals");
    }

    [Fact]
    public async Task FormSubmissions_ReturnArrays()
    {
        const string submissionId = "11111111-1111-1111-1111-111111111111";

        await AssertJsonArrayAsync($"/api/forms/submissions/{submissionId}/fields");
        await AssertJsonArrayAsync($"/api/forms/submissions/{submissionId}/attachments");
    }

    private static async Task AssertJsonArrayAsync(string path)
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        using var factory = new TestApplicationFactory(connectionString);
        using var client = factory.CreateClient();
        {
            var response = await client.GetAsync(path);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var payload = await response.Content.ReadAsStringAsync();
            Assert.True(IsJsonArray(payload), $"Expected JSON array payload for {path}.");
        }
    }

    private static async Task AssertJsonObjectAsync(string path)
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        using var factory = new TestApplicationFactory(connectionString);
        using var client = factory.CreateClient();
        {
            var response = await client.GetAsync(path);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var payload = await response.Content.ReadAsStringAsync();
            Assert.True(IsJsonObject(payload), $"Expected JSON object payload for {path}.");
        }
    }

    private static bool IsJsonArray(string payload)
    {
        if (string.IsNullOrWhiteSpace(payload))
        {
            return false;
        }

        try
        {
            using var document = JsonDocument.Parse(payload);
            return document.RootElement.ValueKind == JsonValueKind.Array;
        }
        catch (JsonException)
        {
            return false;
        }
    }

    private static bool IsJsonObject(string payload)
    {
        if (string.IsNullOrWhiteSpace(payload))
        {
            return false;
        }

        try
        {
            using var document = JsonDocument.Parse(payload);
            return document.RootElement.ValueKind == JsonValueKind.Object;
        }
        catch (JsonException)
        {
            return false;
        }
    }

    private static async Task<string?> TryGetAnyClientIdAsync(HttpClient client)
    {
        var response = await client.GetAsync("/api/clients?PageSize=1");
        if (response.StatusCode != HttpStatusCode.OK)
        {
            return null;
        }

        var payload = await response.Content.ReadAsStringAsync();
        if (string.IsNullOrWhiteSpace(payload))
        {
            return null;
        }

        try
        {
            using var document = JsonDocument.Parse(payload);
            if (!document.RootElement.TryGetProperty("Clients", out var clients)
                || clients.ValueKind != JsonValueKind.Array
                || clients.GetArrayLength() == 0)
            {
                return null;
            }

            var first = clients[0];
            if (!first.TryGetProperty("ClientId", out var clientId))
            {
                return null;
            }

            return clientId.GetString();
        }
        catch (JsonException)
        {
            return null;
        }
    }
}
