using System;

namespace HealthcareForm.Tests.Integration;

internal static class TestEnvironment
{
    internal static bool TryGetConnectionString(out string connectionString)
    {
        connectionString = Environment.GetEnvironmentVariable("HF_TEST_DB_CONNECTION")
            ?? Environment.GetEnvironmentVariable("ConnectionStrings__HealthcareEntity")
            ?? string.Empty;

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return false;
        }

        if (connectionString.StartsWith("__SET_", StringComparison.OrdinalIgnoreCase)
            || connectionString.Contains("REPLACE_WITH_", StringComparison.OrdinalIgnoreCase)
            || connectionString.Contains("<password>", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return true;
    }
}
