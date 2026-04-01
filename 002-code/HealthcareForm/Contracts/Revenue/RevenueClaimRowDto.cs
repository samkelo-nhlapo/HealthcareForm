namespace HealthcareForm.Contracts.Revenue;

// Claim row shown in the revenue claims snapshot.
public sealed class RevenueClaimRowDto
{
    // Human-readable claim or invoice identifier.
    public string ClaimId { get; init; } = string.Empty;

    // Patient name associated with the claim.
    public string Patient { get; init; } = string.Empty;

    // National ID number associated with the patient.
    public string IdNumber { get; init; } = string.Empty;

    // Payer or billing counterparty.
    public string Payer { get; init; } = string.Empty;

    // Service date formatted for display.
    public string ServiceDate { get; init; } = string.Empty;

    // Total claim amount.
    public decimal Amount { get; init; }

    // Amount currently treated as paid.
    public decimal PaidAmount { get; init; }

    // Coding workflow state shown to billing staff.
    public string CodingStatus { get; init; } = "Uncoded";

    // Claim lifecycle state shown to billing staff.
    public string ClaimStatus { get; init; } = "Ready to Submit";

    // Denial reason shown only when the claim is denied.
    public string DenialReason { get; init; } = string.Empty;

    // Number of days since the claim opened.
    public int DaysOpen { get; init; }

    // Last update timestamp formatted for display.
    public string LastUpdated { get; init; } = string.Empty;
}
