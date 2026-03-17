namespace HealthcareForm.Contracts.Clients;

public sealed class ClientStaffSnapshotDto
{
    public IReadOnlyList<ClientStaffDto> Staff { get; set; } = [];
    public int TotalRecords { get; set; }
}
