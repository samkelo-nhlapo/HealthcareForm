using System.Text;
using HealthcareForm.Security;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

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
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();

var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "HealthcareForm.Api";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "HealthcareForm.Angular";
var jwtKey = builder.Configuration["Jwt:Key"] ?? "DevelopmentOnly_ChangeThisJwtKey_AtLeast_32_Chars";

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
