namespace CarRental.Infrastructure.Auth;

/// <summary>Bound from the "Jwt" section of appsettings.json.</summary>
public class JwtSettings
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "CarRental.API";
    public string Audience { get; set; } = "CarRental.Clients";

    /// <summary>
    /// Signing key. Must be at least 32 bytes for HMAC-SHA256.
    /// In production supply this via environment variable or user-secrets, never in source control.
    /// </summary>
    public string Key { get; set; } = string.Empty;

    public int ExpiryMinutes { get; set; } = 120;
}

/// <summary>
/// Single admin account for the dashboard, bound from the "AdminUser" section.
/// <para>
/// This is deliberately simple for the course project. A production system would store
/// users in a table with hashed passwords (e.g. ASP.NET Core Identity) instead of config.
/// </para>
/// </summary>
public class AdminUserSettings
{
    public const string SectionName = "AdminUser";

    public string Username { get; set; } = "admin";
    public string Password { get; set; } = string.Empty;
    public string Role { get; set; } = "Admin";
}
