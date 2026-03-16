# ASP.NET Framework 4.7.2 to .NET 6 Migration Guide

## Overview
This guide helps migrate the HealthcareForm application from ASP.NET MVC 5 (.NET Framework 4.7.2) to ASP.NET Core 6.0 for cross-platform support including Linux.

## Key Changes Required

### 1. Project File Changes

**Old (.NET Framework):**
- Uses `packages.config` for NuGet dependencies
- Uses traditional `.csproj` format with extensive configurations
- References `System.Web` assemblies

**New (.NET 6):**
- Uses `PackageReference` in `.csproj`
- Uses SDK-style project format
- No `System.Web` references

**Action:** Replace `HealthcareForm.csproj` with the provided `.csproj.net6` content.

### 2. Configuration Changes

**Old (Web.config):**
```xml
<connectionStrings>
  <add name="HealthcareEntity" connectionString="Server=localhost,1433; Database=PatientEnrollment; User Id=sa; Password=111GkiPQ25af;" providerName="System.Data.SqlClient"/>
</connectionStrings>
<appSettings>
  <add key="webpages:Version" value="3.0.0.0"/>
</appSettings>
```

**New (appsettings.json):**
```json
{
  "ConnectionStrings": {
    "HealthcareEntity": "Server=localhost,1433; Database=PatientEnrollment; User Id=sa; Password=111GkiPQ25af; TrustServerCertificate=true"
  },
  "AppSettings": {
    "ClientValidationEnabled": true
  }
}
```

**Action:** 
1. Create `appsettings.json` with configuration from `Web.config`
2. Note: Added `TrustServerCertificate=true` for Linux SQL Server connections
3. Move connection strings under `ConnectionStrings` root
4. Move app settings under `AppSettings` root

### 3. Application Entry Point Changes

**Old (Global.asax.cs):**
- Registers routes in `Application_Start()`
- Registers filters
- Registers bundles

**New (Program.cs):**
- Uses top-level statements
- Middleware pipeline defined in Program.cs
- No Global.asax needed

**Action:** The provided `Program.cs` replaces `Global.asax.cs` functionality.

### 4. Controller Changes Required

All controllers need updates to use dependency injection instead of `ConfigurationManager`:

**Old Pattern:**
```csharp
string connection = ConfigurationManager.ConnectionStrings["HealthcareEntity"].ConnectionString;
```

**New Pattern:**
```csharp
private readonly IConfiguration _configuration;

public AddPatientController(IConfiguration configuration)
{
    _configuration = configuration;
}

// In method:
string connection = _configuration.GetConnectionString("HealthcareEntity");
```

**Action Items for Each Controller:**

1. **HomeController**: Update `GetContxt()` to accept `IConfiguration`
   ```csharp
   public static Contxt GetContxt(IConfiguration configuration)
   {
       return new Contxt(configuration);
   }
   ```

2. **AddPatientController**: 
   - Add constructor to inject `IConfiguration`
   - Replace `ConfigurationManager.ConnectionStrings["HealthcareEntity"]` with `_configuration.GetConnectionString("HealthcareEntity")`
   - No other changes needed to SQL logic

3. **GetPatientController**: Same pattern as AddPatientController

4. **RemovePatientController**: Same pattern as AddPatientController

5. **DropDownController**: 
   - Inject `IConfiguration` into constructor
   - Update `HomeController.GetContxt()` calls to pass configuration

### 5. Entity Model Context Changes

**Old (Repo/Contxt.cs):**
```csharp
public class Contxt : DbContext
{
    public Contxt() : base("name = HealthcareEntity") { }
}
```

**New (Repo/Contxt.cs):**
```csharp
using Microsoft.Extensions.Configuration;

public class Contxt : DbContext
{
    private readonly IConfiguration _configuration;
    
    public Contxt(IConfiguration configuration) : base()
    {
        _configuration = configuration;
    }
    
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        string connectionString = _configuration.GetConnectionString("HealthcareEntity");
        optionsBuilder.UseSqlServer(connectionString);
        base.OnConfiguring(optionsBuilder);
    }
}
```

### 6. View Changes

**Minimal changes required for Razor views:**

1. Remove `@using System.Web.Mvc` if present
2. Update HTML helpers if needed (ASP.NET Core uses different tag helpers)
3. AJAX calls remain mostly the same
4. jQuery validation should work as-is

**Layout changes:**
- Create `Views/Shared/_Layout.cshtml` if it doesn't exist
- Update `_ViewStart.cshtml` to reference correct layout
- CDN links for jQuery/Bootstrap remain compatible

### 7. Static Files & Bundling

**Old Pattern:** Uses `Microsoft.AspNet.Web.Optimization` with `BundleConfig.cs`

**New Pattern:** 
- Static files served from `wwwroot/` folder
- Bundling optional (use `BundlerMinifier` or similar)
- For now, manually reference scripts in views

**Action:** Move static files to `wwwroot/` folder:
```
wwwroot/
  css/
    bootstrap.min.css
    site.css
  js/
    jquery.min.js
    jquery.validate.min.js
  images/
  fonts/
```

### 8. Data Type Compatibility

**Important:** `System.Data.SqlClient` parameter handling remains the same:

```csharp
// No changes needed
cmd.Parameters.Add(new SqlParameter("@FirstName", locationModel.FirstName));
cmd.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
```

## Step-by-Step Migration Checklist

- [ ] Delete `packages.config`
- [ ] Delete `Web.config`, `Web.Debug.config`, `Web.Release.config`
- [ ] Delete `Global.asax` and `Global.asax.cs`
- [ ] Delete `App_Start/` folder (BundleConfig, RouteConfig, FilterConfig)
- [ ] Replace `HealthcareForm.csproj` with new SDK-style version
- [ ] Create `appsettings.json` with connection strings
- [ ] Create `Program.cs` with ASP.NET Core middleware
- [ ] Update `Repo/Contxt.cs` to use `IConfiguration`
- [ ] Update all controllers to inject `IConfiguration`
- [ ] Update `HomeController.GetContxt()` method signature
- [ ] Move static files to `wwwroot/` folder
- [ ] Update `_ViewStart.cshtml` layout reference
- [ ] Test each controller's database operations
- [ ] Update copilot-instructions.md with ASP.NET Core patterns

## Build & Run Commands

### Build
```bash
dotnet build
```

### Run (Development)
```bash
dotnet run
```

### Run (Production)
```bash
dotnet publish -c Release -o ./publish
dotnet publish/HealthcareForm.dll
```

### Set Connection String via Environment Variable (Linux)
```bash
export ConnectionStrings__HealthcareEntity="Server=db_server,1433;Database=PatientEnrollment;User Id=sa;Password=your_password;TrustServerCertificate=true"
dotnet run
```

## Linux-Specific Considerations

1. **Case Sensitivity:** File paths are case-sensitive on Linux
   - Controllers must be named `AddPatientController.cs` (not `addpatientcontroller.cs`)
   - View folders must match controller name case

2. **Database Connection:**
   - Use `TrustServerCertificate=true` for self-signed SSL certs
   - SQL Server on Linux listens on port 1433
   - Ensure firewall allows connection

3. **Kestrel Server:**
   - ASP.NET Core uses Kestrel by default
   - Configure ports in `appsettings.json` if needed:
   ```json
   "Kestrel": {
     "Endpoints": {
       "Http": {
         "Url": "http://localhost:5000"
       }
     }
   }
   ```

## Testing After Migration

1. **View Home Page:** `dotnet run` then visit `http://localhost:5000`
2. **Test Add Patient:** POST to `/AddPatient/AddPatient` with form data
3. **Test Get Patient:** GET to `/GetPatient/GetPatient?IDnumber=1234567890123`
4. **Test Dropdowns:** GET to `/DropDown/GetGender`, etc.
5. **Test Remove Patient:** POST to `/RemovePatient/RemovePatient`

## Common Issues & Solutions

### Issue: "The reference assemblies for .NETFramework,Version=v4.7.2 were not found"
**Solution:** Delete the old `.csproj` file and use the new SDK-style `.csproj`

### Issue: "Could not load type 'System.Web.Mvc.Controller'"
**Solution:** Update all `using` statements to remove `System.Web.Mvc` (now just `using Microsoft.AspNetCore.Mvc`)

### Issue: SQL Connection fails on Linux
**Solution:** 
- Add `TrustServerCertificate=true` to connection string
- Verify SQL Server is accessible: `telnet hostname 1433`

### Issue: Static files not loading
**Solution:** Ensure files are in `wwwroot/` folder and `app.UseStaticFiles()` is in `Program.cs`

## References

- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core)
- [Migrate from ASP.NET to ASP.NET Core](https://docs.microsoft.com/dotnet/architecture/porting-existing-aspnet-apps)
- [Configuration in ASP.NET Core](https://docs.microsoft.com/aspnet/core/fundamentals/configuration)
- [Dependency Injection in ASP.NET Core](https://docs.microsoft.com/aspnet/core/fundamentals/dependency-injection)
