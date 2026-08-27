using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace HealthcareForm.Contracts.Patients;

internal static class PatientRequestRules
{
    private static readonly Regex IdNumberRegex = new(
        @"^\d{13}$",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);

    public static bool IsValidIdNumber(string? value)
        => IdNumberRegex.IsMatch(NormalizeText(value));

    public static string NormalizeText(string? value)
        => (value ?? string.Empty).Trim();

    public static DateTime NormalizeDate(DateTime value)
        => value == default ? default : value.Date;

    public static IEnumerable<ValidationResult> ValidateRequiredDate(DateTime value, string memberName, string displayName)
    {
        if (NormalizeDate(value) == default)
        {
            yield return new ValidationResult(
                $"{displayName} is required.",
                [memberName]);
        }
    }
}
