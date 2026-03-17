using HealthcareForm.Contracts.Forms;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class FormsService : IFormsService
{
    private const string ConnectionStringKey = "HealthcareEntity";

    private readonly IConfiguration _configuration;
    private readonly ILogger<FormsService> _logger;

    public FormsService(IConfiguration configuration, ILogger<FormsService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<IReadOnlyList<FormFieldValueDto>> GetFormFieldValuesAsync(Guid formSubmissionId, CancellationToken cancellationToken = default)
    {
        try
        {
            var items = new List<FormFieldValueDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Contacts.spGetFormFieldValues", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@FormSubmissionId", formSubmissionId));

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("FormFieldValueId");
            var submissionOrdinal = reader.GetOrdinal("FormSubmissionIdFK");
            var nameOrdinal = reader.GetOrdinal("FieldName");
            var typeOrdinal = reader.GetOrdinal("FieldType");
            var valueOrdinal = reader.GetOrdinal("FieldValue");
            var orderOrdinal = reader.GetOrdinal("DisplayOrder");
            var requiredOrdinal = reader.GetOrdinal("IsRequired");
            var validationOrdinal = reader.GetOrdinal("ValidationRules");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new FormFieldValueDto
                {
                    FormFieldValueId = GetReaderGuid(reader, idOrdinal),
                    FormSubmissionId = GetReaderGuid(reader, submissionOrdinal),
                    FieldName = GetReaderString(reader, nameOrdinal),
                    FieldType = GetReaderString(reader, typeOrdinal),
                    FieldValue = GetReaderString(reader, valueOrdinal),
                    DisplayOrder = GetReaderNullableInt(reader, orderOrdinal),
                    IsRequired = GetReaderBoolean(reader, requiredOrdinal),
                    ValidationRules = GetReaderString(reader, validationOrdinal),
                    UpdatedDate = GetReaderNullableDateTime(reader, updatedOrdinal)
                });
            }

            return items;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load form field values for submission {SubmissionId}.", formSubmissionId);
            return [];
        }
    }

    public async Task<IReadOnlyList<FormAttachmentDto>> GetFormAttachmentsAsync(Guid formSubmissionId, CancellationToken cancellationToken = default)
    {
        try
        {
            var items = new List<FormAttachmentDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Contacts.spGetFormAttachments", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@FormSubmissionId", formSubmissionId));

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("FormAttachmentId");
            var submissionOrdinal = reader.GetOrdinal("FormSubmissionIdFK");
            var nameOrdinal = reader.GetOrdinal("FileName");
            var typeOrdinal = reader.GetOrdinal("FileType");
            var sizeOrdinal = reader.GetOrdinal("FileSizeBytes");
            var hashOrdinal = reader.GetOrdinal("FileHash");
            var pathOrdinal = reader.GetOrdinal("StoragePath");
            var documentOrdinal = reader.GetOrdinal("DocumentType");
            var uploadedDateOrdinal = reader.GetOrdinal("UploadedDate");
            var uploadedByOrdinal = reader.GetOrdinal("UploadedBy");
            var verifiedOrdinal = reader.GetOrdinal("IsVerified");
            var verifiedByOrdinal = reader.GetOrdinal("VerifiedBy");
            var verificationDateOrdinal = reader.GetOrdinal("VerificationDate");
            var expiryDateOrdinal = reader.GetOrdinal("ExpiryDate");
            var notesOrdinal = reader.GetOrdinal("Notes");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new FormAttachmentDto
                {
                    FormAttachmentId = GetReaderGuid(reader, idOrdinal),
                    FormSubmissionId = GetReaderGuid(reader, submissionOrdinal),
                    FileName = GetReaderString(reader, nameOrdinal),
                    FileType = GetReaderString(reader, typeOrdinal),
                    FileSizeBytes = GetReaderLong(reader, sizeOrdinal),
                    FileHash = GetReaderString(reader, hashOrdinal),
                    StoragePath = GetReaderString(reader, pathOrdinal),
                    DocumentType = GetReaderString(reader, documentOrdinal),
                    UploadedDate = GetReaderDateTime(reader, uploadedDateOrdinal),
                    UploadedBy = GetReaderString(reader, uploadedByOrdinal),
                    IsVerified = GetReaderBoolean(reader, verifiedOrdinal),
                    VerifiedBy = GetReaderString(reader, verifiedByOrdinal),
                    VerificationDate = GetReaderNullableDateTime(reader, verificationDateOrdinal),
                    ExpiryDate = GetReaderNullableDateTime(reader, expiryDateOrdinal),
                    Notes = GetReaderString(reader, notesOrdinal),
                    UpdatedDate = GetReaderNullableDateTime(reader, updatedOrdinal)
                });
            }

            return items;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to load form attachments for submission {SubmissionId}.", formSubmissionId);
            return [];
        }
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

    private static string GetReaderString(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? string.Empty : Convert.ToString(reader.GetValue(ordinal)) ?? string.Empty;

    private static Guid GetReaderGuid(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? Guid.Empty : reader.GetGuid(ordinal);

    private static int? GetReaderNullableInt(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? null : Convert.ToInt32(reader.GetValue(ordinal));

    private static long GetReaderLong(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? 0L : Convert.ToInt64(reader.GetValue(ordinal));

    private static bool GetReaderBoolean(SqlDataReader reader, int ordinal)
        => !reader.IsDBNull(ordinal) && Convert.ToBoolean(reader.GetValue(ordinal));

    private static DateTime GetReaderDateTime(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? DateTime.MinValue : Convert.ToDateTime(reader.GetValue(ordinal));

    private static DateTime? GetReaderNullableDateTime(SqlDataReader reader, int ordinal)
        => reader.IsDBNull(ordinal) ? null : Convert.ToDateTime(reader.GetValue(ordinal));
}
