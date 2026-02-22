# Migration Checklist: .NET Framework 4.7.2 → .NET 6

## Pre-Migration
- [ ] Backup entire project: `cp -r HealthcareForm HealthcareForm.backup`
- [ ] Verify all tests pass on current framework (if tests exist)
- [ ] Document any custom configurations in Web.config
- [ ] Note any environment-specific settings

## Project Files
- [ ] Delete `packages.config`
- [ ] Delete `Web.config`, `Web.Debug.config`, `Web.Release.config`
- [ ] Delete `Global.asax` and `Global.asax.cs`
- [ ] Delete `App_Start/` folder (contains BundleConfig.cs, RouteConfig.cs, FilterConfig.cs)
- [ ] Delete `packages/` folder (NuGet will restore)
- [ ] Replace `HealthcareForm.csproj` with provided SDK-style version
- [ ] Create `appsettings.json` with connection strings and settings
- [ ] Create `Program.cs` with ASP.NET Core middleware pipeline

## Controllers (5 Controllers)

### HomeController
- [ ] Add `private readonly IConfiguration _configuration;` field
- [ ] Add constructor: `public HomeController(IConfiguration configuration)`
- [ ] Update `GetContxt()` to accept IConfiguration parameter
- [ ] Change `using System.Web.Mvc;` to `using Microsoft.AspNetCore.Mvc;`

### AddPatientController
- [ ] Add `private readonly IConfiguration _configuration;` field
- [ ] Add constructor accepting IConfiguration
- [ ] Replace all `ConfigurationManager.ConnectionStrings["HealthcareEntity"].ConnectionString` with `_configuration.GetConnectionString("HealthcareEntity")`
- [ ] Change return statement: `return new JsonResult(new { data = locationModel });`
- [ ] Change `using System.Web.Mvc;` to `using Microsoft.AspNetCore.Mvc;`
- [ ] Remove `using System.Configuration;`

### GetPatientController
- [ ] Add `private readonly IConfiguration _configuration;` field
- [ ] Add constructor accepting IConfiguration
- [ ] Replace all ConfigurationManager calls with `_configuration.GetConnectionString()`
- [ ] Change return statement: `return new JsonResult(new { data = locationModel });`
- [ ] Update using statements

### RemovePatientController
- [ ] Add `private readonly IConfiguration _configuration;` field
- [ ] Add constructor accepting IConfiguration
- [ ] Replace ConfigurationManager with `_configuration`
- [ ] Change return statement: `return new JsonResult(new { data = locationModel });`
- [ ] Update using statements

### DropDownController
- [ ] Add `private readonly IConfiguration _configuration;` field
- [ ] Add constructor accepting IConfiguration
- [ ] Update all `HomeController.GetContxt()` calls to pass `_configuration`
- [ ] Change return statements: `return new JsonResult(new { data = eventGender });`
- [ ] Update using statements

## Data Access Layer

### Repo/Contxt.cs
- [ ] Add `using Microsoft.Extensions.Configuration;`
- [ ] Update constructor to accept IConfiguration
- [ ] Store IConfiguration as private field
- [ ] Add OnConfiguring method to set connection string from configuration
- [ ] Remove old constructor parameter

## Views
- [ ] Update `_ViewStart.cshtml` if layout path changed
- [ ] Create `Views/Shared/_Layout.cshtml` if missing
- [ ] Verify all view paths (case-sensitive on Linux!)
- [ ] Check all HTML helpers are compatible
- [ ] Verify AJAX calls reference correct controller/action names

## Static Files
- [ ] Create `wwwroot/` folder structure
- [ ] Move CSS files: `Content/` → `wwwroot/css/`
- [ ] Move JavaScript: `Scripts/` → `wwwroot/js/`
- [ ] Move fonts: `fonts/` → `wwwroot/fonts/`
- [ ] Move images: `Images/` → `wwwroot/images/`
- [ ] Update CDN references if using external resources
- [ ] Verify static files are served (check Program.cs has `app.UseStaticFiles()`)

## Configuration
- [ ] Verify connection string in appsettings.json
- [ ] Add `TrustServerCertificate=true` for Linux SQL Server
- [ ] Copy any custom appSettings from Web.config to appsettings.json
- [ ] Set environment variables for sensitive data if needed

## Build & Test
- [ ] Run `dotnet build` - should complete without errors
- [ ] Run `dotnet run` - should start on localhost:5000
- [ ] Test Home page loads (http://localhost:5000)
- [ ] Test Add Patient endpoint
- [ ] Test Get Patient endpoint  
- [ ] Test Remove Patient endpoint
- [ ] Test all dropdown lists (Gender, Marital Status, Countries, etc.)
- [ ] Verify SQL Server connection works
- [ ] Check JavaScript/jQuery functionality in browser

## Linux-Specific Verification (if applicable)
- [ ] File names match case exactly (Controllers/, not controllers/)
- [ ] View folder paths match case exactly
- [ ] Connection string specifies correct hostname/port
- [ ] Database user has correct permissions
- [ ] Firewall allows connection to SQL Server (port 1433)
- [ ] Run `telnet <hostname> 1433` to verify connectivity

## Post-Migration Cleanup
- [ ] Delete all `.net6` template files
- [ ] Delete `.old` backup controller files
- [ ] Update `.gitignore` if needed (remove packages/ entries)
- [ ] Update README.md with new build/run instructions
- [ ] Update `.github/copilot-instructions.md` if needed
- [ ] Review and test error handling in controllers
- [ ] Verify all business logic still works as expected

## Verification Commands

```bash
# Build
dotnet build

# Run development server
dotnet run

# Run with specific port
dotnet run --urls="http://localhost:5000"

# Build for production
dotnet publish -c Release -o ./publish

# Check project structure
ls -la
ls -la Controllers/
ls -la Views/
ls -la wwwroot/
```

## Rollback Plan
If migration fails at any point:
```bash
# Restore from backup
rm -rf HealthcareForm
cp -r HealthcareForm.backup HealthcareForm
cd HealthcareForm
# Investigate issue and try again
```

## Known Issues & Solutions

| Issue | Solution |
|-------|----------|
| Build fails: "Type 'System.Web.Mvc.Controller' not found" | Ensure using statement is `using Microsoft.AspNetCore.Mvc;` |
| "GetContxt() does not accept parameter" | Update method signature: `public static Contxt GetContxt(IConfiguration configuration)` |
| SQL connection fails | Add `TrustServerCertificate=true` to connection string |
| Views not found (404) | Check case sensitivity on Linux (Views/ not views/) |
| Static files not loading | Verify `app.UseStaticFiles()` in Program.cs and files in wwwroot/ |
| "IConfiguration not found" | Add `using Microsoft.Extensions.Configuration;` |

## Sign-Off
- [ ] All controllers compile without errors
- [ ] All database operations work correctly
- [ ] Application runs on `dotnet run`
- [ ] Can be deployed to Linux
- [ ] No breaking changes to public APIs
- [ ] Documentation updated (MIGRATION_GUIDE.md, README.md)
