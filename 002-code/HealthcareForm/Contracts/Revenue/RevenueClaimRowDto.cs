namespace HealthcareForm.Contracts.Revenue;

public sealed class RevenueClaimRowDto
{
    public string ClaimId { get; init; } = string.Empty;
    public string Patient { get; init; } = string.Empty;
    public string IdNumber { get; init; } = string.Empty;
    public string Payer { get; init; } = string.Empty;
    public string ServiceDate { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public decimal PaidAmount { get; init; }
    public string CodingStatus { get; init; } = "Uncoded";
    public string ClaimStatus { get; init; } = "Ready to Submit";
    public string DenialReason { get; init; } = string.Empty;
    public int DaysOpen { get; init; }
    public string LastUpdated { get; init; } = string.Empty;
}
