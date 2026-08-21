using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Infrastructure.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;

namespace CarRental.API.Controllers;

/// <summary>
/// Issues JWTs for the admin dashboard and mobile app.
/// <para>
/// Credentials come from the "AdminUser" configuration section. This is intentionally
/// simple for the course project — a production system would keep users in a table with
/// hashed passwords (ASP.NET Core Identity).
/// </para>
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class AuthController(
    ITokenService tokenService,
    IOptions<AdminUserSettings> adminOptions,
    ILogger<AuthController> logger) : ControllerBase
{
    private readonly AdminUserSettings _admin = adminOptions.Value;

    [HttpPost("login")]
    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public ActionResult<AuthResponseDto> Login(LoginDto dto)
    {
        if (string.IsNullOrWhiteSpace(_admin.Password))
            return Problem(
                detail: "No admin account is configured. Set AdminUser:Password in configuration.",
                statusCode: StatusCodes.Status500InternalServerError,
                title: "Server not configured");

        // Fixed-time-ish comparison; ordinal so casing matters on the password.
        var userOk = string.Equals(dto.Username, _admin.Username, StringComparison.OrdinalIgnoreCase);
        var passOk = string.Equals(dto.Password, _admin.Password, StringComparison.Ordinal);

        if (!userOk || !passOk)
        {
            logger.LogWarning("Failed login attempt for username {Username}", dto.Username);
            return Problem(
                detail: "Invalid username or password.",
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Authentication failed");
        }

        return Ok(tokenService.CreateToken(_admin.Username, _admin.Role));
    }

    /// <summary>Echoes the caller's identity — handy for verifying a token works.</summary>
    [HttpGet("me")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public IActionResult Me() => Ok(new
    {
        username = User.Identity?.Name,
        roles = User.Claims
                    .Where(c => c.Type.EndsWith("role", StringComparison.OrdinalIgnoreCase))
                    .Select(c => c.Value)
                    .Distinct()
    });
}
