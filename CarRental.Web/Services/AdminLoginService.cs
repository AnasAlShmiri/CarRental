using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using CarRental.Infrastructure.Auth;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace CarRental.Web.Services;

/// <summary>
/// Validates credentials against the shared <c>AdminUser</c> settings (identical to the
/// API host) and signs the same JWT that <c>TokenService</c> issues, so the cookie and
/// any forwarded Bearer calls honour the same issuer/audience/key.
/// </summary>
public class AdminLoginService(
    IOptions<AdminUserSettings> admin,
    IOptions<JwtSettings> jwt)
{
    public bool Validate(string username, string password) =>
        string.Equals(admin.Value.Username, username, StringComparison.Ordinal)
        && string.Equals(admin.Value.Password, password, StringComparison.Ordinal);

    public AdminUserSettings Admin => admin.Value;
    public JwtSettings Jwt => jwt.Value;

    public string SignToken(string username, string role)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Value.Key));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.Name, username),
            new Claim(ClaimTypes.Role, role)
        };

        var token = new JwtSecurityToken(
            issuer: jwt.Value.Issuer,
            audience: jwt.Value.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(jwt.Value.ExpiryMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
