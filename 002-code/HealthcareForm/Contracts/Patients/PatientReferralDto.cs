namespace HealthcareForm.Contracts.Patients;

public sealed class PatientReferralDto
{
    public Guid ReferralId { get; init; }
    public Guid ReferringProviderId { get; init; }
    public string ReferringProviderName { get; init; } = string.Empty;
    public Guid? ReferredProviderId { get; init; }
    public string ReferredProviderName { get; init; } = string.Empty;
    public DateTime ReferralDate { get; init; }
    public string Reason { get; init; } = string.Empty;
    public string Priority { get; init; } = string.Empty;
    public string ReferralType { get; init; } = string.Empty;
    public string SpecializationNeeded { get; init; } = string.Empty;
    public string ReferralCode { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public DateTime? AcceptanceDate { get; init; }
    public DateTime? CompletionDate { get; init; }
    public string Notes { get; init; } = string.Empty;
    public DateTime? UpdatedDate { get; init; }
}
