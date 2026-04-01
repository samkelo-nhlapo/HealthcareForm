namespace HealthcareForm.Contracts.Admin;

// Database error row returned to the admin workspace.
public sealed class AdminDbErrorDto
{
    // Internal identifier for the stored error record.
    public int ErrorId { get; init; }

    // Database or application user associated with the error, when captured.
    public string UserName { get; init; } = string.Empty;

    // Database schema involved in the error.
    public string ErrorSchema { get; init; } = string.Empty;

    // Stored procedure or routine involved in the error.
    public string ErrorProcedure { get; init; } = string.Empty;

    // SQL Server error number, when available.
    public int? ErrorNumber { get; init; }

    // SQL Server state value, when available.
    public int? ErrorState { get; init; }

    // SQL Server severity value, when available.
    public int? ErrorSeverity { get; init; }

    // Line number reported by SQL Server, when available.
    public int? ErrorLine { get; init; }

    // Human-readable error message.
    public string ErrorMessage { get; init; } = string.Empty;

    // UTC timestamp for when the error was recorded, when available.
    public DateTime? ErrorDateTime { get; init; }
}
