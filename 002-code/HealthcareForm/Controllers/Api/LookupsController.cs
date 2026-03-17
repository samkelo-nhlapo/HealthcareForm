using HealthcareForm.Contracts.Lookups;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Authorize(Policy = AuthorizationPolicies.LookupsRead)]
[Route("api/lookups")]
public sealed class LookupsController : ControllerBase
{
    private readonly ILookupService _lookupService;

    public LookupsController(ILookupService lookupService)
    {
        _lookupService = lookupService;
    }

    [HttpGet("genders")]
    public async Task<ActionResult<IReadOnlyList<LookupOptionDto>>> GetGenders(CancellationToken cancellationToken)
        => Ok(await _lookupService.GetGendersAsync(cancellationToken));

    [HttpGet("marital-statuses")]
    public async Task<ActionResult<IReadOnlyList<LookupOptionDto>>> GetMaritalStatuses(CancellationToken cancellationToken)
        => Ok(await _lookupService.GetMaritalStatusesAsync(cancellationToken));

    [HttpGet("countries")]
    public async Task<ActionResult<IReadOnlyList<LookupOptionDto>>> GetCountries(CancellationToken cancellationToken)
        => Ok(await _lookupService.GetCountriesAsync(cancellationToken));

    [HttpGet("provinces")]
    public async Task<ActionResult<IReadOnlyList<LookupOptionDto>>> GetProvinces(CancellationToken cancellationToken)
        => Ok(await _lookupService.GetProvincesAsync(cancellationToken));

    [HttpGet("cities")]
    public async Task<ActionResult<IReadOnlyList<LookupOptionDto>>> GetCities(CancellationToken cancellationToken)
        => Ok(await _lookupService.GetCitiesAsync(cancellationToken));

    [HttpGet("allergies")]
    public async Task<ActionResult<IReadOnlyList<AllergyLookupDto>>> GetAllergies(CancellationToken cancellationToken)
        => Ok(await _lookupService.GetAllergiesAsync(cancellationToken));

    [HttpGet("medications")]
    public async Task<ActionResult<IReadOnlyList<MedicationLookupDto>>> GetMedications(CancellationToken cancellationToken)
        => Ok(await _lookupService.GetMedicationsAsync(cancellationToken));
}
