namespace HealthcareForm.Contracts.Admin;

public sealed class AdminDbErrorDto
{
    public int ErrorId { get; init; }
    public string UserName { get; init; } = string.Empty;
    public string ErrorSchema { get; init; } = string.Empty;
    public string ErrorProcedure { get; init; } = string.Empty;
    public int? ErrorNumber { get; init; }
    public int? ErrorState { get; init; }
    public int? ErrorSeverity { get; init; }
    public int? ErrorLine { get; init; }
    public string ErrorMessage { get; init; } = string.Empty;
    public DateTime? ErrorDateTime { get; init; }
}
