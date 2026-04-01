using HealthcareForm.Contracts.Patients;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

// Patient-facing API endpoints used by the clinical workspace.
// Read operations use PatientsRead; create, update, and delete tighten access as needed.
[ApiController]
[Authorize(Policy = AuthorizationPolicies.PatientsRead)]
[Produces("application/json")]
[Route("api/patients")]
public sealed class PatientsController : ControllerBase
{
    private readonly IPatientService _patientService;

    public PatientsController(IPatientService patientService)
    {
        _patientService = patientService;
    }

    // Returns the patient worklist shown on the main clinical dashboard.
    [HttpGet("worklist")]
    [ProducesResponseType(typeof(IReadOnlyList<PatientWorklistItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<PatientWorklistItemDto>>> GetWorklist(CancellationToken cancellationToken)
        => Ok(await _patientService.GetWorklistAsync(cancellationToken));

    // Creates a new patient record.
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.PatientsWrite)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status409Conflict)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
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

    // Looks up a patient by national ID number.
    [HttpGet("{idNumber}")]
    [ProducesResponseType(typeof(PatientRecordDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(PatientLookupResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(PatientLookupResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
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

    // Returns allergy records for the requested patient.
    [HttpGet("{idNumber}/allergies")]
    [ProducesResponseType(typeof(IReadOnlyList<PatientAllergyDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<PatientAllergyDto>>> GetPatientAllergies(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientAllergiesAsync(idNumber, cancellationToken));
    }

    // Returns active and historical medications for the requested patient.
    [HttpGet("{idNumber}/medications")]
    [ProducesResponseType(typeof(IReadOnlyList<PatientMedicationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<PatientMedicationDto>>> GetPatientMedications(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientMedicationsAsync(idNumber, cancellationToken));
    }

    // Returns vaccination history for the requested patient.
    [HttpGet("{idNumber}/vaccinations")]
    [ProducesResponseType(typeof(IReadOnlyList<PatientVaccinationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<PatientVaccinationDto>>> GetPatientVaccinations(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientVaccinationsAsync(idNumber, cancellationToken));
    }

    // Returns consultation notes for the requested patient.
    [HttpGet("{idNumber}/consultation-notes")]
    [ProducesResponseType(typeof(IReadOnlyList<PatientConsultationNoteDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<PatientConsultationNoteDto>>> GetPatientConsultationNotes(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientConsultationNotesAsync(idNumber, cancellationToken));
    }

    // Returns referral history for the requested patient.
    [HttpGet("{idNumber}/referrals")]
    [ProducesResponseType(typeof(IReadOnlyList<PatientReferralDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<PatientReferralDto>>> GetPatientReferrals(string idNumber, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(idNumber))
        {
            return BadRequest(new { Message = "Please provide an ID number." });
        }

        return Ok(await _patientService.GetPatientReferralsAsync(idNumber, cancellationToken));
    }

    // Soft-deletes a patient record identified by national ID number.
    [HttpDelete("{idNumber}")]
    [Authorize(Policy = AuthorizationPolicies.PatientsDelete)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
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

    // Updates an existing patient record.
    [HttpPut("{idNumber}")]
    [Authorize(Policy = AuthorizationPolicies.PatientsWrite)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(PatientCommandResult), StatusCodes.Status500InternalServerError)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
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
