using HealthcareForm.Contracts.Patients;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.PatientsRead)]
[Route("api/patients")]
public sealed class PatientsController : ControllerBase
{
    private readonly IPatientService _patientService;

    public PatientsController(IPatientService patientService)
    {
        _patientService = patientService;
    }

    [HttpGet("worklist")]
    public async Task<ActionResult<IReadOnlyList<PatientWorklistItemDto>>> GetWorklist(CancellationToken cancellationToken)
        => Ok(await _patientService.GetWorklistAsync(cancellationToken));

    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.PatientsWrite)]
    public async Task<ActionResult<PatientCommandResult>> CreatePatient([FromBody] PatientCreateRequest request, CancellationToken cancellationToken)
    {
        var result = await _patientService.AddPatientAsync(request, cancellationToken);

        if (result.Success)
        {
            return CreatedAtAction(nameof(GetPatientByIdNumber), new { idNumber = request.IdNumber }, result);
        }

        return result.StatusCode switch
        {
            1 => BadRequest(result),
            2 => Conflict(result),
            _ => StatusCode(StatusCodes.Status500InternalServerError, result)
        };
    }

    [HttpGet("{idNumber}")]
    public async Task<ActionResult<PatientRecordDto>> GetPatientByIdNumber(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        var result = await _patientService.GetPatientAsync(idNumber, cancellationToken);
        if (!result.Found)
        {
            if (result.Message.StartsWith("Unable to retrieve", StringComparison.OrdinalIgnoreCase))
            {
                return StatusCode(StatusCodes.Status500InternalServerError, result);
            }

            return NotFound(result);
        }

        return Ok(result.Patient);
    }

    [HttpGet("{idNumber}/allergies")]
    public async Task<ActionResult<IReadOnlyList<PatientAllergyDto>>> GetPatientAllergies(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientAllergiesAsync(idNumber, cancellationToken));
    }

    [HttpGet("{idNumber}/medications")]
    public async Task<ActionResult<IReadOnlyList<PatientMedicationDto>>> GetPatientMedications(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientMedicationsAsync(idNumber, cancellationToken));
    }

    [HttpGet("{idNumber}/vaccinations")]
    public async Task<ActionResult<IReadOnlyList<PatientVaccinationDto>>> GetPatientVaccinations(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientVaccinationsAsync(idNumber, cancellationToken));
    }

    [HttpGet("{idNumber}/consultation-notes")]
    public async Task<ActionResult<IReadOnlyList<PatientConsultationNoteDto>>> GetPatientConsultationNotes(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientConsultationNotesAsync(idNumber, cancellationToken));
    }

    [HttpGet("{idNumber}/referrals")]
    public async Task<ActionResult<IReadOnlyList<PatientReferralDto>>> GetPatientReferrals(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientReferralsAsync(idNumber, cancellationToken));
    }

    [HttpDelete("{idNumber}")]
    [Authorize(Policy = AuthorizationPolicies.PatientsDelete)]
    public async Task<ActionResult<PatientCommandResult>> DeletePatient(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        var result = await _patientService.DeletePatientAsync(idNumber, cancellationToken);
        if (!result.Success)
        {
            if (result.Message.StartsWith("Unable to delete", StringComparison.OrdinalIgnoreCase))
            {
                return StatusCode(StatusCodes.Status500InternalServerError, result);
            }

            return NotFound(result);
        }

        return Ok(result);
    }

    [HttpPut("{idNumber}")]
    [Authorize(Policy = AuthorizationPolicies.PatientsWrite)]
    public async Task<ActionResult<PatientCommandResult>> UpdatePatient(
        string idNumber,
        [FromBody] PatientUpdateRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        var result = await _patientService.UpdatePatientAsync(idNumber, request, cancellationToken);
        if (result.Success)
        {
            return Ok(result);
        }

        if (result.Message.StartsWith("Unable to update", StringComparison.OrdinalIgnoreCase))
        {
            return StatusCode(StatusCodes.Status500InternalServerError, result);
        }

        if (result.Message.Contains("does not exist", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(result);
        }

        return BadRequest(result);
    }
}
