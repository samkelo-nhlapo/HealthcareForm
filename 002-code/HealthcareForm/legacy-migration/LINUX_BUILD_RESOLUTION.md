# Linux Build Resolution - Quick Start

## Problem
The project targets .NET Framework 4.7.2 which doesn't run on Linux. The error indicates missing .NET Framework Developer Pack.

## Solution
Migrate to .NET 6.0 (cross-platform, runs on Linux, Windows, macOS).

## Files Provided

| File | Purpose |
|------|---------|
| `HealthcareForm.csproj.net6` | New SDK-style project file for .NET 6 |
| `appsettings.json` | Configuration (replaces Web.config) |
| `Program.cs` | ASP.NET Core entry point (replaces Global.asax) |
| `MIGRATION_GUIDE.md` | Detailed step-by-step migration instructions |
| `Controllers/*.cs.net6` | Updated controller templates with DI |
| `Repo/Contxt.cs.net6` | Updated DbContext for .NET 6 |

## Quick Migration Steps

### 1. Backup Current Project
```bash
cp -r /path/to/HealthcareForm /path/to/HealthcareForm.backup
```

### 2. Replace Key Files
```bash
# Remove old framework-specific files
rm HealthcareForm.csproj
rm Web.config Web.Debug.config Web.Release.config
rm Global.asax Global.asax.cs
rm -rf App_Start/

# Rename new .NET 6 files to active use
mv HealthcareForm.csproj.net6 HealthcareForm.csproj
mv Controllers/HomeController.cs Controllers/HomeController.cs.old
mv Controllers/HomeController.cs.net6 Controllers/HomeController.cs
# Repeat for other controllers: AddPatientController, DropDownController
# (GetPatientController and RemovePatientController follow same pattern)

mv Repo/Contxt.cs Repo/Contxt.cs.old
mv Repo/Contxt.cs.net6 Repo/Contxt.cs
```

### 3. Update Controllers
Each controller needs one change - inject `IConfiguration`:

**HomeController example:**
```csharp
private readonly IConfiguration _configuration;

public HomeController(IConfiguration configuration)
{
    _configuration = configuration;
}

// Update GetContxt() calls:
public static Contxt GetContxt(IConfiguration configuration)
{
    return new Contxt(configuration);
}
```

Replace:
```csharp
string connection = ConfigurationManager.ConnectionStrings["HealthcareEntity"].ConnectionString;
```

With:
```csharp
string connection = _configuration.GetConnectionString("HealthcareEntity");
```

### 4. Move Static Files
```bash
mkdir -p wwwroot/{css,js,images,fonts}
# Move files from Content/ Scripts/ fonts/ to wwwroot/
```

### 5. Build & Test
```bash
cd /path/to/HealthcareForm
dotnet build
dotnet run
# Visit http://localhost:5000
```

## Connection String

The connection string in `appsettings.json` includes `TrustServerCertificate=true` for Linux SQL Server compatibility:

```json
"HealthcareEntity": "Server=localhost,1433; Database=PatientEnrollment; User Id=sa; Password=111GkiPQ25af; TrustServerCertificate=true"
```

## Troubleshooting

**Q: "The type 'System.Web.Mvc.Controller' could not be loaded"**
A: Remove old `using System.Web.Mvc;` - ASP.NET Core uses `using Microsoft.AspNetCore.Mvc;`

**Q: "GetContxt() does not accept a parameter"**
A: Update `HomeController.GetContxt()` to accept `IConfiguration` parameter

**Q: SQL connection fails on Linux**
A: Ensure:
- SQL Server is accessible: `telnet localhost 1433`
- Connection string has `TrustServerCertificate=true`
- Password in connection string is correct

**Q: Files not found when running**
A: Linux is case-sensitive. Ensure file/folder names match exactly:
- `Controllers/`, not `controllers/`
- `Views/Home/Index.cshtml`, not `views/home/index.cshtml`

## What Didn't Change

These patterns work identically in .NET 6:
- SQL stored procedure calls (SqlConnection, SqlCommand, SqlParameter)
- Output parameter handling for error messages
- Razor view syntax (mostly)
- jQuery + AJAX calls
- Model validation attributes

## Next Steps

1. See `MIGRATION_GUIDE.md` for comprehensive documentation
2. See `.github/copilot-instructions.md` for AI agent guidance
3. Test each controller endpoint after migration
4. Update any remaining System.Web references
