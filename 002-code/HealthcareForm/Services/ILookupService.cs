using HealthcareForm.Contracts.Lookups;

namespace HealthcareForm.Services;

public interface ILookupService
{
    Task<IReadOnlyList<LookupOptionDto>> GetGendersAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<LookupOptionDto>> GetMaritalStatusesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<LookupOptionDto>> GetCountriesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<LookupOptionDto>> GetProvincesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<LookupOptionDto>> GetCitiesAsync(CancellationToken cancellationToken = default);
}
