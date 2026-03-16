# Migration Package Index

## 📋 Documentation Files (Read in This Order)

### 1. **QUICK_REFERENCE.md** ⭐ START HERE
   - **Read Time:** 5 minutes
   - **Contains:** The 5 key changes, template patterns, common errors
   - **Best for:** Getting the big picture quickly

### 2. **LINUX_BUILD_RESOLUTION.md** 
   - **Read Time:** 10 minutes
   - **Contains:** Problem/solution overview, file listing, quick migration steps
   - **Best for:** Understanding what's changing and why

### 3. **MIGRATION_GUIDE.md**
   - **Read Time:** 20-30 minutes
   - **Contains:** Detailed explanations of all changes, architecture differences, Linux considerations
   - **Best for:** Deep understanding before implementing changes

### 4. **MIGRATION_CHECKLIST.md**
   - **Read Time:** Ongoing (use while migrating)
   - **Contains:** 100+ item checklist, organized by component, with verification steps
   - **Best for:** Tracking progress and ensuring nothing is missed

### 5. **README_MIGRATION.md**
   - **Read Time:** 15-20 minutes
   - **Contains:** Complete package overview, file actions, testing strategy, troubleshooting tree
   - **Best for:** Comprehensive reference and post-migration verification

## 📁 Code Template Files

### Core Framework Files (MUST USE)
- **HealthcareForm.csproj.net6** → Replace `HealthcareForm.csproj`
  - New SDK-style project file
  - Targets .NET 6.0
  - All required NuGet packages

- **Program.cs** → Create in project root
  - Application entry point
  - Middleware pipeline
  - Dependency injection setup

- **appsettings.json** → Create in project root
  - Configuration file
  - Connection strings
  - Application settings

### Controller Files (5 TEMPLATES, ONE FOR EACH)
- **Controllers/HomeController.cs.net6** → Replace original
- **Controllers/AddPatientController.cs.net6** → Replace original
- **Controllers/GetPatientController.cs.net6** → Replace original
- **Controllers/RemovePatientController.cs.net6** → Replace original
- **Controllers/DropDownController.cs.net6** → Replace original

All follow the same pattern:
- Constructor with `IConfiguration` injection
- `_configuration.GetConnectionString()` instead of ConfigurationManager
- Updated JSON response format

### Data Layer File
- **Repo/Contxt.cs.net6** → Replace original
  - Updated to accept `IConfiguration`
  - Connection string configuration in `OnConfiguring()`

### Updated Documentation
- **.github/copilot-instructions.md** (UPDATED)
  - Added .NET 6+ migration section
  - ASP.NET Core patterns documented
  - Build/run commands for Linux

## 🚀 Quick Start Path (30 minutes)

1. **Read:** `QUICK_REFERENCE.md` (5 min)
2. **Backup:** `cp -r HealthcareForm HealthcareForm.backup`
3. **Apply Files:** Copy all `.net6` templates to replace originals
4. **Build:** `dotnet build` (should have minimal errors)
5. **Fix:** Resolve any compilation issues (usually missing usings)
6. **Test:** `dotnet run` then test endpoints
7. **Verify:** Use `MIGRATION_CHECKLIST.md` to ensure completeness

## 📊 Migration Complexity by Component

| Component | Complexity | Time | Risk |
|-----------|-----------|------|------|
| Project File (csproj) | Low | 5 min | Low |
| Configuration (appsettings.json) | Low | 5 min | Low |
| Program.cs | Low | 5 min | Low |
| HomeController | Low | 5 min | Low |
| AddPatientController | Low | 5 min | Low |
| GetPatientController | Low | 10 min | Low |
| RemovePatientController | Low | 5 min | Low |
| DropDownController | Low | 5 min | Low |
| Contxt.cs | Low | 5 min | Low |
| Static Files Reorganization | Low | 5 min | Low |
| Views (minimal changes) | Very Low | 5 min | Very Low |
| **TOTAL** | **Low** | **60 min** | **Low** |

## ✅ What Will Work Identically

These patterns and components require NO code changes:

- ✅ SQL Connection calls (SqlConnection, SqlCommand, SqlParameter)
- ✅ Stored procedure execution and parameter handling
- ✅ Error message handling via output parameters
- ✅ Razor view syntax (mostly compatible)
- ✅ jQuery and AJAX calls
- ✅ Model validation attributes
- ✅ HTML form binding
- ✅ Database operations (stored procedure logic unchanged)

## ⚠️ What MUST Change

These require updates for .NET 6:

- ❌ `using System.Web.Mvc;` → `using Microsoft.AspNetCore.Mvc;`
- ❌ `using System.Configuration;` → `using Microsoft.Extensions.Configuration;`
- ❌ `ConfigurationManager.ConnectionStrings["X"]` → `_configuration.GetConnectionString("X")`
- ❌ Constructor without DI → Constructor with `IConfiguration` parameter
- ❌ `JsonRequestBehavior.AllowGet` → `new JsonResult(new { data = model })`
- ❌ `Web.config` → `appsettings.json`
- ❌ `Global.asax.cs` → `Program.cs`
- ❌ File organization: `Content/`, `Scripts/` → `wwwroot/css/`, `wwwroot/js/`

## 🔍 File Decision Table

| Original File | Keep? | Action | Reason |
|---------------|-------|--------|--------|
| `HealthcareForm.csproj` | No | Replace | .NET 6 uses SDK style |
| `Web.config` | No | Delete | Replaced by appsettings.json |
| `Web.Debug.config` | No | Delete | Not used in .NET Core |
| `Web.Release.config` | No | Delete | Not used in .NET Core |
| `Global.asax` | No | Delete | Replaced by Program.cs |
| `Global.asax.cs` | No | Delete | Replaced by Program.cs |
| `packages.config` | No | Delete | Replaced by .csproj PackageReference |
| `App_Start/` | No | Delete | Configuration in Program.cs |
| `packages/` | No | Delete | Will be restored by dotnet restore |
| `Controllers/` | Yes | Update | Update with .net6 versions |
| `Models/` | Yes | Keep | No changes needed |
| `Views/` | Yes | Keep | Mostly compatible, minimal changes |
| `Repo/` | Yes | Update | Update Contxt.cs with .net6 version |
| `Properties/` | Yes | Keep | AssemblyInfo.cs works as-is |
| `Content/` | Move | Reorganize | → `wwwroot/css/` |
| `Scripts/` | Move | Reorganize | → `wwwroot/js/` |
| `fonts/` | Move | Reorganize | → `wwwroot/fonts/` |
| `Images/` | Move | Reorganize | → `wwwroot/images/` |

## 🎯 Testing Workflow

After migration:

```
Build ✓
  ↓
Unit Run ✓
  ↓
Homepage Load ✓
  ↓
Add Patient ✓
  ↓
Get Patient ✓
  ↓
Remove Patient ✓
  ↓
All Dropdowns ✓
  ↓
Database Ops ✓
  ↓
✅ MIGRATION COMPLETE
```

## 📞 Getting Help

### Quick Questions
→ See **QUICK_REFERENCE.md**

### Understanding Architecture
→ Read **MIGRATION_GUIDE.md** sections:
- Project File Changes
- Configuration Changes
- Controller Changes Pattern

### Specific Implementation Steps
→ Follow **MIGRATION_CHECKLIST.md** item by item

### Troubleshooting Errors
→ Check **README_MIGRATION.md** section:
- "Troubleshooting Decision Tree"
- "Known Issues & Solutions"

### Verification After Completion
→ Use **MIGRATION_CHECKLIST.md** final sections:
- Build & Test
- Post-Migration Cleanup
- Sign-Off checklist

## 📚 Related Resources

- **Microsoft ASP.NET Core Docs**: https://docs.microsoft.com/aspnet/core
- **Migration Guide from ASP.NET to Core**: https://docs.microsoft.com/dotnet/architecture/porting-existing-aspnet-apps
- **Configuration in ASP.NET Core**: https://docs.microsoft.com/aspnet/core/fundamentals/configuration
- **Dependency Injection**: https://docs.microsoft.com/aspnet/core/fundamentals/dependency-injection

## 🏆 Success Criteria

Your migration is complete when:

1. ✅ `dotnet build` succeeds with no errors
2. ✅ `dotnet run` starts application
3. ✅ http://localhost:5000 loads homepage
4. ✅ All CRUD operations work
5. ✅ All database calls succeed
6. ✅ No warnings in build output
7. ✅ Application runs on Linux (or Windows, macOS)
8. ✅ All checklist items verified

## 📝 Modification Log

| Date | Document | Changes |
|------|----------|---------|
| 2026-02-12 | All | Initial creation |
| | ├─ QUICK_REFERENCE.md | 5-minute quick guide |
| | ├─ LINUX_BUILD_RESOLUTION.md | Problem/solution overview |
| | ├─ MIGRATION_GUIDE.md | Comprehensive guide |
| | ├─ MIGRATION_CHECKLIST.md | 100+ item tracker |
| | ├─ README_MIGRATION.md | Complete package reference |
| | ├─ CODE TEMPLATES | 8 files with .net6 patterns |
| | └─ This file | Index and navigation |

---

**🎯 Ready to start?**
→ Read `QUICK_REFERENCE.md` (5 minutes)
→ Then `LINUX_BUILD_RESOLUTION.md` (10 minutes)
→ Then follow `MIGRATION_CHECKLIST.md` (60 minutes)

**Already familiar?**
→ Jump to `MIGRATION_CHECKLIST.md` and start applying changes

**Need deep understanding?**
→ Read `MIGRATION_GUIDE.md` for all the details

**Questions after migration?**
→ Check `README_MIGRATION.md` troubleshooting section

Good luck! 🚀
