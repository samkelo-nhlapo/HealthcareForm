namespace HealthcareForm.Contracts.Clients;

public sealed class ClientDepartmentSnapshotDto
{
    public IReadOnlyList<ClientDepartmentDto> Departments { get; set; } = [];
    public int TotalRecords { get; set; }
}
