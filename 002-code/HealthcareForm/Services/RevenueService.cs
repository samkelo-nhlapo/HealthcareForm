using HealthcareForm.Contracts.Revenue;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class RevenueService : IRevenueService
{
    private const string ConnectionStringKey = "HealthcareEntity";
    private const int MaxClaimsRows = 400;

    private readonly IConfiguration _configuration;
    private readonly ILogger<RevenueService> _logger;

    public RevenueService(IConfiguration configuration, ILogger<RevenueService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<RevenueClaimsSnapshotDto> GetClaimsSnapshotAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetRevenueClaimsSourceRows", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@MaxRows", SqlDbType.Int) { Value = MaxClaimsRows });

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var invoiceIdOrdinal = reader.GetOrdinal("InvoiceId");
            var invoiceNumberOrdinal = reader.GetOrdinal("InvoiceNumber");
            var invoiceDateOrdinal = reader.GetOrdinal("InvoiceDate");
            var serviceDateOrdinal = reader.GetOrdinal("ServiceDate");
            var totalAmountOrdinal = reader.GetOrdinal("TotalAmount");
            var insuranceCoverageOrdinal = reader.GetOrdinal("InsuranceCoverage");
            var statusOrdinal = reader.GetOrdinal("Status");
            var notesOrdinal = reader.GetOrdinal("Notes");
            var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
            var firstNameOrdinal = reader.GetOrdinal("FirstName");
            var lastNameOrdinal = reader.GetOrdinal("LastName");
            var idNumberOrdinal = reader.GetOrdinal("IdNumber");
            var payerNameOrdinal = reader.GetOrdinal("PayerName");
            var billingCodeOrdinal = reader.GetOrdinal("BillingCode");

            var claims = new List<RevenueClaimRowDto>();

            while (await reader.ReadAsync(cancellationToken))
            {
                var status = GetString(reader, statusOrdinal);
                var notes = GetString(reader, notesOrdinal);
                var amount = GetDecimal(reader, totalAmountOrdinal);
                var insuranceCoverage = GetDecimalNullable(reader, insuranceCoverageOrdinal);

                var invoiceDate = GetDateTime(reader, invoiceDateOrdinal, DateTime.Today);
                var serviceDate = GetDateTime(reader, serviceDateOrdinal, invoiceDate);
                var updatedDate = GetDateTime(reader, updatedDateOrdinal, invoiceDate);

                var firstName = GetString(reader, firstNameOrdinal);
                var lastName = GetString(reader, lastNameOrdinal);
                var patientName = $"{firstName} {lastName}".Trim();
                if (string.IsNullOrWhiteSpace(patientName))
                {
                    patientName = "Unknown Patient";
                }

                var claimStatus = ResolveClaimStatus(status, notes);
                var codingStatus = ResolveCodingStatus(GetString(reader, billingCodeOrdinal), status);
                var paidAmount = ResolvePaidAmount(amount, insuranceCoverage, status);
                var daysOpen = Math.Max(0, (int)Math.Floor((DateTime.Today - invoiceDate.Date).TotalDays));

                claims.Add(new RevenueClaimRowDto
                {
                    ClaimId = ResolveClaimId(
                        GetString(reader, invoiceNumberOrdinal),
                        GetGuid(reader, invoiceIdOrdinal)),
                    Patient = patientName,
                    IdNumber = GetString(reader, idNumberOrdinal),
                    Payer = GetString(reader, payerNameOrdinal, "Self Pay"),
                    ServiceDate = serviceDate.ToString("yyyy-MM-dd"),
                    Amount = amount,
                    PaidAmount = paidAmount,
                    CodingStatus = codingStatus,
                    ClaimStatus = claimStatus,
                    DenialReason = ResolveDenialReason(claimStatus, notes),
                    DaysOpen = daysOpen,
                    LastUpdated = updatedDate.ToString("yyyy-MM-dd HH:mm")
                });
            }

            return new RevenueClaimsSnapshotDto
            {
                Claims = claims
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to build revenue claims snapshot.");
            return new RevenueClaimsSnapshotDto();
        }
    }

    private static string ResolveClaimId(string invoiceNumber, Guid? invoiceId)
    {
        if (!string.IsNullOrWhiteSpace(invoiceNumber))
        {
            return invoiceNumber;
        }

        if (invoiceId.HasValue)
        {
            return $"INV-{invoiceId.Value.ToString("N")[..8].ToUpperInvariant()}";
        }

        return "INV-UNKNOWN";
    }

    private static string ResolveCodingStatus(string billingCode, string invoiceStatus)
    {
        if (string.IsNullOrWhiteSpace(billingCode))
        {
            return "Uncoded";
        }

        var normalizedStatus = (invoiceStatus ?? string.Empty).Trim().ToUpperInvariant();
        if (normalizedStatus.Contains("DRAFT", StringComparison.Ordinal))
        {
            return "Coder Review";
        }

        return "Code Complete";
    }

    private static string ResolveClaimStatus(string invoiceStatus, string notes)
    {
        var normalizedStatus = (invoiceStatus ?? string.Empty).Trim().ToUpperInvariant();
        var normalizedNotes = (notes ?? string.Empty).Trim().ToUpperInvariant();

        if (normalizedStatus.Contains("PAID", StringComparison.Ordinal)
            && !normalizedStatus.Contains("PARTIAL", StringComparison.Ordinal))
        {
            return "Paid";
        }

        if (normalizedStatus.Contains("SENT", StringComparison.Ordinal)
            || normalizedStatus.Contains("SUBMIT", StringComparison.Ordinal))
        {
            return "Submitted";
        }

        if (normalizedStatus.Contains("OVERDUE", StringComparison.Ordinal)
            || normalizedStatus.Contains("PARTIAL", StringComparison.Ordinal))
        {
            return "Pending Documentation";
        }

        if (normalizedStatus.Contains("CANCEL", StringComparison.Ordinal)
            || normalizedNotes.Contains("DENY", StringComparison.Ordinal)
            || normalizedNotes.Contains("REJECT", StringComparison.Ordinal))
        {
            return "Denied";
        }

        return "Ready to Submit";
    }

    private static decimal ResolvePaidAmount(decimal amount, decimal? insuranceCoverage, string invoiceStatus)
    {
        var normalizedStatus = (invoiceStatus ?? string.Empty).Trim().ToUpperInvariant();

        if (normalizedStatus.Contains("PAID", StringComparison.Ordinal)
            && !normalizedStatus.Contains("PARTIAL", StringComparison.Ordinal))
        {
            return amount;
        }

        if (normalizedStatus.Contains("PARTIAL", StringComparison.Ordinal))
        {
            return Math.Min(amount, Math.Max(0m, insuranceCoverage ?? 0m));
        }

        return 0m;
    }

    private static string ResolveDenialReason(string claimStatus, string notes)
    {
        if (!claimStatus.Equals("Denied", StringComparison.OrdinalIgnoreCase))
        {
            return string.Empty;
        }

        if (!string.IsNullOrWhiteSpace(notes))
        {
            return notes.Trim();
        }

        return "Claim denied by payer.";
    }

    private string GetConnectionString()
    {
        var connection = _configuration.GetConnectionString(ConnectionStringKey);
        if (string.IsNullOrWhiteSpace(connection) || connection.StartsWith("__SET_CONNECTIONSTRINGS__", StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Connection string '{ConnectionStringKey}' is not configured.");
        }

        return connection;
    }

    private static string GetString(SqlDataReader reader, int ordinal, string fallback = "")
    {
        if (reader.IsDBNull(ordinal))
        {
            return fallback;
        }

        return Convert.ToString(reader.GetValue(ordinal))?.Trim() ?? fallback;
    }

    private static DateTime GetDateTime(SqlDataReader reader, int ordinal, DateTime fallback)
    {
        if (reader.IsDBNull(ordinal))
        {
            return fallback;
        }

        return Convert.ToDateTime(reader.GetValue(ordinal));
    }

    private static decimal GetDecimal(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return 0m;
        }

        return Convert.ToDecimal(reader.GetValue(ordinal));
    }

    private static decimal? GetDecimalNullable(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return null;
        }

        return Convert.ToDecimal(reader.GetValue(ordinal));
    }

    private static Guid? GetGuid(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return null;
        }

        return reader.GetGuid(ordinal);
    }
}
