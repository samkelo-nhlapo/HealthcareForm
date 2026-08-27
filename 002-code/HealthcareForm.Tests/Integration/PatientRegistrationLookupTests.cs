using HealthcareForm.Contracts.Lookups;
using HealthcareForm.Contracts.Patients;
using System.Net;
using System.Net.Http.Json;

namespace HealthcareForm.Tests.Integration;

public sealed class PatientRegistrationLookupTests
{
    [Fact]
    public async Task PatientRegistrationDropdownLookups_ReturnExpectedOptions()
    {
        if (!TestEnvironment.TryGetConnectionString(out var connectionString))
        {
            return;
        }

        using var factory = new TestApplicationFactory(connectionString);
        using var client = factory.CreateClient();

        var genders = await GetRequiredLookupAsync<LookupOptionDto[]>(client, "/api/lookups/genders");
        var maritalStatuses = await GetRequiredLookupAsync<LookupOptionDto[]>(client, "/api/lookups/marital-statuses");
        var countries = await GetRequiredLookupAsync<LookupOptionDto[]>(client, "/api/lookups/countries");
        var provinces = await GetRequiredLookupAsync<LookupOptionDto[]>(client, "/api/lookups/provinces");
        var cities = await GetRequiredLookupAsync<LookupOptionDto[]>(client, "/api/lookups/cities");
        var patientClients = await GetRequiredLookupAsync<PatientClientLookupItemDto[]>(client, "/api/patients/client-lookup");

        Assert.NotEmpty(genders);
        Assert.NotEmpty(maritalStatuses);
        Assert.NotEmpty(countries);
        Assert.NotEmpty(provinces);
        Assert.NotEmpty(cities);
        Assert.NotEmpty(patientClients);

        Assert.All(genders, option => Assert.True(option.Id > 0 && !string.IsNullOrWhiteSpace(option.Name)));
        Assert.All(maritalStatuses, option => Assert.True(option.Id > 0 && !string.IsNullOrWhiteSpace(option.Name)));
        Assert.All(countries, option => Assert.True(option.Id > 0 && !string.IsNullOrWhiteSpace(option.Name)));
        Assert.All(provinces, option => Assert.True(option.Id > 0 && !string.IsNullOrWhiteSpace(option.Name)));
        Assert.All(cities, option => Assert.True(option.Id > 0 && !string.IsNullOrWhiteSpace(option.Name)));
        Assert.All(patientClients, option =>
        {
            Assert.NotEqual(Guid.Empty, option.ClientId);
            Assert.False(string.IsNullOrWhiteSpace(option.ClientName));
        });
    }

    private static async Task<T> GetRequiredLookupAsync<T>(HttpClient client, string path)
    {
        var response = await client.GetAsync(path);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var payload = await response.Content.ReadFromJsonAsync<T>();
        Assert.NotNull(payload);
        return payload!;
    }
}
