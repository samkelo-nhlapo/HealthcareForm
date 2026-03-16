using System.Net;
using System.Text.Json;
using Xunit;

namespace HealthcareForm.Tests.Integration;

public sealed class StoredProcedureApiTests
{
    [Fact]
    public async Task PatientsWorklist_ReturnsArray()
    {
        await AssertJsonArrayAsync("/api/patients/worklist");
    }

    [Fact]
    public async Task Lookups_ReturnArrays()
    {
        await AssertJsonArrayAsync("/api/lookups/genders");
        await AssertJsonArrayAsync("/api/lookups/marital-statuses");
        await AssertJsonArrayAsync("/api/lookups/countries");
        await AssertJsonArrayAsync("/api/lookups/provinces");
        await AssertJsonArrayAsync("/api/lookups/cities");
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
}
