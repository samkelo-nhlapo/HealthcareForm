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

    public async Task<ClientCommandResult> AddClientAsync(
        ClientCreateRequest request,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (HasPartialAddress(request.Line1, request.Line2, request.CityId))
        {
            return new ClientCommandResult
            {
                Success = false,
                Message = "Line 1, line 2, and city are all required when saving an address.",
                StatusCode = 1,
                ClientId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);
            await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(cancellationToken);

            try
            {
                Guid? addressId = null;
                if (HasAddress(request.Line1, request.Line2, request.CityId))
                {
                    addressId = await InsertAddressAsync(
                        connection,
                        transaction,
                        request.Line1,
                        request.Line2,
                        request.CityId,
                        actor,
                        cancellationToken);
                }

                await using var command = new SqlCommand("Profile.spAddClient", connection, transaction)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.Add(new SqlParameter("@ClientCode", SqlDbType.VarChar, 50) { Value = request.ClientCode.Trim() });
                command.Parameters.Add(new SqlParameter("@FirstName", SqlDbType.VarChar, 250) { Value = request.FirstName.Trim() });
                command.Parameters.Add(new SqlParameter("@LastName", SqlDbType.VarChar, 250) { Value = request.LastName.Trim() });
                command.Parameters.Add(new SqlParameter("@DateOfBirth", SqlDbType.DateTime)
                {
                    Value = request.DateOfBirth.HasValue ? request.DateOfBirth.Value : DBNull.Value
                });
                command.Parameters.Add(new SqlParameter("@ID_Number", SqlDbType.VarChar, 250)
                {
                    Value = ToDbString(request.IdNumber)
                });
                command.Parameters.Add(new SqlParameter("@Email", SqlDbType.VarChar, 250)
                {
                    Value = ToDbString(request.Email)
                });
                command.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.VarChar, 25)
                {
                    Value = ToDbString(request.PhoneNumber)
                });
                command.Parameters.Add(new SqlParameter("@AddressIDFK", SqlDbType.UniqueIdentifier)
                {
                    Value = addressId.HasValue ? addressId.Value : DBNull.Value
                });
                command.Parameters.Add(new SqlParameter("@PatientIdFK", SqlDbType.UniqueIdentifier)
                {
                    Value = DBNull.Value
                });
                command.Parameters.Add(new SqlParameter("@ClientClinicCategoryIDFK", SqlDbType.Int)
                {
                    Value = request.ClientClinicCategoryId.HasValue ? request.ClientClinicCategoryId.Value : DBNull.Value
                });
                command.Parameters.Add(new SqlParameter("@CreatedBy", SqlDbType.VarChar, 250)
                {
                    Value = NormalizeActor(actor)
                });

                var clientIdParameter = command.Parameters.Add(new SqlParameter("@ClientIdOutput", SqlDbType.UniqueIdentifier)
                {
                    Direction = ParameterDirection.Output
                });
                var statusCodeParameter = command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                });
                var messageParameter = command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
                {
                    Direction = ParameterDirection.Output
                });

                _ = clientIdParameter;
                _ = statusCodeParameter;
                _ = messageParameter;

                await command.ExecuteNonQueryAsync(cancellationToken);

                var message = GetStringOutput(command, "@Message");
                var statusCode = GetNullableIntOutput(command, "@StatusCode");
                var clientId = GetGuidOutput(command, "@ClientIdOutput");
                var success = string.IsNullOrWhiteSpace(message) && statusCode == 0 && clientId.HasValue;

                if (success)
                {
                    await transaction.CommitAsync(cancellationToken);
                }
                else
                {
                    await transaction.RollbackAsync(cancellationToken);
                }

                return new ClientCommandResult
                {
                    Success = success,
                    Message = message,
                    StatusCode = statusCode,
                    ClientId = clientId
                };
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to add client.");
            return new ClientCommandResult
            {
                Success = false,
                Message = "Unable to add client right now. Please try again.",
                StatusCode = null,
                ClientId = null
            };
        }
    }

    public async Task<ClientDepartmentCommandResult> AddClientDepartmentAsync(
        Guid clientId,
        ClientDepartmentCreateRequest request,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (clientId == Guid.Empty)
        {
            return new ClientDepartmentCommandResult
            {
                Success = false,
                Message = "Please provide a valid client ID.",
                StatusCode = 1,
                ClientDepartmentId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spAddClientDepartment", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier) { Value = clientId });
            command.Parameters.Add(new SqlParameter("@DepartmentName", SqlDbType.VarChar, 100)
            {
                Value = request.DepartmentName.Trim()
            });
            command.Parameters.Add(new SqlParameter("@DepartmentCode", SqlDbType.VarChar, 50)
            {
                Value = ToDbString(request.DepartmentCode)
            });
            command.Parameters.Add(new SqlParameter("@DepartmentType", SqlDbType.VarChar, 50)
            {
                Value = request.DepartmentType.Trim()
            });
            command.Parameters.Add(new SqlParameter("@CreatedBy", SqlDbType.VarChar, 250)
            {
                Value = NormalizeActor(actor)
            });
            command.Parameters.Add(new SqlParameter("@ClientDepartmentIdOutput", SqlDbType.UniqueIdentifier)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetNullableIntOutput(command, "@StatusCode");
            var clientDepartmentId = GetGuidOutput(command, "@ClientDepartmentIdOutput");
            var success = string.IsNullOrWhiteSpace(message) && statusCode == 0 && clientDepartmentId.HasValue;

            return new ClientDepartmentCommandResult
            {
                Success = success,
                Message = message,
                StatusCode = statusCode,
                ClientDepartmentId = clientDepartmentId
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to add department for client {ClientId}.", clientId);
            return new ClientDepartmentCommandResult
            {
                Success = false,
                Message = "Unable to add client department right now. Please try again.",
                StatusCode = null,
                ClientDepartmentId = null
            };
        }
    }

    public async Task<ClientStaffCommandResult> AddClientStaffAsync(
        Guid clientId,
        ClientStaffCreateRequest request,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (clientId == Guid.Empty)
        {
            return new ClientStaffCommandResult
            {
                Success = false,
                Message = "Please provide a valid client ID.",
                StatusCode = 1,
                ClientStaffId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spAddClientStaff", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientIdFK", SqlDbType.UniqueIdentifier) { Value = clientId });
            command.Parameters.Add(new SqlParameter("@RoleIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });
            command.Parameters.Add(new SqlParameter("@UserIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });
            command.Parameters.Add(new SqlParameter("@ProviderIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });
            command.Parameters.Add(new SqlParameter("@StaffCode", SqlDbType.VarChar, 50) { Value = request.StaffCode.Trim() });
            command.Parameters.Add(new SqlParameter("@FirstName", SqlDbType.VarChar, 250) { Value = request.FirstName.Trim() });
            command.Parameters.Add(new SqlParameter("@LastName", SqlDbType.VarChar, 250) { Value = request.LastName.Trim() });
            command.Parameters.Add(new SqlParameter("@Email", SqlDbType.VarChar, 250) { Value = ToDbString(request.Email) });
            command.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.VarChar, 25) { Value = ToDbString(request.PhoneNumber) });
            command.Parameters.Add(new SqlParameter("@JobTitle", SqlDbType.VarChar, 150) { Value = ToDbString(request.JobTitle) });
            command.Parameters.Add(new SqlParameter("@Department", SqlDbType.VarChar, 100) { Value = ToDbString(request.Department) });
            command.Parameters.Add(new SqlParameter("@StaffType", SqlDbType.VarChar, 50) { Value = request.StaffType.Trim() });
            command.Parameters.Add(new SqlParameter("@EmploymentType", SqlDbType.VarChar, 50) { Value = request.EmploymentType.Trim() });
            command.Parameters.Add(new SqlParameter("@HireDate", SqlDbType.DateTime)
            {
                Value = request.HireDate.HasValue ? request.HireDate.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@IsPrimaryContact", SqlDbType.Bit) { Value = request.IsPrimaryContact });
            command.Parameters.Add(new SqlParameter("@CreatedBy", SqlDbType.VarChar, 250)
            {
                Value = NormalizeActor(actor)
            });
            command.Parameters.Add(new SqlParameter("@StaffDesignationIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });
            command.Parameters.Add(new SqlParameter("@PrimaryDepartmentIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = request.PrimaryDepartmentId.HasValue ? request.PrimaryDepartmentId.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@ClientStaffIdOutput", SqlDbType.UniqueIdentifier)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetNullableIntOutput(command, "@StatusCode");
            var clientStaffId = GetGuidOutput(command, "@ClientStaffIdOutput");
            var success = string.IsNullOrWhiteSpace(message) && statusCode == 0 && clientStaffId.HasValue;

            return new ClientStaffCommandResult
            {
                Success = success,
                Message = message,
                StatusCode = statusCode,
                ClientStaffId = clientStaffId
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to add staff for client {ClientId}.", clientId);
            return new ClientStaffCommandResult
            {
                Success = false,
                Message = "Unable to add client staff right now. Please try again.",
                StatusCode = null,
                ClientStaffId = null
            };
        }
    }

    public async Task<ClientCommandResult> UpdateClientAsync(
        Guid clientId,
        ClientUpdateRequest request,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (HasPartialAddress(request.Line1, request.Line2, request.CityId))
        {
            return new ClientCommandResult
            {
                Success = false,
                Message = "Line 1, line 2, and city are all required when saving an address.",
                StatusCode = 1,
                ClientId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await connection.OpenAsync(cancellationToken);
            await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(cancellationToken);

            try
            {
                var currentAddressId = await TryGetClientAddressIdAsync(connection, transaction, clientId, cancellationToken);
                if (currentAddressId == MissingClient)
                {
                    await transaction.RollbackAsync(cancellationToken);
                    return new ClientCommandResult
                    {
                        Success = false,
                        Message = "Client not found or already deleted.",
                        StatusCode = 1,
                        ClientId = null
                    };
                }

                Guid? resolvedAddressId = null;
                if (HasAddress(request.Line1, request.Line2, request.CityId))
                {
                    resolvedAddressId = currentAddressId.HasValue
                        ? await UpdateAddressAsync(
                            connection,
                            transaction,
                            currentAddressId.Value,
                            request.Line1,
                            request.Line2,
                            request.CityId,
                            actor,
                            cancellationToken)
                        : await InsertAddressAsync(
                            connection,
                            transaction,
                            request.Line1,
                            request.Line2,
                            request.CityId,
                            actor,
                            cancellationToken);
                }

                await using var command = new SqlCommand("Profile.spUpdateClient", connection, transaction)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.Add(new SqlParameter("@ClientId", SqlDbType.UniqueIdentifier) { Value = clientId });
                command.Parameters.Add(new SqlParameter("@ClientCode", SqlDbType.VarChar, 50) { Value = request.ClientCode.Trim() });
                command.Parameters.Add(new SqlParameter("@FirstName", SqlDbType.VarChar, 250) { Value = request.FirstName.Trim() });
                command.Parameters.Add(new SqlParameter("@LastName", SqlDbType.VarChar, 250) { Value = request.LastName.Trim() });
                command.Parameters.Add(new SqlParameter("@DateOfBirth", SqlDbType.DateTime)
                {
                    Value = request.DateOfBirth.HasValue ? request.DateOfBirth.Value : DBNull.Value
                });
                command.Parameters.Add(new SqlParameter("@ID_Number", SqlDbType.VarChar, 250)
                {
                    Value = ToDbString(request.IdNumber)
                });
                command.Parameters.Add(new SqlParameter("@Email", SqlDbType.VarChar, 250)
                {
                    Value = ToDbString(request.Email)
                });
                command.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.VarChar, 25)
                {
                    Value = ToDbString(request.PhoneNumber)
                });
                command.Parameters.Add(new SqlParameter("@AddressIDFK", SqlDbType.UniqueIdentifier)
                {
                    Value = resolvedAddressId.HasValue ? resolvedAddressId.Value : DBNull.Value
                });
                command.Parameters.Add(new SqlParameter("@PatientIdFK", SqlDbType.UniqueIdentifier)
                {
                    Value = DBNull.Value
                });
                command.Parameters.Add(new SqlParameter("@ClientClinicCategoryIDFK", SqlDbType.Int)
                {
                    Value = request.ClientClinicCategoryId.HasValue ? request.ClientClinicCategoryId.Value : DBNull.Value
                });
                command.Parameters.Add(new SqlParameter("@IsActive", SqlDbType.Bit)
                {
                    Value = request.IsActive
                });
                command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250)
                {
                    Value = NormalizeActor(actor)
                });

                command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                });
                command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
                {
                    Direction = ParameterDirection.Output
                });

                await command.ExecuteNonQueryAsync(cancellationToken);

                var message = GetStringOutput(command, "@Message");
                var statusCode = GetNullableIntOutput(command, "@StatusCode");
                var success = string.IsNullOrWhiteSpace(message) && statusCode == 0;

                if (success)
                {
                    await transaction.CommitAsync(cancellationToken);
                }
                else
                {
                    await transaction.RollbackAsync(cancellationToken);
                }

                return new ClientCommandResult
                {
                    Success = success,
                    Message = message,
                    StatusCode = statusCode,
                    ClientId = success ? clientId : null
                };
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update client {ClientId}.", clientId);
            return new ClientCommandResult
            {
                Success = false,
                Message = "Unable to update client right now. Please try again.",
                StatusCode = null,
                ClientId = null
            };
        }
    }

    public async Task<ClientDepartmentCommandResult> UpdateClientDepartmentAsync(
        Guid clientDepartmentId,
        ClientDepartmentUpdateRequest request,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (clientDepartmentId == Guid.Empty)
        {
            return new ClientDepartmentCommandResult
            {
                Success = false,
                Message = "Please provide a valid client department ID.",
                StatusCode = 1,
                ClientDepartmentId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spUpdateClientDepartment", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientDepartmentId", SqlDbType.UniqueIdentifier) { Value = clientDepartmentId });
            command.Parameters.Add(new SqlParameter("@DepartmentName", SqlDbType.VarChar, 100)
            {
                Value = request.DepartmentName.Trim()
            });
            command.Parameters.Add(new SqlParameter("@DepartmentCode", SqlDbType.VarChar, 50)
            {
                Value = ToDbString(request.DepartmentCode)
            });
            command.Parameters.Add(new SqlParameter("@DepartmentType", SqlDbType.VarChar, 50)
            {
                Value = request.DepartmentType.Trim()
            });
            command.Parameters.Add(new SqlParameter("@IsActive", SqlDbType.Bit) { Value = request.IsActive });
            command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250)
            {
                Value = NormalizeActor(actor)
            });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetNullableIntOutput(command, "@StatusCode");
            var success = string.IsNullOrWhiteSpace(message) && statusCode == 0;

            return new ClientDepartmentCommandResult
            {
                Success = success,
                Message = message,
                StatusCode = statusCode,
                ClientDepartmentId = success ? clientDepartmentId : null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update client department {ClientDepartmentId}.", clientDepartmentId);
            return new ClientDepartmentCommandResult
            {
                Success = false,
                Message = "Unable to update client department right now. Please try again.",
                StatusCode = null,
                ClientDepartmentId = null
            };
        }
    }

    public async Task<ClientStaffCommandResult> UpdateClientStaffAsync(
        Guid clientStaffId,
        ClientStaffUpdateRequest request,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (clientStaffId == Guid.Empty)
        {
            return new ClientStaffCommandResult
            {
                Success = false,
                Message = "Please provide a valid client staff ID.",
                StatusCode = 1,
                ClientStaffId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spUpdateClientStaff", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientStaffId", SqlDbType.UniqueIdentifier) { Value = clientStaffId });
            command.Parameters.Add(new SqlParameter("@RoleIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });
            command.Parameters.Add(new SqlParameter("@UserIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });
            command.Parameters.Add(new SqlParameter("@ProviderIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });
            command.Parameters.Add(new SqlParameter("@StaffCode", SqlDbType.VarChar, 50) { Value = request.StaffCode.Trim() });
            command.Parameters.Add(new SqlParameter("@FirstName", SqlDbType.VarChar, 250) { Value = request.FirstName.Trim() });
            command.Parameters.Add(new SqlParameter("@LastName", SqlDbType.VarChar, 250) { Value = request.LastName.Trim() });
            command.Parameters.Add(new SqlParameter("@Email", SqlDbType.VarChar, 250) { Value = ToDbString(request.Email) });
            command.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.VarChar, 25) { Value = ToDbString(request.PhoneNumber) });
            command.Parameters.Add(new SqlParameter("@JobTitle", SqlDbType.VarChar, 150) { Value = ToDbString(request.JobTitle) });
            command.Parameters.Add(new SqlParameter("@Department", SqlDbType.VarChar, 100) { Value = ToDbString(request.Department) });
            command.Parameters.Add(new SqlParameter("@StaffType", SqlDbType.VarChar, 50) { Value = request.StaffType.Trim() });
            command.Parameters.Add(new SqlParameter("@EmploymentType", SqlDbType.VarChar, 50) { Value = request.EmploymentType.Trim() });
            command.Parameters.Add(new SqlParameter("@HireDate", SqlDbType.DateTime)
            {
                Value = request.HireDate.HasValue ? request.HireDate.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@TerminationDate", SqlDbType.DateTime)
            {
                Value = request.TerminationDate.HasValue ? request.TerminationDate.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@IsPrimaryContact", SqlDbType.Bit) { Value = request.IsPrimaryContact });
            command.Parameters.Add(new SqlParameter("@IsActive", SqlDbType.Bit) { Value = request.IsActive });
            command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250)
            {
                Value = NormalizeActor(actor)
            });
            command.Parameters.Add(new SqlParameter("@StaffDesignationIdFK", SqlDbType.UniqueIdentifier) { Value = DBNull.Value });
            command.Parameters.Add(new SqlParameter("@PrimaryDepartmentIdFK", SqlDbType.UniqueIdentifier)
            {
                Value = request.PrimaryDepartmentId.HasValue ? request.PrimaryDepartmentId.Value : DBNull.Value
            });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetNullableIntOutput(command, "@StatusCode");
            var success = string.IsNullOrWhiteSpace(message) && statusCode == 0;

            return new ClientStaffCommandResult
            {
                Success = success,
                Message = message,
                StatusCode = statusCode,
                ClientStaffId = success ? clientStaffId : null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update client staff {ClientStaffId}.", clientStaffId);
            return new ClientStaffCommandResult
            {
                Success = false,
                Message = "Unable to update client staff right now. Please try again.",
                StatusCode = null,
                ClientStaffId = null
            };
        }
    }

    public async Task<ClientCommandResult> DeleteClientAsync(
        Guid clientId,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (clientId == Guid.Empty)
        {
            return new ClientCommandResult
            {
                Success = false,
                Message = "Please provide a valid client ID.",
                StatusCode = 1,
                ClientId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spDeleteClient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientId", SqlDbType.UniqueIdentifier) { Value = clientId });
            command.Parameters.Add(new SqlParameter("@ClientCode", SqlDbType.VarChar, 50) { Value = string.Empty });
            command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250)
            {
                Value = NormalizeActor(actor)
            });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetNullableIntOutput(command, "@StatusCode");
            var success = string.IsNullOrWhiteSpace(message) && statusCode == 0;

            return new ClientCommandResult
            {
                Success = success,
                Message = message,
                StatusCode = statusCode,
                ClientId = success ? clientId : null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete client {ClientId}.", clientId);
            return new ClientCommandResult
            {
                Success = false,
                Message = "Unable to delete client right now. Please try again.",
                StatusCode = null,
                ClientId = null
            };
        }
    }

    public async Task<ClientDepartmentCommandResult> DeleteClientDepartmentAsync(
        Guid clientDepartmentId,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (clientDepartmentId == Guid.Empty)
        {
            return new ClientDepartmentCommandResult
            {
                Success = false,
                Message = "Please provide a valid client department ID.",
                StatusCode = 1,
                ClientDepartmentId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spDeleteClientDepartment", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientDepartmentId", SqlDbType.UniqueIdentifier) { Value = clientDepartmentId });
            command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250)
            {
                Value = NormalizeActor(actor)
            });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetNullableIntOutput(command, "@StatusCode");
            var success = string.IsNullOrWhiteSpace(message) && statusCode == 0;

            return new ClientDepartmentCommandResult
            {
                Success = success,
                Message = message,
                StatusCode = statusCode,
                ClientDepartmentId = success ? clientDepartmentId : null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete client department {ClientDepartmentId}.", clientDepartmentId);
            return new ClientDepartmentCommandResult
            {
                Success = false,
                Message = "Unable to delete client department right now. Please try again.",
                StatusCode = null,
                ClientDepartmentId = null
            };
        }
    }

    public async Task<ClientStaffCommandResult> DeleteClientStaffAsync(
        Guid clientStaffId,
        string actor,
        CancellationToken cancellationToken = default)
    {
        if (clientStaffId == Guid.Empty)
        {
            return new ClientStaffCommandResult
            {
                Success = false,
                Message = "Please provide a valid client staff ID.",
                StatusCode = 1,
                ClientStaffId = null
            };
        }

        try
        {
            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spDeleteClientStaff", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientStaffId", SqlDbType.UniqueIdentifier) { Value = clientStaffId });
            command.Parameters.Add(new SqlParameter("@StaffCode", SqlDbType.VarChar, 50) { Value = string.Empty });
            command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250)
            {
                Value = NormalizeActor(actor)
            });
            command.Parameters.Add(new SqlParameter("@StatusCode", SqlDbType.Int)
            {
                Direction = ParameterDirection.Output
            });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await command.ExecuteNonQueryAsync(cancellationToken);

            var message = GetStringOutput(command, "@Message");
            var statusCode = GetNullableIntOutput(command, "@StatusCode");
            var success = string.IsNullOrWhiteSpace(message) && statusCode == 0;

            return new ClientStaffCommandResult
            {
                Success = success,
                Message = message,
                StatusCode = statusCode,
                ClientStaffId = success ? clientStaffId : null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete client staff {ClientStaffId}.", clientStaffId);
            return new ClientStaffCommandResult
            {
                Success = false,
                Message = "Unable to delete client staff right now. Please try again.",
                StatusCode = null,
                ClientStaffId = null
            };
        }
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
                Value = ToDbNullableBoolean(query.IsDeleted)
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
                var displayNameOrdinal = TryGetOrdinal(reader, "DisplayName");
                var organizationTypeOrdinal = TryGetOrdinal(reader, "OrganizationType");
                var groupOperatorOrdinal = TryGetOrdinal(reader, "GroupOperator");
                var networkSourcesOrdinal = TryGetOrdinal(reader, "NetworkSources");
                var directoryExternalKeyOrdinal = TryGetOrdinal(reader, "DirectoryExternalKey");
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
                var facilityCityIdOrdinal = TryGetOrdinal(reader, "FacilityCityIDFK");
                var facilityTownOrdinal = TryGetOrdinal(reader, "FacilityTownName");
                var facilityProvinceOrdinal = TryGetOrdinal(reader, "FacilityProvinceName");
                var facilityCountryOrdinal = TryGetOrdinal(reader, "FacilityCountryName");
                var facilityAddressOrdinal = TryGetOrdinal(reader, "FacilityAddressText");
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
                        DisplayName = GetOptionalString(reader, displayNameOrdinal),
                        OrganizationType = GetOptionalString(reader, organizationTypeOrdinal),
                        GroupOperator = GetOptionalString(reader, groupOperatorOrdinal),
                        NetworkSources = GetOptionalString(reader, networkSourcesOrdinal),
                        DirectoryExternalKey = GetOptionalString(reader, directoryExternalKeyOrdinal),
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
                        FacilityCityId = GetOptionalIntNullable(reader, facilityCityIdOrdinal),
                        FacilityTownName = GetOptionalString(reader, facilityTownOrdinal),
                        FacilityProvinceName = GetOptionalString(reader, facilityProvinceOrdinal),
                        FacilityCountryName = GetOptionalString(reader, facilityCountryOrdinal),
                        FacilityAddressText = GetOptionalString(reader, facilityAddressOrdinal),
                        IsActive = GetBoolean(reader, isActiveOrdinal),
                        IsDeleted = GetBoolean(reader, isDeletedOrdinal),
                        CreatedDate = GetDateTime(reader, createdDateOrdinal),
                        UpdatedDate = GetDateTime(reader, updatedDateOrdinal)
                    });
                }
            }

            await PopulatePatientCountsAsync(clients, cancellationToken);

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

    public async Task<ClientLookupResult> GetClientAsync(
        Guid clientId,
        bool includeDeleted,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ClientRecordDto? client = null;

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetClient", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientId", SqlDbType.UniqueIdentifier) { Value = clientId });
            command.Parameters.Add(new SqlParameter("@ClientCode", SqlDbType.VarChar, 50) { Value = string.Empty });
            command.Parameters.Add(new SqlParameter("@IncludeDeleted", SqlDbType.Bit) { Value = includeDeleted });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
            {
                if (await reader.ReadAsync(cancellationToken))
                {
                    var clientIdOrdinal = reader.GetOrdinal("ClientId");
                    var patientIdOrdinal = reader.GetOrdinal("PatientIdFK");
                    var categoryIdOrdinal = reader.GetOrdinal("ClientClinicCategoryIDFK");
                    var categoryNameOrdinal = reader.GetOrdinal("ClientClinicCategoryName");
                    var clinicSizeOrdinal = reader.GetOrdinal("ClinicSize");
                    var ownershipTypeOrdinal = reader.GetOrdinal("OwnershipType");
                    var clientCodeOrdinal = reader.GetOrdinal("ClientCode");
                    var displayNameOrdinal = TryGetOrdinal(reader, "DisplayName");
                    var organizationTypeOrdinal = TryGetOrdinal(reader, "OrganizationType");
                    var groupOperatorOrdinal = TryGetOrdinal(reader, "GroupOperator");
                    var networkSourcesOrdinal = TryGetOrdinal(reader, "NetworkSources");
                    var directoryExternalKeyOrdinal = TryGetOrdinal(reader, "DirectoryExternalKey");
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
                    var facilityCityIdOrdinal = TryGetOrdinal(reader, "FacilityCityIDFK");
                    var facilityTownOrdinal = TryGetOrdinal(reader, "FacilityTownName");
                    var facilityProvinceOrdinal = TryGetOrdinal(reader, "FacilityProvinceName");
                    var facilityCountryOrdinal = TryGetOrdinal(reader, "FacilityCountryName");
                    var facilityAddressOrdinal = TryGetOrdinal(reader, "FacilityAddressText");
                    var isActiveOrdinal = reader.GetOrdinal("IsActive");
                    var isDeletedOrdinal = reader.GetOrdinal("IsDeleted");
                    var createdDateOrdinal = reader.GetOrdinal("CreatedDate");
                    var createdByOrdinal = reader.GetOrdinal("CreatedBy");
                    var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
                    var updatedByOrdinal = reader.GetOrdinal("UpdatedBy");

                    client = new ClientRecordDto
                    {
                        ClientId = reader.GetGuid(clientIdOrdinal),
                        PatientId = GetGuidNullable(reader, patientIdOrdinal),
                        ClientClinicCategoryId = GetIntNullable(reader, categoryIdOrdinal),
                        ClientClinicCategoryName = GetString(reader, categoryNameOrdinal),
                        ClinicSize = GetString(reader, clinicSizeOrdinal),
                        OwnershipType = GetString(reader, ownershipTypeOrdinal),
                        ClientCode = GetString(reader, clientCodeOrdinal),
                        DisplayName = GetOptionalString(reader, displayNameOrdinal),
                        OrganizationType = GetOptionalString(reader, organizationTypeOrdinal),
                        GroupOperator = GetOptionalString(reader, groupOperatorOrdinal),
                        NetworkSources = GetOptionalString(reader, networkSourcesOrdinal),
                        DirectoryExternalKey = GetOptionalString(reader, directoryExternalKeyOrdinal),
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
                        FacilityCityId = GetOptionalIntNullable(reader, facilityCityIdOrdinal),
                        FacilityTownName = GetOptionalString(reader, facilityTownOrdinal),
                        FacilityProvinceName = GetOptionalString(reader, facilityProvinceOrdinal),
                        FacilityCountryName = GetOptionalString(reader, facilityCountryOrdinal),
                        FacilityAddressText = GetOptionalString(reader, facilityAddressOrdinal),
                        IsActive = GetBoolean(reader, isActiveOrdinal),
                        IsDeleted = GetBoolean(reader, isDeletedOrdinal),
                        CreatedDate = GetDateTime(reader, createdDateOrdinal),
                        CreatedBy = GetString(reader, createdByOrdinal),
                        UpdatedDate = GetDateTime(reader, updatedDateOrdinal),
                        UpdatedBy = GetString(reader, updatedByOrdinal)
                    };
                }
            }

            var message = GetStringOutput(command, "@Message");
            if (!string.IsNullOrWhiteSpace(message))
            {
                return new ClientLookupResult
                {
                    Found = false,
                    Message = message,
                    Client = null
                };
            }

            if (client is null)
            {
                return new ClientLookupResult
                {
                    Found = false,
                    Message = "Client not found.",
                    Client = null
                };
            }

            var patientCounts = await GetClientPatientCountsMapAsync([client.ClientId], cancellationToken);
            if (patientCounts.TryGetValue(client.ClientId, out var counts))
            {
                client.RegisteredPatientCount = counts.Registered;
                client.ActivePatientCount = counts.Active;
            }

            return new ClientLookupResult
            {
                Found = true,
                Message = string.Empty,
                Client = client
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch client {ClientId}.", clientId);
            return new ClientLookupResult
            {
                Found = false,
                Message = "Unable to retrieve client right now. Please try again.",
                Client = null
            };
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
                Value = ToDbNullableBoolean(query.IsDeleted)
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
                Value = ToDbNullableBoolean(query.IsDeleted)
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
                var createdByOrdinal = TryGetOrdinal(reader, "CreatedBy");
                var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
                var updatedByOrdinal = TryGetOrdinal(reader, "UpdatedBy");

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
                        CreatedBy = GetOptionalString(reader, createdByOrdinal),
                        UpdatedDate = GetDateTime(reader, updatedDateOrdinal),
                        UpdatedBy = GetOptionalString(reader, updatedByOrdinal)
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

    public async Task<ClientStaffLookupResult> GetClientStaffRecordAsync(
        Guid clientStaffId,
        bool includeDeleted,
        CancellationToken cancellationToken = default)
    {
        try
        {
            ClientStaffDto? staff = null;

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand("Profile.spGetClientStaff", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@ClientStaffId", SqlDbType.UniqueIdentifier) { Value = clientStaffId });
            command.Parameters.Add(new SqlParameter("@StaffCode", SqlDbType.VarChar, 50) { Value = string.Empty });
            command.Parameters.Add(new SqlParameter("@IncludeDeleted", SqlDbType.Bit) { Value = includeDeleted });
            command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)
            {
                Direction = ParameterDirection.Output
            });

            await connection.OpenAsync(cancellationToken);
            await using (var reader = await command.ExecuteReaderAsync(cancellationToken))
            {
                if (await reader.ReadAsync(cancellationToken))
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
                    var createdByOrdinal = reader.GetOrdinal("CreatedBy");
                    var updatedDateOrdinal = reader.GetOrdinal("UpdatedDate");
                    var updatedByOrdinal = reader.GetOrdinal("UpdatedBy");

                    staff = new ClientStaffDto
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
                        CreatedBy = GetString(reader, createdByOrdinal),
                        UpdatedDate = GetDateTime(reader, updatedDateOrdinal),
                        UpdatedBy = GetString(reader, updatedByOrdinal)
                    };
                }
            }

            var message = GetStringOutput(command, "@Message");
            if (!string.IsNullOrWhiteSpace(message))
            {
                return new ClientStaffLookupResult
                {
                    Found = false,
                    Message = message,
                    Staff = null
                };
            }

            if (staff is null)
            {
                return new ClientStaffLookupResult
                {
                    Found = false,
                    Message = "Client staff not found.",
                    Staff = null
                };
            }

            return new ClientStaffLookupResult
            {
                Found = true,
                Message = string.Empty,
                Staff = staff
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch client staff {ClientStaffId}.", clientStaffId);
            return new ClientStaffLookupResult
            {
                Found = false,
                Message = "Unable to retrieve client staff right now. Please try again.",
                Staff = null
            };
        }
    }

    private static object ToDbNullableBoolean(bool? value)
        => value.HasValue ? value.Value : DBNull.Value;

    private static object ToDbString(string? value)
    {
        var trimmed = (value ?? string.Empty).Trim();
        return trimmed.Length > 0 ? trimmed : DBNull.Value;
    }

    private static string NormalizeActor(string actor)
    {
        var trimmed = actor.Trim();
        return trimmed.Length > 0 ? trimmed : "API";
    }

    private async Task PopulatePatientCountsAsync(
        List<ClientDirectoryItemDto> clients,
        CancellationToken cancellationToken)
    {
        var clientIds = clients
            .Select((client) => client.ClientId)
            .Where((clientId) => clientId != Guid.Empty)
            .Distinct()
            .ToArray();

        if (clientIds.Length == 0)
        {
            return;
        }

        var patientCounts = await GetClientPatientCountsMapAsync(clientIds, cancellationToken);
        foreach (var client in clients)
        {
            if (!patientCounts.TryGetValue(client.ClientId, out var counts))
            {
                continue;
            }

            client.RegisteredPatientCount = counts.Registered;
            client.ActivePatientCount = counts.Active;
        }
    }

    private async Task<Dictionary<Guid, (int Registered, int Active)>> GetClientPatientCountsMapAsync(
        IReadOnlyCollection<Guid> clientIds,
        CancellationToken cancellationToken)
    {
        if (clientIds.Count == 0)
        {
            return [];
        }

        try
        {
            var parameterNames = clientIds
                .Select((_, index) => $"@ClientId{index}")
                .ToArray();

            var counts = new Dictionary<Guid, (int Registered, int Active)>();

            await using var connection = new SqlConnection(GetConnectionString());
            await using var command = new SqlCommand(
                $"""
                 SELECT
                     PC.ClientIdFK,
                     COUNT(1) AS RegisteredPatientCount,
                     SUM(CASE WHEN P.IsDeleted = 0 THEN 1 ELSE 0 END) AS ActivePatientCount
                 FROM Profile.PatientClients PC
                 INNER JOIN Profile.Patient P
                     ON P.PatientId = PC.PatientIdFK
                 WHERE PC.ClientIdFK IN ({string.Join(", ", parameterNames)})
                 GROUP BY PC.ClientIdFK;
                 """,
                connection);

            var index = 0;
            foreach (var clientId in clientIds)
            {
                command.Parameters.Add(new SqlParameter(parameterNames[index], SqlDbType.UniqueIdentifier) { Value = clientId });
                index += 1;
            }

            await connection.OpenAsync(cancellationToken);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var clientIdOrdinal = reader.GetOrdinal("ClientIdFK");
            var registeredOrdinal = reader.GetOrdinal("RegisteredPatientCount");
            var activeOrdinal = reader.GetOrdinal("ActivePatientCount");

            while (await reader.ReadAsync(cancellationToken))
            {
                var clientId = reader.IsDBNull(clientIdOrdinal) ? Guid.Empty : reader.GetGuid(clientIdOrdinal);
                if (clientId == Guid.Empty)
                {
                    continue;
                }

                counts[clientId] = (GetInt(reader, registeredOrdinal), GetInt(reader, activeOrdinal));
            }

            return counts;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to resolve patient counts for client directory results.");
            return [];
        }
    }

    private static bool HasAddress(string? line1, string? line2, int? cityId)
        => !string.IsNullOrWhiteSpace(line1)
           && !string.IsNullOrWhiteSpace(line2)
           && cityId.HasValue
           && cityId.Value > 0;

    private static bool HasPartialAddress(string? line1, string? line2, int? cityId)
    {
        var hasAnyAddressInput =
            !string.IsNullOrWhiteSpace(line1)
            || !string.IsNullOrWhiteSpace(line2)
            || cityId.HasValue;

        return hasAnyAddressInput && !HasAddress(line1, line2, cityId);
    }

    // Client create expects an existing address ID, so the API builds the address row
    // first and lets the transaction keep both inserts in sync.
    private static async Task<Guid> InsertAddressAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        string? line1,
        string? line2,
        int? cityId,
        string actor,
        CancellationToken cancellationToken)
    {
        var addressId = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var normalizedLine1 = line1?.Trim() ?? string.Empty;
        var normalizedLine2 = line2?.Trim() ?? string.Empty;
        var normalizedCityId = cityId ?? 0;

        await using var command = new SqlCommand(
            """
            INSERT INTO Location.Address
            (
                AddressId,
                Line1,
                Line2,
                CityIDFK,
                UpdateDate,
                CreatedDate,
                CreatedBy,
                UpdatedBy
            )
            VALUES
            (
                @AddressId,
                @Line1,
                @Line2,
                @CityIDFK,
                @UpdateDate,
                @CreatedDate,
                @CreatedBy,
                @UpdatedBy
            );
            """,
            connection,
            transaction);

        command.Parameters.Add(new SqlParameter("@AddressId", SqlDbType.UniqueIdentifier) { Value = addressId });
        command.Parameters.Add(new SqlParameter("@Line1", SqlDbType.VarChar, 250) { Value = normalizedLine1 });
        command.Parameters.Add(new SqlParameter("@Line2", SqlDbType.VarChar, 250) { Value = normalizedLine2 });
        command.Parameters.Add(new SqlParameter("@CityIDFK", SqlDbType.Int) { Value = normalizedCityId });
        command.Parameters.Add(new SqlParameter("@UpdateDate", SqlDbType.DateTime) { Value = now });
        command.Parameters.Add(new SqlParameter("@CreatedDate", SqlDbType.DateTime) { Value = now });
        command.Parameters.Add(new SqlParameter("@CreatedBy", SqlDbType.VarChar, 250) { Value = NormalizeActor(actor) });
        command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250) { Value = NormalizeActor(actor) });

        await command.ExecuteNonQueryAsync(cancellationToken);
        return addressId;
    }

    private static async Task<Guid> UpdateAddressAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        Guid addressId,
        string? line1,
        string? line2,
        int? cityId,
        string actor,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var normalizedLine1 = line1?.Trim() ?? string.Empty;
        var normalizedLine2 = line2?.Trim() ?? string.Empty;
        var normalizedCityId = cityId ?? 0;

        await using var command = new SqlCommand(
            """
            UPDATE Location.Address
            SET Line1 = @Line1,
                Line2 = @Line2,
                CityIDFK = @CityIDFK,
                UpdateDate = @UpdateDate,
                UpdatedBy = @UpdatedBy
            WHERE AddressId = @AddressId;
            """,
            connection,
            transaction);

        command.Parameters.Add(new SqlParameter("@AddressId", SqlDbType.UniqueIdentifier) { Value = addressId });
        command.Parameters.Add(new SqlParameter("@Line1", SqlDbType.VarChar, 250) { Value = normalizedLine1 });
        command.Parameters.Add(new SqlParameter("@Line2", SqlDbType.VarChar, 250) { Value = normalizedLine2 });
        command.Parameters.Add(new SqlParameter("@CityIDFK", SqlDbType.Int) { Value = normalizedCityId });
        command.Parameters.Add(new SqlParameter("@UpdateDate", SqlDbType.DateTime) { Value = now });
        command.Parameters.Add(new SqlParameter("@UpdatedBy", SqlDbType.VarChar, 250) { Value = NormalizeActor(actor) });

        await command.ExecuteNonQueryAsync(cancellationToken);
        return addressId;
    }

    // Update needs the current address pointer so we can decide whether to update the
    // existing address row, create one, or clear the link altogether.
    private static async Task<Guid?> TryGetClientAddressIdAsync(
        SqlConnection connection,
        SqlTransaction transaction,
        Guid clientId,
        CancellationToken cancellationToken)
    {
        await using var command = new SqlCommand(
            """
            SELECT AddressIDFK
            FROM Profile.Clients
            WHERE ClientId = @ClientId
              AND IsDeleted = 0;
            """,
            connection,
            transaction);

        command.Parameters.Add(new SqlParameter("@ClientId", SqlDbType.UniqueIdentifier) { Value = clientId });

        var value = await command.ExecuteScalarAsync(cancellationToken);
        if (value is null)
        {
            return MissingClient;
        }

        if (value == DBNull.Value)
        {
            return null;
        }

        return value is Guid addressId
            ? addressId
            : Guid.Parse(Convert.ToString(value) ?? string.Empty);
    }

    private static readonly Guid MissingClient = Guid.Empty;

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

    private static string GetOptionalString(SqlDataReader reader, int? ordinal)
        => ordinal.HasValue ? GetString(reader, ordinal.Value) : string.Empty;

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

    private static int? GetOptionalIntNullable(SqlDataReader reader, int? ordinal)
        => ordinal.HasValue ? GetIntNullable(reader, ordinal.Value) : null;

    private static Guid? GetGuidNullable(SqlDataReader reader, int ordinal)
    {
        if (reader.IsDBNull(ordinal))
        {
            return null;
        }

        return reader.GetGuid(ordinal);
    }

    private static int? TryGetOrdinal(SqlDataReader reader, string columnName)
    {
        try
        {
            return reader.GetOrdinal(columnName);
        }
        catch (IndexOutOfRangeException)
        {
            return null;
        }
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

    private static int? GetNullableIntOutput(SqlCommand command, string name)
    {
        if (!command.Parameters.Contains(name))
        {
            return null;
        }

        var value = command.Parameters[name].Value;
        if (value is null || value == DBNull.Value)
        {
            return null;
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

    private static Guid? GetGuidOutput(SqlCommand command, string name)
    {
        if (!command.Parameters.Contains(name))
        {
            return null;
        }

        var value = command.Parameters[name].Value;
        if (value is null || value == DBNull.Value)
        {
            return null;
        }

        return value is Guid guid ? guid : Guid.Parse(Convert.ToString(value) ?? string.Empty);
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
