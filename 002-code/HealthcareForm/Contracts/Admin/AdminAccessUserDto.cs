namespace HealthcareForm.Contracts.Admin;

// User row shown in the access-control snapshot.
public sealed class AdminAccessUserDto
{
    // Unique sign-in name for the user.
    public string Username { get; init; } = string.Empty;

    // Human-friendly full name assembled for the admin table.
    public string FullName { get; init; } = string.Empty;

    // Primary email address for the user.
    public string Email { get; init; } = string.Empty;

    // Roles currently assigned to the user.
    public IReadOnlyList<string> Roles { get; init; } = [];

    // Display status such as active, locked, or inactive.
    public string Status { get; init; } = string.Empty;

    // Human-readable MFA enrollment status.
    public string Mfa { get; init; } = string.Empty;

    // Last successful sign-in timestamp formatted for display, or "Never".
    public string LastLogin { get; init; } = string.Empty;
}
