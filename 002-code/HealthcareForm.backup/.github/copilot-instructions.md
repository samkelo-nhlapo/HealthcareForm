# Healthcare Form - Copilot Instructions

## Project Overview
A healthcare patient management system built with ASP.NET MVC 5 and Entity Framework. The application manages patient profiles, demographic data, and emergency contact information through a SQL Server backend.

## Architecture & Data Flow

### Core Structure
- **Framework**: ASP.NET MVC 5 (.NET 4.7.2) with Entity Framework 6.4.4
- **Database**: SQL Server with stored procedure-based operations (not direct EF queries)
- **Entry Point**: `Global.asax.cs` - Configures routing, filters, and bundles at application start

### Request Pattern: Controller → Stored Procedure → View
All database operations route through stored procedures in SQL Server via raw `SqlConnection` and `SqlCommand`:

1. **Models** (`MainModel.cs`, `GetPatientModel.cs`) - Data transfer objects with validation attributes
2. **Controllers** - Call stored procedures directly, marshal parameters, return JSON responses
3. **Database** - Execution handled by stored procedures in `Profile.*` and `Location.*` schemas

**Example from AddPatientController**:
```csharp
SqlCommand cmd = new SqlCommand("Profile.spAddPatientProfile", conn);
cmd.CommandType = CommandType.StoredProcedure;
cmd.Parameters.Add(new SqlParameter("@FirstName", locationModel.FirstName));
// ... more parameters
// Output parameter for status messages
cmd.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
```

## Controller Functions

| Controller | Responsibility |
|---|---|
| `HomeController` | Application entry point, navigation |
| `AddPatientController` | Insert new patient via `Profile.spAddPatientProfile` |
| `GetPatientController` | Retrieve patient by ID number via `Profile.spGetPatient` |
| `RemovePatientController` | Delete patient via `Profile.spDeletePatient` |
| `DropDownController` | Populate dropdown lists from lookup tables (Gender, Marital Status, Countries, Provinces, Cities) |

## Key Patterns & Conventions

### Model Validation
- **`MainModel`** contains all form fields with `[Required]`, `[MaxLength]`, `[RegularExpression]` attributes
- Phone numbers: Pattern `^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$`
- Email: Must match standard email regex
- ID Number: Exactly 13 characters (South African ID format)
- Date format: `{0:dd-MM-yyyy}` via `[DisplayFormat]`

### Database Access Pattern
- **No LINQ-to-EF**: All operations use raw `SqlConnection` + `SqlCommand`
- **No DbContext queries**: `Contxt.cs` only provides connection string configuration
- **Output parameters**: Used for both data retrieval and status messages
- **Connection string**: `HealthcareEntity` from `Web.config`

### Entity Model Usage
The only use of Entity Framework is in `DropDownController`:
```csharp
using (var db = HomeController.GetContxt())
{
    var result = db.Database.SqlQuery<MainModel>("Profile.spGetGender").ToList();
}
```
This executes raw SQL queries returning `MainModel` objects.

### JSON Response Pattern
All AJAX endpoints return:
```csharp
new JsonResult { Data = model, JsonRequestBehavior = JsonRequestBehavior.AllowGet }
```
This allows GET requests to return JSON (non-standard but deliberate pattern here).

## Critical Developer Notes

### Stored Procedure Schema Mapping
- **Profile schema**: `spAddPatientProfile`, `spGetPatient`, `spDeletePatient`, `spGetGender`, `spGetMaritalStatus`
- **Location schema**: `spGetCountries`, `spGetProvinces`, `spGetCities`

When adding new database operations, match the schema prefix to the logical domain.

### Parameter Passing
- Input/Output parameters use explicit `Direction = ParameterDirection.Output`
- Messages/errors return via output parameters, checked post-execution with `Convert.ToString(cmd.Parameters["@Message"].Value)`
- Always handle `SqlParameter` conversions (to `DateTime`, `Int32`, etc.)

### Typo Alert
- `EmergancyDateOfBirth` is misspelled throughout codebase (should be "Emergency") - maintain consistency with existing codebase

### Connection Management
- All database access uses `using` statements with `SqlConnection`
- Connection string comes from `ConfigurationManager.ConnectionStrings["HealthcareEntity"]`
- No connection pooling or async patterns currently in use

## Build & Debug
- **Build**: Standard MSBuild via Visual Studio or `dotnet build` (target .NET 4.7.2)
- **Debug**: Use `FilterConfig.cs` (custom action filters) to hook request/response pipeline
- **Routing**: Default route `{controller}/{action}/{id}` in `RouteConfig.cs`

## View Layer
- Views located in `Views/{ControllerName}/` folders
- Uses Razor syntax with Bootstrap 3.4.1 for styling
- jQuery 3.4.1 + jQuery Validation 1.17.0 for client-side interactions
- Form submission typically done via AJAX to controller endpoints

## Common Tasks

**Adding a new patient field**:
1. Add property to `MainModel` with validation attributes
2. Create/update stored procedure parameter in controller
3. Update SQL stored procedure to include new field
4. Update view form to include new input

**Fixing data retrieval**:
1. Check stored procedure name in schema (Profile or Location)
2. Verify output parameters in controller match SP definition
3. Verify `Convert.ToXxx()` type casting matches actual SQL types
4. Check `MainModel` property exists for the data

**Adding dropdown list**:
1. Add method to `DropDownController` calling appropriate stored procedure
2. Create SP in Location or Profile schema
3. Call from view via AJAX to populate select element

## .NET 6+ Migration (Linux Compatibility)

The project has been migrated from .NET Framework 4.7.2 to .NET 6.0 for Linux/cross-platform support.

### Configuration Changes:
- `Web.config` → `appsettings.json`
- `packages.config` → `PackageReference` in `.csproj`
- `Global.asax.cs` → `Program.cs`

### Key ASP.NET Core Differences:
- Controllers use dependency injection: inject `IConfiguration` in constructor
- Use `_configuration.GetConnectionString("HealthcareEntity")` instead of `ConfigurationManager`
- `HomeController.GetContxt()` now accepts `IConfiguration` parameter
- Static files go in `wwwroot/` folder
- Views use ASP.NET Core Razor (mostly compatible with ASP.NET MVC)

### Build & Run (Linux):
```bash
dotnet build
dotnet run
```

For detailed migration steps, see `MIGRATION_GUIDE.md`
