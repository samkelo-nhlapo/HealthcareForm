using System.Text;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddUserSecrets<Program>(optional: true);

static Dictionary<string, string?> LoadDotEnvValues(string path)
{
    var values = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
    if (!File.Exists(path))
    {
        return values;
    }

    foreach (var rawLine in File.ReadAllLines(path))
    {
        var line = rawLine.Trim();
        if (line.Length == 0 || line.StartsWith("#", StringComparison.Ordinal))
        {
            continue;
        }

        var separatorIndex = line.IndexOf('=');
        if (separatorIndex <= 0)
        {
            continue;
        }

        var key = line[..separatorIndex].Trim();
        var value = line[(separatorIndex + 1)..].Trim();
        if (value.Length >= 2
            && value.StartsWith("\"", StringComparison.Ordinal)
            && value.EndsWith("\"", StringComparison.Ordinal))
        {
            value = value[1..^1];
        }

        if (key.Length == 0)
        {
            continue;
        }

        values[key.Replace("__", ":", StringComparison.Ordinal)] = value;
    }

    return values;
}

static bool IsPlaceholderValue(string value)
{
    var normalized = value.Trim();
    return normalized.StartsWith("__SET_", StringComparison.Ordinal)
        || normalized.StartsWith("REPLACE_WITH_", StringComparison.OrdinalIgnoreCase)
        || normalized.Equals("YOUR_CONNECTION_STRING", StringComparison.OrdinalIgnoreCase)
        || normalized.Contains("<password>", StringComparison.OrdinalIgnoreCase);
}

static string RequireConfigurationValue(IConfiguration configuration, string key)
{
    var value = configuration[key];
    if (string.IsNullOrWhiteSpace(value) || IsPlaceholderValue(value))
    {
        throw new InvalidOperationException($"Configuration value '{key}' is not set.");
    }

    return value;
}

if (builder.Environment.IsDevelopment())
{
    var dotenvCandidates = new[]
    {
        Path.Combine(builder.Environment.ContentRootPath, ".env.dev"),
        Path.Combine(builder.Environment.ContentRootPath, "..", "..", ".env.dev")
    };

    var overlayValues = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
    foreach (var dotenvPath in dotenvCandidates)
    {
        foreach (var entry in LoadDotEnvValues(dotenvPath))
        {
            var currentValue = builder.Configuration[entry.Key];
            if (string.IsNullOrWhiteSpace(currentValue) || IsPlaceholderValue(currentValue))
            {
                overlayValues[entry.Key] = entry.Value;
            }
        }
    }

    if (overlayValues.Count > 0)
    {
        builder.Configuration.AddInMemoryCollection(overlayValues);
    }
}

// Add services to the container
builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = null;
    });

builder.Services.AddCors(options =>
{
    options.AddPolicy("AngularDevClient", policy =>
    {
        var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();
        policy.WithOrigins(allowedOrigins is { Length: > 0 } ? allowedOrigins : ["http://localhost:4200"])
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddScoped<IPatientService, PatientService>();
builder.Services.AddScoped<ILookupService, LookupService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IOperationsService, OperationsService>();
builder.Services.AddScoped<IRevenueService, RevenueService>();
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();

_ = RequireConfigurationValue(builder.Configuration, "ConnectionStrings:HealthcareEntity");
var jwtIssuer = RequireConfigurationValue(builder.Configuration, "Jwt:Issuer");
var jwtAudience = RequireConfigurationValue(builder.Configuration, "Jwt:Audience");
var jwtKey = RequireConfigurationValue(builder.Configuration, "Jwt:Key");
if (jwtKey.Length < 32)
{
    throw new InvalidOperationException("Configuration value 'Jwt:Key' must be at least 32 characters.");
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(
        AuthorizationPolicies.PatientsRead,
        policy => policy.RequireRole(AuthorizationPolicies.PatientsReadRoles));

    options.AddPolicy(
        AuthorizationPolicies.PatientsWrite,
        policy => policy.RequireRole(AuthorizationPolicies.PatientsWriteRoles));

    options.AddPolicy(
        AuthorizationPolicies.PatientsDelete,
        policy => policy.RequireRole(AuthorizationPolicies.PatientsDeleteRoles));

    options.AddPolicy(
        AuthorizationPolicies.LookupsRead,
        policy => policy.RequireRole(AuthorizationPolicies.LookupsReadRoles));

    // Reserved for upcoming API endpoints mapped to Phase 4 and Phase 5 Angular routes.
    options.AddPolicy(
        AuthorizationPolicies.OperationsAccess,
        policy => policy.RequireRole(AuthorizationPolicies.OperationsAccessRoles));

    options.AddPolicy(
        AuthorizationPolicies.RevenueAccess,
        policy => policy.RequireRole(AuthorizationPolicies.RevenueAccessRoles));

    options.AddPolicy(
        AuthorizationPolicies.AdminAccess,
        policy => policy.RequireRole(AuthorizationPolicies.AdminAccessRoles));
});

var app = builder.Build();
var configuredUrls = builder.Configuration["urls"] ?? builder.Configuration["ASPNETCORE_URLS"];
var hasHttpsEndpoint = !string.IsNullOrWhiteSpace(configuredUrls)
    && configuredUrls.Split(';', StringSplitOptions.RemoveEmptyEntries)
                     .Any(url => url.Trim().StartsWith("https://", StringComparison.OrdinalIgnoreCase));
var forceHttpsRedirection = builder.Configuration.GetValue("HttpsRedirection:Enabled", false);

// Configure the HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler(exceptionHandler =>
    {
        exceptionHandler.Run(async context =>
        {
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new
            {
                Message = "An unexpected server error occurred."
            });
        });
    });
    app.UseHsts();
}

if (forceHttpsRedirection || hasHttpsEndpoint)
{
    app.UseHttpsRedirection();
}

app.UseRouting();
app.UseCors("AngularDevClient");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
