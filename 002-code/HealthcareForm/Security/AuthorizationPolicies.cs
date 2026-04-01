namespace HealthcareForm.Security;

// Central place for backend role names and the policies built from them.
public static class AuthorizationPolicies
{
    // These role names mirror the values stored in the auth schema.
    public const string AdminRole = "ADMIN";
    public const string DoctorRole = "DOCTOR";
    public const string NurseRole = "NURSE";
    public const string ReceptionistRole = "RECEPTIONIST";
    public const string BillingRole = "BILLING";
    public const string PharmacistRole = "PHARMACIST";

    // Policy names stay stable even if the role membership behind them changes.
    public const string PatientsRead = nameof(PatientsRead);
    public const string PatientsWrite = nameof(PatientsWrite);
    public const string PatientsDelete = nameof(PatientsDelete);
    public const string LookupsRead = nameof(LookupsRead);
    public const string OperationsAccess = nameof(OperationsAccess);
    public const string RevenueAccess = nameof(RevenueAccess);
    public const string AdminAccess = nameof(AdminAccess);

    // These arrays are the single source of truth for policy-to-role mapping.
    public static readonly string[] PatientsReadRoles =
    [
        AdminRole,
        DoctorRole,
        NurseRole,
        ReceptionistRole,
        BillingRole,
        PharmacistRole
    ];

    public static readonly string[] PatientsWriteRoles =
    [
        AdminRole,
        DoctorRole,
        NurseRole,
        ReceptionistRole
    ];

    public static readonly string[] PatientsDeleteRoles =
    [
        AdminRole
    ];

    public static readonly string[] LookupsReadRoles = PatientsReadRoles;

    public static readonly string[] OperationsAccessRoles =
    [
        AdminRole,
        DoctorRole,
        NurseRole,
        BillingRole,
        PharmacistRole
    ];

    public static readonly string[] RevenueAccessRoles =
    [
        AdminRole,
        BillingRole
    ];

    public static readonly string[] AdminAccessRoles =
    [
        AdminRole
    ];
}
