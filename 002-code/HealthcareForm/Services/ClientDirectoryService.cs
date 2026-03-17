using HealthcareForm.Contracts.Clients;
using System.Data;
using System.Data.SqlClient;

namespace HealthcareForm.Services;

public sealed class ClientDirectoryService : IClientDirectoryService
{
    private const string ConnectionStringKey = "HealthcareEntity";
    private const int DefaultPageSize = 25;
    private const int MaxPageSize = 200;

    private readonly IConfiguration _configuration;
    private readonly ILogger<ClientDirectoryService> _logger;

    public ClientDirectoryService(IConfiguration configuration, ILogger<ClientDirectoryService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<IReadOnlyList<ClientClinicCategoryDto>> GetClinicCategoriesAsync(
        ClientClinicCategoryQueryDto query,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var categories = new List<ClientClinicCategoryDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetClientClinicCategories", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            var categoryId = query.ClientClinicCategoryId <= 0 ? 0 : query.ClientClinicCategoryId;

            command.Parameters.Add(new SqlParameter("@ClientClinicCategoryId", SqlDbType.Int) { Value = categoryId });
            command.Parameters.Add(new SqlParameter("@IsActive", SqlDbType.Bit)
            {
                Value = query.IsActive.HasValue ? query.IsActive.Value : DBNull.Value
            });

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var idOrdinal = reader.GetOrdinal("ClientClinicCategoryId");
            var nameOrdinal = reader.GetOrdinal("CategoryName");
            var clinicSizeOrdinal = reader.GetOrdinal("ClinicSize");
            var ownershipOrdinal = reader.GetOrdinal("OwnershipType");
            var isActiveOrdinal = reader.GetOrdinal("IsActive");
            var createdOrdinal = reader.GetOrdinal("CreatedDate");
            var updatedOrdinal = reader.GetOrdinal("UpdatedDate");

            while (await reader.ReadAsync(cancellationToken))
            {
                categories.Add(new ClientClinicCategoryDto
                {
                    ClientClinicCategoryId = GetInt(reader, idOrdinal),
                    CategoryName = GetString(reader, nameOrdinal),
                    ClinicSize = GetString(reader, clinicSizeOrdinal),
                    OwnershipType = GetString(reader, ownershipOrdinal),
                    IsActive = GetBoolean(reader, isActiveOrdinal),
                    CreatedDate = GetDateTime(reader, createdOrdinal),
                    UpdatedDate = GetDateTime(reader, updatedOrdinal)
                });
            }

            return categories;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to list client clinic categories.");
            return [];
        }
    }

    public async Task<ClientDirectorySnapshotDto> GetClientsAsync(
        ClientDirectoryQueryDto query,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var (pageNumber, pageSize) = NormalizePage(query.PageNumber, query.PageSize);
            var clients = new List<ClientDirectoryItemDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spListClients", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@SearchTerm", SqlDbType.VarChar, 250)
            {
                Value = (query.SearchTerm ?? string.Empty).Trim()
            });
            command.Parameters.Add(new SqlParameter("@ClientClinicCategoryIDFK", SqlDbType.Int)
            {
                Value = query.ClientClinicCategoryId ?? 0
            });
            command.Parameters.Add(new SqlParameter("@ClinicSize", SqlDbType.VarChar, 20)
            {
                Value = (query.ClinicSize ?? string.Empty).Trim()
            });
            command.Parameters.Add(new SqlParameter("@OwnershipType", SqlDbType.VarChar, 20)
            {
                Value = (query.OwnershipType ?? string.Empty).Trim()
            });
            command.Parameters.Add(new SqlParameter("@IsActive", SqlDbType.Bit)
            {
                Value = query.IsActive.HasValue ? query.IsActive.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@IsDeleted", SqlDbType.Bit)
            {
                Value = query.IsDeleted ?? false
            });
            command.Parameters.Add(new SqlParameter("@PageNumber", SqlDbType.Int) { Value = pageNumber });
            command.Parameters.Add(new SqlParameter("@PageSize", SqlDbType.Int) { Value = pageSize });

            var totalRecordsParameter = new SqlParameter("@TotalRecords", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };
            var messageParameter = new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            };

            command.Parameters.Add(totalRecordsParameter);
            command.Parameters.Add(messageParameter);

            await connection.OpenAsync(cancellationToken);
            await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
            {
                var clientIdOrdinal = reader.GetOrdinal("ClientId");
                var patientIdOrdinal = reader.GetOrdinal("PatientIdFK");
                var categoryIdOrdinal = reader.GetOrdinal("ClientClinicCategoryIDFK");
                var categoryNameOrdinal = reader.GetOrdinal("ClientClinicCategoryName");
                var clinicSizeOrdinal = reader.GetOrdinal("ClinicSize");
                var ownershipTypeOrdinal = reader.GetOrdinal("OwnershipType");
                var clientCodeOrdinal = reader.GetOrdinal("ClientCode");
                var firstNameOrdinal = reader.GetOrdinal("FirstName");
                var lastNameOrdinal = reader.GetOrdinal("LastName");
                var dateOfBirthOrdinal = reader.GetOrdinal("DateOfBirth");
                var idNumberOrdinal = reader.GetOrdinal("ID_Number");
                var emailOrdinal = reader.GetOrdinal("Email");
                var phoneNumberOrdinal = reader.GetOrdinal("PhoneNumber");
                var addressIdOrdinal = reader.GetOrdinal("AddressIDFK");
                var line1Ordinal = reader.GetOrdinal("Line1");
                var line2Ordinal = reader.GetOrdinal("Line2");
                var cityIdOrdinal = reader.GetOrdinal("CityIDFK");
                var isActiveOrdinal = reader.GetOrdinal("IsActive");
                var isDeletedOrdinal = reader.GetOrdinal("IsDeleted");
                var createdDateOrdinal = reader.GetOrdinal("CreatedDate");
                var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");

                while (await reader.ReadAsync(cancellationToken))
                {
                    clients.Add(new ClientDirectoryItemDto
                    {
                        ClientId = reader.GetGuid(clientIdOrdinal),
                        PatientId = GetGuidNullable(reader, patientIdOrdinal),
                        ClientClinicCategoryId = GetIntNullable(reader, categoryIdOrdinal),
                        ClientClinicCategoryName = GetString(reader, categoryNameOrdinal),
                        ClinicSize = GetString(reader, clinicSizeOrdinal),
                        OwnershipType = GetString(reader, ownershipTypeOrdinal),
                        ClientCode = GetString(reader, clientCodeOrdinal),
                        FirstName = GetString(reader, firstNameOrdinal),
                        LastName = GetString(reader, lastNameOrdinal),
                        DateOfBirth = GetDateTimeNullable(reader, dateOfBirthOrdinal),
                        IdNumber = GetString(reader, idNumberOrdinal),
                        Email = GetString(reader, emailOrdinal),
                        PhoneNumber = GetString(reader, phoneNumberOrdinal),
                        AddressId = GetGuidNullable(reader, addressIdOrdinal),
                        Line1 = GetString(reader, line1Ordinal),
                        Line2 = GetString(reader, line2Ordinal),
                        CityId = GetIntNullable(reader, cityIdOrdinal),
                        IsActive = GetBoolean(reader, isActiveOrdinal),
                        IsDeleted = GetBoolean(reader, isDeletedOrdinal),
                        CreatedDate = GetDateTime(reader, createdDateOrdinal),
                        UpdatedDate = GetDateTime(reader, updatedDateOrdinal)
                    });
                }
            }

            var totalRecords = GetIntOutput(command, "@TotalRecords");
            var message = GetStringOutput(command, "@Message");
            if (!string.IsNullOrWhiteSpace(message))
            {
                _logger.LogWarning("Client list returned message: {Message}", message);
            }

            return new ClientDirectorySnapshotDto
            {
                Clients = clients,
                TotalRecords = totalRecords
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to list clients.");
            return new ClientDirectorySnapshotDto();
        }
    }

    public async Task<ClientDepartmentSnapshotDto> GetClientDepartmentsAsync(
        ClientDepartmentQueryDto query,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var (pageNumber, pageSize) = NormalizePage(query.PageNumber, query.PageSize);
            var departments = new List<ClientDepartmentDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spListClientDepartments", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = query.ClientId.HasValue ? query.ClientId.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@DepartmentType", SqlDbType.VarChar, 50)
            {
                Value = (query.DepartmentType ?? string.Empty).Trim()
            });
            command.Parameters.Add(new SqlParameter("@SearchTerm", SqlDbType.VarChar, 100)
            {
                Value = (query.SearchTerm ?? string.Empty).Trim()
            });
            command.Parameters.Add(new SqlParameter("@IsActive", SqlDbType.Bit)
            {
                Value = query.IsActive.HasValue ? query.IsActive.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@IsDeleted", SqlDbType.Bit)
            {
                Value = query.IsDeleted ?? false
            });
            command.Parameters.Add(new SqlParameter("@PageNumber", SqlDbType.Int) { Value = pageNumber });
            command.Parameters.Add(new SqlParameter("@PageSize", SqlDbType.Int) { Value = pageSize });

            var totalRecordsParameter = new SqlParameter("@TotalRecords", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };
            var messageParameter = new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            };

            command.Parameters.Add(totalRecordsParameter);
            command.Parameters.Add(messageParameter);

            await connection.OpenAsync(cancellationToken);
            await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
            {
                var departmentIdOrdinal = reader.GetOrdinal("ClientDepartmentId");
                var clientIdOrdinal = reader.GetOrdinal("ClientIdFK");
                var clientCodeOrdinal = reader.GetOrdinal("ClientCode");
                var clientFirstNameOrdinal = reader.GetOrdinal("ClientFirstName");
                var clientLastNameOrdinal = reader.GetOrdinal("ClientLastName");
                var departmentCodeOrdinal = reader.GetOrdinal("DepartmentCode");
                var departmentNameOrdinal = reader.GetOrdinal("DepartmentName");
                var departmentTypeOrdinal = reader.GetOrdinal("DepartmentType");
                var isActiveOrdinal = reader.GetOrdinal("IsActive");
                var isDeletedOrdinal = reader.GetOrdinal("IsDeleted");
                var createdDateOrdinal = reader.GetOrdinal("CreatedDate");
                var createdByOrdinal = reader.GetOrdinal("CreatedBy");
                var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
                var updatedByOrdinal = reader.GetOrdinal("UpdatedBy");

                while (await reader.ReadAsync(cancellationToken))
                {
                    departments.Add(new ClientDepartmentDto
                    {
                        ClientDepartmentId = reader.GetGuid(departmentIdOrdinal),
                        ClientId = reader.GetGuid(clientIdOrdinal),
                        ClientCode = GetString(reader, clientCodeOrdinal),
                        ClientFirstName = GetString(reader, clientFirstNameOrdinal),
                        ClientLastName = GetString(reader, clientLastNameOrdinal),
                        DepartmentCode = GetString(reader, departmentCodeOrdinal),
                        DepartmentName = GetString(reader, departmentNameOrdinal),
                        DepartmentType = GetString(reader, departmentTypeOrdinal),
                        IsActive = GetBoolean(reader, isActiveOrdinal),
                        IsDeleted = GetBoolean(reader, isDeletedOrdinal),
                        CreatedDate = GetDateTime(reader, createdDateOrdinal),
                        CreatedBy = GetString(reader, createdByOrdinal),
                        UpdatedDate = GetDateTime(reader, updatedDateOrdinal),
                        UpdatedBy = GetString(reader, updatedByOrdinal)
                    });
                }
            }

            var totalRecords = GetIntOutput(command, "@TotalRecords");
            var message = GetStringOutput(command, "@Message");
            if (!string.IsNullOrWhiteSpace(message))
            {
                _logger.LogWarning("Client departments list returned message: {Message}", message);
            }

            return new ClientDepartmentSnapshotDto
            {
                Departments = departments,
                TotalRecords = totalRecords
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to list client departments.");
            return new ClientDepartmentSnapshotDto();
        }
    }

    public async Task<ClientStaffSnapshotDto> GetClientStaffAsync(
        ClientStaffQueryDto query,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var (pageNumber, pageSize) = NormalizePage(query.PageNumber, query.PageSize);
            var staff = new List<ClientStaffDto>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spListClientStaff", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = query.ClientId.HasValue ? query.ClientId.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@SearchTerm", SqlDbType.VarChar, 250)
            {
                Value = (query.SearchTerm ?? string.Empty).Trim()
            });
            command.Parameters.Add(new SqlParameter("@RoleIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = query.RoleId.HasValue ? query.RoleId.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@StaffType", SqlDbType.VarChar, 50)
            {
                Value = (query.StaffType ?? string.Empty).Trim()
            });
            command.Parameters.Add(new SqlParameter("@IsActive", SqlDbType.Bit)
            {
                Value = query.IsActive.HasValue ? query.IsActive.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@IsDeleted", SqlDbType.Bit)
            {
                Value = query.IsDeleted ?? false
            });
            command.Parameters.Add(new SqlParameter("@PageNumber", SqlDbType.Int) { Value = pageNumber });
            command.Parameters.Add(new SqlParameter("@PageSize", SqlDbType.Int) { Value = pageSize });

            var totalRecordsParameter = new SqlParameter("@TotalRecords", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            };
            var messageParameter = new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            };

            command.Parameters.Add(totalRecordsParameter);
            command.Parameters.Add(messageParameter);

            await connection.OpenAsync(cancellationToken);
            await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
            {
                var clientStaffIdOrdinal = reader.GetOrdinal("ClientStaffId");
                var clientIdOrdinal = reader.GetOrdinal("ClientIdFK");
                var clientCodeOrdinal = reader.GetOrdinal("ClientCode");
                var roleIdOrdinal = reader.GetOrdinal("RoleIdFK");
                var roleNameOrdinal = reader.GetOrdinal("RoleName");
                var userIdOrdinal = reader.GetOrdinal("UserIdFK");
                var usernameOrdinal = reader.GetOrdinal("Username");
                var providerIdOrdinal = reader.GetOrdinal("ProviderIdFK");
                var staffCodeOrdinal = reader.GetOrdinal("StaffCode");
                var firstNameOrdinal = reader.GetOrdinal("FirstName");
                var lastNameOrdinal = reader.GetOrdinal("LastName");
                var emailOrdinal = reader.GetOrdinal("Email");
                var phoneNumberOrdinal = reader.GetOrdinal("PhoneNumber");
                var jobTitleOrdinal = reader.GetOrdinal("JobTitle");
                var departmentOrdinal = reader.GetOrdinal("Department");
                var designationIdOrdinal = reader.GetOrdinal("StaffDesignationIdFK");
                var designationNameOrdinal = reader.GetOrdinal("StaffDesignation");
                var primaryDepartmentIdOrdinal = reader.GetOrdinal("PrimaryDepartmentIdFK");
                var primaryDepartmentNameOrdinal = reader.GetOrdinal("PrimaryDepartmentName");
                var staffTypeOrdinal = reader.GetOrdinal("StaffType");
                var employmentTypeOrdinal = reader.GetOrdinal("EmploymentType");
                var hireDateOrdinal = reader.GetOrdinal("HireDate");
                var terminationDateOrdinal = reader.GetOrdinal("TerminationDate");
                var isPrimaryContactOrdinal = reader.GetOrdinal("IsPrimaryContact");
                var isActiveOrdinal = reader.GetOrdinal("IsActive");
                var isDeletedOrdinal = reader.GetOrdinal("IsDeleted");
                var createdDateOrdinal = reader.GetOrdinal("CreatedDate");
                var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");

                while (await reader.ReadAsync(cancellationToken))
                {
                    staff.Add(new ClientStaffDto
                    {
                        ClientStaffId = reader.GetGuid(clientStaffIdOrdinal),
                        ClientId = reader.GetGuid(clientIdOrdinal),
                        ClientCode = GetString(reader, clientCodeOrdinal),
                        RoleId = GetGuidNullable(reader, roleIdOrdinal),
                        RoleName = GetString(reader, roleNameOrdinal),
                        UserId = GetGuidNullable(reader, userIdOrdinal),
                        Username = GetString(reader, usernameOrdinal),
                        ProviderId = GetGuidNullable(reader, providerIdOrdinal),
                        StaffCode = GetString(reader, staffCodeOrdinal),
                        FirstName = GetString(reader, firstNameOrdinal),
                        LastName = GetString(reader, lastNameOrdinal),
                        Email = GetString(reader, emailOrdinal),
                        PhoneNumber = GetString(reader, phoneNumberOrdinal),
                        JobTitle = GetString(reader, jobTitleOrdinal),
                        Department = GetString(reader, departmentOrdinal),
                        StaffDesignationId = GetGuidNullable(reader, designationIdOrdinal),
                        StaffDesignation = GetString(reader, designationNameOrdinal),
                        PrimaryDepartmentId = GetGuidNullable(reader, primaryDepartmentIdOrdinal),
                        PrimaryDepartmentName = GetString(reader, primaryDepartmentNameOrdinal),
                        StaffType = GetString(reader, staffTypeOrdinal),
                        EmploymentType = GetString(reader, employmentTypeOrdinal),
                        HireDate = GetDateTimeNullable(reader, hireDateOrdinal),
                        TerminationDate = GetDateTimeNullable(reader, terminationDateOrdinal),
                        IsPrimaryContact = GetBoolean(reader, isPrimaryContactOrdinal),
                        IsActive = GetBoolean(reader, isActiveOrdinal),
                        IsDeleted = GetBoolean(reader, isDeletedOrdinal),
                        CreatedDate = GetDateTime(reader, createdDateOrdinal),
                        UpdatedDate = GetDateTime(reader, updatedDateOrdinal)
                    });
                }
            }

            var totalRecords = GetIntOutput(command, "@TotalRecords");
            var message = GetStringOutput(command, "@Message");
            if (!string.IsNullOrWhiteSpace(message))
            {
                _logger.LogWarning("Client staff list returned message: {Message}", message);
            }

            return new ClientStaffSnapshotDto
            {
                Staff = staff,
                TotalRecords = totalRecords
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to list client staff.");
            return new ClientStaffSnapshotDto();
        }
    }

    private static (int PageNumber, int PageSize) NormalizePage(int pageNumber, int pageSize)
    {
        var normalizedPage = pageNumber < 1 ? 1 : pageNumber;
        var normalizedSize = pageSize < 1 ? DefaultPageSize : pageSize;
        if (normalizedSize > MaxPageSize)
        {
            normalizedSize = MaxPageSize;
        }

        return (normalizedPage, normalizedSize);
    }

    private static string GetString(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return string.Empty;
        }

        return Convert.ToString(reader.GetValue(ordinal)) ?? string.Empty;
    }

    private static int GetInt(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return 0;
        }

        return Convert.ToInt32(reader.GetValue(ordinal));
    }

    private static int? GetIntNullable(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return null;
        }

        return Convert.ToInt32(reader.GetValue(ordinal));
    }

    private static Guid? GetGuidNullable(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return null;
        }

        return reader.GetGuid(ordinal);
    }

    private static DateTime? GetDateTimeNullable(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return null;
        }

        return Convert.ToDateTime(reader.GetValue(ordinal));
    }

    private static DateTime GetDateTime(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return DateTime.MinValue;
        }

        return Convert.ToDateTime(reader.GetValue(ordinal));
    }

    private static bool GetBoolean(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return false;
        }

        return Convert.ToBoolean(reader.GetValue(ordinal));
    }

    private static int GetIntOutput(SqlCommand command, string name)
    {
        if (!command.Parameters.Contains(name))
        {
            return 0;
        }

        var value = command.Parameters[name].Value;
        if (value is null || value == DBNull.Value)
        {
            return 0;
        }

        return Convert.ToInt32(value);
    }

    private static string GetStringOutput(SqlCommand command, string name)
    {
        if (!command.Parameters.Contains(name))
        {
            return string.Empty;
        }

        var value = command.Parameters[name].Value;
        if (value is null || value == DBNull.Value)
        {
            return string.Empty;
        }

        return Convert.ToString(value) ?? string.Empty;
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
}
