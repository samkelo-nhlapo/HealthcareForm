using HealthcareForm.Contracts.Auth;
using HealthcareForm.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HealthcareForm.Controllers.Api;

[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly IJwtTokenService _jwtTokenService;

    public AuthController(IAuthService authService, IJwtTokenService jwtTokenService)
    {
        _authService = authService;
        _jwtTokenService = jwtTokenService;
    }

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<ActionResult<AuthTokenResponse>> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        var result = await _authService.AuthenticateAsync(request.UsernameOrEmail, request.Password, cancellationToken);
        if (!result.Success || result.User is null)
        {
            return Unauthorized(new { Message = result.Message });
        }

        try
        {
            var token = _jwtTokenService.CreateToken(result.User);
            return Ok(token);
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                Message = ex.Message
            });
        }
    }

    [Authorize]
    [HttpGet("me")]
    public IActionResult Me()
    {
        return Ok(new
        {
            UserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value
                ?? string.Empty,
            Username = User.Identity?.Name ?? string.Empty,
            Email = User.FindFirst(ClaimTypes.Email)?.Value
                ?? User.FindFirst("email")?.Value
                ?? string.Empty,
            Roles = User.FindAll(ClaimTypes.Role)
                        .Select(role => role.Value)
                        .ToArray()
        });
    }
}
