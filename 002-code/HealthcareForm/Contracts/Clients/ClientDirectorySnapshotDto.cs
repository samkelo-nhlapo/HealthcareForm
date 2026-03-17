namespace HealthcareForm.Contracts.Clients;

public sealed class ClientDirectorySnapshotDto
{
    public IReadOnlyList<ClientDirectoryItemDto> Clients { get; set; } = [];
    public int TotalRecords { get; set; }
}
