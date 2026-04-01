namespace HealthcareForm.Contracts.Patients;

// Referral entry returned for a patient.
public sealed class PatientReferralDto
{
    // Unique identifier for the referral.
    public Guid ReferralId { get; init; }

    // Identifier of the referring provider.
    public Guid ReferringProviderId { get; init; }

    // Referring provider display name.
    public string ReferringProviderName { get; init; } = string.Empty;

    // Identifier of the destination provider when one has been assigned.
    public Guid? ReferredProviderId { get; init; }

    // Destination provider display name.
    public string ReferredProviderName { get; init; } = string.Empty;

    // Date the referral was created.
    public DateTime ReferralDate { get; init; }

    // Clinical reason for the referral.
    public string Reason { get; init; } = string.Empty;

    // Priority label applied to the referral.
    public string Priority { get; init; } = string.Empty;

    // Referral type used by the workflow.
    public string ReferralType { get; init; } = string.Empty;

    // Requested specialization or specialty.
    public string SpecializationNeeded { get; init; } = string.Empty;

    // Human-readable referral code.
    public string ReferralCode { get; init; } = string.Empty;

    // Current referral status.
    public string Status { get; init; } = string.Empty;

    // Date the receiving provider accepted the referral, when applicable.
    public DateTime? AcceptanceDate { get; init; }

    // Date the referral was completed, when applicable.
    public DateTime? CompletionDate { get; init; }

    // Free-form notes attached to the referral.
    public string Notes { get; init; } = string.Empty;

    // Last update timestamp from the source system.
    public DateTime? UpdatedDate { get; init; }
}
