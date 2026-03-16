# Migration Quick Reference Card

## 30-Second Summary
Convert from .NET Framework 4.7.2 (Windows-only) to .NET 6.0 (cross-platform) to enable Linux build support.

## The 5 Key Changes

### 1. Configuration (Web.config → appsettings.json)
```csharp
// OLD
string conn = ConfigurationManager.ConnectionStrings["HealthcareEntity"].ConnectionString;

// NEW
private readonly IConfiguration _configuration;
public MyController(IConfiguration configuration) => _configuration = configuration;
string conn = _configuration.GetConnectionString("HealthcareEntity");
```

### 2. Project File (packages.config → .csproj)
- Delete: `packages.config`, `Web.config`, `Web.Debug.config`, `Web.Release.config`
- Create: New `HealthcareForm.csproj` (SDK-style)
- Create: `appsettings.json` with connection string

### 3. Application Entry Point (Global.asax → Program.cs)
- Delete: `Global.asax` and `Global.asax.cs`
- Create: `Program.cs` with ASP.NET Core middleware setup
- Delete: `App_Start/` folder (no longer needed)

### 4. All Controllers (Dependency Injection Pattern)
**Every controller needs this constructor:**
```csharp
private readonly IConfiguration _configuration;

public ControllerName(IConfiguration configuration) 
{
    _configuration = configuration;
}
```

### 5. Static Files Organization
```
Before:           After:
Content/     →    wwwroot/css/
Scripts/     →    wwwroot/js/
Images/      →    wwwroot/images/
fonts/       →    wwwroot/fonts/
```

## Files to Apply (In Order)

1. **Delete:** `packages.config`, `Web.*.config`, `Global.asax*`, `App_Start/`
2. **Copy:** `HealthcareForm.csproj.net6` → `HealthcareForm.csproj`
3. **Copy:** `Program.cs` (provided)
4. **Copy:** `appsettings.json` (provided)
5. **Copy:** All `Controllers/*.cs.net6` → `Controllers/*.cs`
6. **Copy:** `Repo/Contxt.cs.net6` → `Repo/Contxt.cs`
7. **Organize:** Move static files to `wwwroot/`

## The Template Pattern (for all 5 controllers)

```csharp
using Microsoft.AspNetCore.Mvc;  // ← IMPORTANT: NOT System.Web.Mvc
using System.Data;
using System.Data.SqlClient;

public class XyzController : Controller 
{
    private readonly IConfiguration _configuration;  // ← ADD
    
    public XyzController(IConfiguration configuration)  // ← ADD
    {
        _configuration = configuration;
    }
    
    public JsonResult SomeMethod() 
    {
        // OLD: string conn = ConfigurationManager.ConnectionStrings["HealthcareEntity"].ConnectionString;
        // NEW:
        string conn = _configuration.GetConnectionString("HealthcareEntity");  // ← CHANGE
        
        using (SqlConnection connection = new SqlConnection(conn))
        {
            // ... rest is the SAME (no SQL changes needed!)
        }
        
        // OLD: return new JsonResult { Data = model, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
        // NEW:
        return new JsonResult(new { data = model });  // ← CHANGE
    }
}
```

## Special Cases

### HomeController.GetContxt()
```csharp
// OLD
public static Contxt GetContxt()
{
    return new Contxt();
}

// NEW
public static Contxt GetContxt(IConfiguration configuration)  // ← ADD PARAMETER
{
    return new Contxt(configuration);  // ← PASS IT
}
```

### DropDownController (calls GetContxt)
```csharp
// OLD
using (var db = HomeController.GetContxt())  // ← No parameters

// NEW
using (var db = HomeController.GetContxt(_configuration))  // ← Pass config
```

## Build & Run

```bash
# Navigate to project
cd /path/to/HealthcareForm

# Build
dotnet build

# Run (development)
dotnet run
# Now visit http://localhost:5000

# Run (with specific port)
dotnet run --urls="http://localhost:5000"

# Publish (production)
dotnet publish -c Release -o ./publish
dotnet ./publish/HealthcareForm.dll
```

## Testing Endpoints

```bash
# Home
curl http://localhost:5000

# Get dropdowns
curl http://localhost:5000/DropDown/GetGender

# Add patient (needs form data)
curl -X POST http://localhost:5000/AddPatient/AddPatient \
  -H "Content-Type: application/json" \
  -d '{"FirstName":"John","LastName":"Doe",...}'

# Get patient
curl "http://localhost:5000/GetPatient/GetPatient?IDnumber=1234567890123"

# Delete patient
curl -X POST http://localhost:5000/RemovePatient/RemovePatient \
  -H "Content-Type: application/json" \
  -d '{"IDNumber":"1234567890123"}'
```

## Linux-Specific Notes

1. **Connection String:** Must include `TrustServerCertificate=true`
   ```json
   "HealthcareEntity": "Server=localhost,1433; Database=PatientEnrollment; User Id=sa; Password=xxx; TrustServerCertificate=true"
   ```

2. **Case Sensitivity:** Linux is case-sensitive
   - ✅ `Controllers/AddPatientController.cs`
   - ❌ `controllers/addpatientcontroller.cs`
   - ✅ `Views/Home/Index.cshtml`
   - ❌ `views/home/index.cshtml`

3. **Database Access:** Verify connectivity
   ```bash
   telnet localhost 1433
   # Should connect successfully
   ```

## Rollback (if needed)

```bash
# Restore from backup
rm -rf HealthcareForm
cp -r HealthcareForm.backup HealthcareForm
```

## Success Indicators

✅ `dotnet build` succeeds
✅ `dotnet run` starts without exceptions
✅ http://localhost:5000 loads
✅ Database operations work
✅ All controllers respond

## Common Errors

| Error | Fix |
|-------|-----|
| "Type 'System.Web.Mvc.Controller' not found" | Change `using` to `using Microsoft.AspNetCore.Mvc;` |
| "GetContxt does not accept parameters" | Add parameter: `IConfiguration configuration` |
| "IConfiguration is not defined" | Add `using Microsoft.Extensions.Configuration;` |
| SQL connection fails | Add `TrustServerCertificate=true` to connection string |
| Static files missing | Ensure files are in `wwwroot/` and check case |

## Key Files Reference

| What | File | Action |
|------|------|--------|
| Controllers | `Controllers/*.cs.net6` | Copy over original |
| Config | `appsettings.json` | Create new |
| Entry Point | `Program.cs` | Create new |
| Project | `HealthcareForm.csproj.net6` | Copy over original |
| DB Context | `Repo/Contxt.cs.net6` | Copy over original |
| Guide | `MIGRATION_GUIDE.md` | Read for details |
| Checklist | `MIGRATION_CHECKLIST.md` | Track progress |

## One More Thing

**Update using statements in EVERY FILE:**

```csharp
// REMOVE
using System.Web.Mvc;
using System.Configuration;
using System.Web.Routing;

// ADD (if not present)
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
```

---

Need more help? See `MIGRATION_GUIDE.md` for detailed explanations and `LINUX_BUILD_RESOLUTION.md` for step-by-step walkthrough.
