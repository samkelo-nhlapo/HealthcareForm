using HealthcareForm.Contracts.Patients;
using HealthcareForm.Controllers.Api;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

namespace HealthcareForm.Tests;

public sealed class PatientsControllerTests
{
    [Fact]
    public async Task RestorePatient_ReturnsBadRequest_WhenIdNumberIsBlank()
    {
        var controller = new PatientsController(new FakePatientService());

        var result = await controller.RestorePatient(" ", CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.Equal(400, badRequest.StatusCode);
    }

    [Fact]
    public async Task GetPatientByIdNumber_ReturnsBadRequest_WhenIdNumberIsNotExactDigits()
    {
        var controller = new PatientsController(new FakePatientService());

        var result = await controller.GetPatientByIdNumber("ABC1234567890", CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.Equal(400, badRequest.StatusCode);
    }

    [Fact]
    public async Task RestorePatient_ReturnsOk_WhenServiceSucceeds()
    {
        var controller = new PatientsController(new FakePatientService
        {
            RestoreResult = new PatientCommandResult
            {
                Success = true,
                Message = string.Empty,
                StatusCode = 0
            }
        });

        var result = await controller.RestorePatient("0000000000000", CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<PatientCommandResult>(ok.Value);
        Assert.True(payload.Success);
        Assert.Equal(0, payload.StatusCode);
    }

    [Fact]
    public async Task RestorePatient_ReturnsNotFound_WhenServiceReturnsBusinessFailure()
    {
        var controller = new PatientsController(new FakePatientService
        {
            RestoreResult = new PatientCommandResult
            {
                Success = false,
                Message = "Patient does not exist.",
                StatusCode = 1
            }
        });

        var result = await controller.RestorePatient("0000000000000", CancellationToken.None);

        var notFound = Assert.IsType<NotFoundObjectResult>(result.Result);
        var payload = Assert.IsType<PatientCommandResult>(notFound.Value);
        Assert.False(payload.Success);
    }

    [Fact]
    public async Task CreatePatient_ReturnsCreated_WhenServiceSucceeds()
    {
        var createdPatientId = Guid.NewGuid();
        var service = new FakePatientService
        {
            CreateResult = new PatientCommandResult
            {
                Success = true,
                Message = string.Empty,
                StatusCode = 0,
                PatientId = createdPatientId
            }
        };

        var controller = new PatientsController(service);
        var request = new PatientCreateRequest
        {
            PrimaryClientId = Guid.NewGuid(),
            SecondaryClientIds = [Guid.NewGuid()],
            FirstName = "Sam",
            LastName = "Patient",
            IdNumber = "0000000000000",
            DateOfBirth = new DateTime(1990, 1, 1),
            GenderId = 1,
            PhoneNumber = "0123456789",
            Email = "sam@example.com",
            Line1 = "Line 1",
            Line2 = "Line 2",
            CityId = 1,
            ProvinceId = 1,
            CountryId = 1,
            MaritalStatusId = 1,
            EmergencyName = "Alex",
            EmergencyLastName = "Contact",
            EmergencyPhoneNumber = "0987654321",
            Relationship = "Sibling",
            EmergencyDateOfBirth = new DateTime(1988, 1, 1),
            MedicationList = "None"
        };

        var result = await controller.CreatePatient(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.Equal(nameof(PatientsController.GetPatientByIdNumber), created.ActionName);
        var payload = Assert.IsType<PatientCommandResult>(created.Value);
        Assert.True(payload.Success);
        Assert.Equal(createdPatientId, payload.PatientId);
        Assert.Same(request, service.LastCreateRequest);
        Assert.Equal(request.PrimaryClientId, service.LastCreateRequest?.PrimaryClientId);
        Assert.Equal(request.SecondaryClientIds, service.LastCreateRequest?.SecondaryClientIds);
    }

    [Fact]
    public async Task CreatePatient_ReturnsBadRequest_WhenServiceReportsValidationFailure()
    {
        var controller = new PatientsController(new FakePatientService
        {
            CreateResult = new PatientCommandResult
            {
                Success = false,
                Message = "Please select a primary clinic or hospital for the patient.",
                StatusCode = 1
            }
        });

        var result = await controller.CreatePatient(new PatientCreateRequest
        {
            PrimaryClientId = null,
            FirstName = "Sam",
            LastName = "Patient",
            IdNumber = "0000000000000",
            DateOfBirth = new DateTime(1990, 1, 1),
            GenderId = 1,
            PhoneNumber = "0123456789",
            Email = "sam@example.com",
            Line1 = "Line 1",
            Line2 = "Line 2",
            CityId = 1,
            ProvinceId = 1,
            CountryId = 1,
            MaritalStatusId = 1,
            EmergencyName = "Alex",
            EmergencyLastName = "Contact",
            EmergencyPhoneNumber = "0987654321",
            Relationship = "Sibling",
            EmergencyDateOfBirth = new DateTime(1988, 1, 1)
        }, CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result.Result);
        var payload = Assert.IsType<PatientCommandResult>(badRequest.Value);
        Assert.False(payload.Success);
        Assert.Equal(1, payload.StatusCode);
    }

    [Fact]
    public async Task UpdatePatient_ReturnsBadRequest_WhenRouteIdNumberIsNotExactDigits()
    {
        var controller = new PatientsController(new FakePatientService());

        var result = await controller.UpdatePatient(
            "ABC1234567890",
            new PatientUpdateRequest(),
            CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.Equal(400, badRequest.StatusCode);
    }

    [Fact]
    public async Task GetDirectory_ReturnsSnapshot_WithClientAssignments()
    {
        var clientId = Guid.NewGuid();
        var secondaryClientId = Guid.NewGuid();
        var service = new FakePatientService
        {
            DirectoryResult = new PatientDirectorySnapshotDto
            {
                TotalRecords = 1,
                Patients =
                [
                    new PatientDirectoryItemDto
                    {
                        PatientId = Guid.NewGuid(),
                        FirstName = "Sam",
                        LastName = "Patient",
                        IdNumber = "0000000000000",
                        ClientId = clientId,
                        ClientCode = "CLI-001",
                        ClientName = "Hope Clinic",
                        ClientClinicCategoryName = "Clinic",
                        Clients =
                        [
                            new PatientClientAssignmentDto
                            {
                                ClientId = clientId,
                                ClientCode = "CLI-001",
                                ClientName = "Hope Clinic",
                                ClientClinicCategoryName = "Clinic",
                                IsPrimary = true
                            },
                            new PatientClientAssignmentDto
                            {
                                ClientId = secondaryClientId,
                                ClientCode = "HSP-002",
                                ClientName = "Central Hospital",
                                ClientClinicCategoryName = "Hospital",
                                IsPrimary = false
                            }
                        ]
                    }
                ]
            }
        };

        var controller = new PatientsController(service);
        var query = new PatientDirectoryQueryDto { ClientId = clientId, PageNumber = 1, PageSize = 25 };

        var result = await controller.GetDirectory(query, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<PatientDirectorySnapshotDto>(ok.Value);
        Assert.Equal(1, payload.TotalRecords);
        Assert.Single(payload.Patients);
        Assert.Equal(2, payload.Patients[0].Clients.Count);
        Assert.Equal(clientId, service.LastDirectoryQuery?.ClientId);
    }

    [Fact]
    public async Task GetPatientOrdersResults_ReturnsBadRequest_WhenIdNumberIsNotExactDigits()
    {
        var controller = new PatientsController(new FakePatientService());

        var result = await controller.GetPatientOrdersResults("ABC1234567890", CancellationToken.None);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.Equal(400, badRequest.StatusCode);
    }

    [Fact]
    public async Task GetPatientOrdersResults_ReturnsOk_WhenServiceSucceeds()
    {
        var snapshot = new PatientOrdersResultsSnapshotDto
        {
            PendingOrders =
            [
                new PatientPendingOrderDto
                {
                    LabResultId = Guid.NewGuid(),
                    TestName = "CBC with differential",
                    SpecimenType = "Blood",
                    Status = "Pending",
                    OrderedBy = "Dr Moyo"
                }
            ],
            Results =
            [
                new PatientLabResultDto
                {
                    LabResultId = Guid.NewGuid(),
                    TestName = "Potassium",
                    ResultValue = "5.9",
                    Unit = "mmol/L",
                    ReferenceRange = "3.5 - 5.1",
                    Severity = "Critical"
                }
            ]
        };

        var controller = new PatientsController(new FakePatientService
        {
            OrdersResultsResult = snapshot
        });

        var result = await controller.GetPatientOrdersResults("0000000000000", CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<PatientOrdersResultsSnapshotDto>(ok.Value);
        Assert.Single(payload.PendingOrders);
        Assert.Single(payload.Results);
        Assert.Equal("Critical", payload.Results[0].Severity);
    }

    [Fact]
    public void PatientCreateRequest_FailsValidation_WithoutPrimaryClient()
    {
        var request = new PatientCreateRequest
        {
            PrimaryClientId = null,
            FirstName = "Sam",
            LastName = "Patient",
            IdNumber = "0000000000000",
            DateOfBirth = new DateTime(1990, 1, 1),
            GenderId = 1,
            PhoneNumber = "0123456789",
            Email = "sam@example.com",
            Line1 = "Line 1",
            Line2 = "Line 2",
            CityId = 1,
            ProvinceId = 1,
            CountryId = 1,
            MaritalStatusId = 1,
            EmergencyName = "Alex",
            EmergencyLastName = "Contact",
            EmergencyPhoneNumber = "0987654321",
            Relationship = "Sibling",
            EmergencyDateOfBirth = new DateTime(1988, 1, 1)
        };

        var validationResults = Validate(request);

        Assert.Contains(validationResults, (result) => result.MemberNames.Contains(nameof(PatientCreateRequest.PrimaryClientId)));
    }

    [Fact]
    public void PatientCreateRequest_FailsValidation_WhenIdNumberIsNotExactDigits()
    {
        var request = new PatientCreateRequest
        {
            PrimaryClientId = Guid.NewGuid(),
            FirstName = "Sam",
            LastName = "Patient",
            IdNumber = "ABC1234567890",
            DateOfBirth = new DateTime(1990, 1, 1),
            GenderId = 1,
            PhoneNumber = "0123456789",
            Email = "sam@example.com",
            Line1 = "Line 1",
            Line2 = "Line 2",
            CityId = 1,
            ProvinceId = 1,
            CountryId = 1,
            MaritalStatusId = 1,
            EmergencyName = "Alex",
            EmergencyLastName = "Contact",
            EmergencyPhoneNumber = "0987654321",
            Relationship = "Sibling",
            EmergencyDateOfBirth = new DateTime(1988, 1, 1)
        };

        var validationResults = Validate(request);

        Assert.Contains(validationResults, result => result.MemberNames.Contains(nameof(PatientCreateRequest.IdNumber)));
    }

    [Fact]
    public void PatientCreateRequest_FailsValidation_WhenEmergencyDateOfBirthIsMissing()
    {
        var request = new PatientCreateRequest
        {
            PrimaryClientId = Guid.NewGuid(),
            FirstName = "Sam",
            LastName = "Patient",
            IdNumber = "0000000000000",
            DateOfBirth = new DateTime(1990, 1, 1),
            GenderId = 1,
            PhoneNumber = "0123456789",
            Email = "sam@example.com",
            Line1 = "Line 1",
            Line2 = "Line 2",
            CityId = 1,
            ProvinceId = 1,
            CountryId = 1,
            MaritalStatusId = 1,
            EmergencyName = "Alex",
            EmergencyLastName = "Contact",
            EmergencyPhoneNumber = "0987654321",
            Relationship = "Sibling",
            EmergencyDateOfBirth = default
        };

        var validationResults = Validate(request);

        Assert.Contains(validationResults, result => result.MemberNames.Contains(nameof(PatientCreateRequest.EmergencyDateOfBirth)));
    }

    [Fact]
    public void PatientCreateRequest_PassesValidation_WithPrimaryAndSecondaryClients()
    {
        var request = new PatientCreateRequest
        {
            PrimaryClientId = Guid.NewGuid(),
            SecondaryClientIds = [Guid.NewGuid(), Guid.NewGuid()],
            FirstName = "Sam",
            LastName = "Patient",
            IdNumber = "0000000000000",
            DateOfBirth = new DateTime(1990, 1, 1),
            GenderId = 1,
            PhoneNumber = "0123456789",
            Email = "sam@example.com",
            Line1 = "Line 1",
            Line2 = "Line 2",
            CityId = 1,
            ProvinceId = 1,
            CountryId = 1,
            MaritalStatusId = 1,
            EmergencyName = "Alex",
            EmergencyLastName = "Contact",
            EmergencyPhoneNumber = "0987654321",
            Relationship = "Sibling",
            EmergencyDateOfBirth = new DateTime(1988, 1, 1)
        };

        var validationResults = Validate(request);

        Assert.Empty(validationResults);
    }

    [Fact]
    public void PatientUpdateRequest_FailsValidation_WhenEmergencyDateOfBirthIsMissing()
    {
        var request = new PatientUpdateRequest
        {
            PrimaryClientId = Guid.NewGuid(),
            FirstName = "Sam",
            LastName = "Patient",
            DateOfBirth = new DateTime(1990, 1, 1),
            GenderId = 1,
            PhoneNumber = "0123456789",
            Email = "sam@example.com",
            Line1 = "Line 1",
            Line2 = "Line 2",
            CityId = 1,
            ProvinceId = 1,
            CountryId = 1,
            MaritalStatusId = 1,
            EmergencyName = "Alex",
            EmergencyLastName = "Contact",
            EmergencyPhoneNumber = "0987654321",
            Relationship = "Sibling",
            EmergencyDateOfBirth = default
        };

        var validationResults = Validate(request);

        Assert.Contains(validationResults, result => result.MemberNames.Contains(nameof(PatientUpdateRequest.EmergencyDateOfBirth)));
    }

    private static List<ValidationResult> Validate(object instance)
    {
        var validationResults = new List<ValidationResult>();
        Validator.TryValidateObject(instance, new ValidationContext(instance), validationResults, validateAllProperties: true);
        return validationResults;
    }

    private sealed class FakePatientService : IPatientService
    {
        public PatientCommandResult CreateResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null,
            PatientId = null
        };

        public PatientCommandResult RestoreResult { get; init; } = new()
        {
            Success = false,
            Message = "Not configured.",
            StatusCode = null
        };

        public PatientDirectorySnapshotDto DirectoryResult { get; init; } = new();
        public PatientOrdersResultsSnapshotDto OrdersResultsResult { get; init; } = new();
        public PatientCreateRequest? LastCreateRequest { get; private set; }
        public PatientDirectoryQueryDto? LastDirectoryQuery { get; private set; }

        public Task<IReadOnlyList<PatientWorklistItemDto>> GetWorklistAsync(CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<PatientDirectorySnapshotDto> GetDirectoryAsync(PatientDirectoryQueryDto query, CancellationToken cancellationToken = default)
        {
            LastDirectoryQuery = query;
            return Task.FromResult(DirectoryResult);
        }

        public Task<IReadOnlyList<PatientClientLookupItemDto>> GetClientLookupAsync(CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<PatientCommandResult> AddPatientAsync(PatientCreateRequest request, CancellationToken cancellationToken = default)
        {
            LastCreateRequest = request;
            return Task.FromResult(CreateResult);
        }

        public Task<PatientCommandResult> UpdatePatientAsync(string idNumber, PatientUpdateRequest request, CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<PatientLookupResult> GetPatientAsync(string idNumber, CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<PatientCommandResult> DeletePatientAsync(string idNumber, CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<PatientCommandResult> RestorePatientAsync(string idNumber, CancellationToken cancellationToken = default)
            => Task.FromResult(RestoreResult);

        public Task<IReadOnlyList<PatientAllergyDto>> GetPatientAllergiesAsync(string idNumber, CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<IReadOnlyList<PatientMedicationDto>> GetPatientMedicationsAsync(string idNumber, CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<PatientOrdersResultsSnapshotDto> GetPatientOrdersResultsAsync(string idNumber, CancellationToken cancellationToken = default)
            => Task.FromResult(OrdersResultsResult);

        public Task<IReadOnlyList<PatientVaccinationDto>> GetPatientVaccinationsAsync(string idNumber, CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<IReadOnlyList<PatientConsultationNoteDto>> GetPatientConsultationNotesAsync(string idNumber, CancellationToken cancellationToken = default)
            => throw new NotImplementedException();

        public Task<IReadOnlyList<PatientReferralDto>> GetPatientReferralsAsync(string idNumber, CancellationToken cancellationToken = default)
            => throw new NotImplementedException();
    }
}
