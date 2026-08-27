namespace HealthcareForm.Tests.Integration;

[CollectionDefinition("Database integration", DisableParallelization = true)]
public sealed class IntegrationDatabaseCollection : ICollectionFixture<IntegrationDatabaseFixture>
{
}
