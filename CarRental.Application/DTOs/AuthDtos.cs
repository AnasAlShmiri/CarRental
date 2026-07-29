using System.ComponentModel.DataAnnotations;

namespace CarRental.Application.DTOs;

/// <summary>Admin login request for the dashboard / mobile app.</summary>
public class LoginDto
{
    [Required(ErrorMessage = "Username is required.")]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "Password is required.")]
    public string Password { get; set; } = string.Empty;
}

/// <summary>Issued JWT plus its expiry, in UTC.</summary>
public record AuthResponseDto(string Token, DateTime ExpiresAtUtc, string Username, string Role);
