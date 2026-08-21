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


/// <summary>Customer self-registration request for the mobile application.</summary>
public class CustomerRegisterDto
{
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(150), EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(8), MaxLength(100)]
    public string Password { get; set; } = string.Empty;

    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;
}

/// <summary>Customer login request. Email is the stable customer identifier.</summary>
public class CustomerLoginDto
{
    [Required, MaxLength(150), EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}

public class CustomerProfileUpdateDto
{
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;
}

/// <summary>Customer token plus the safe profile needed by the mobile session.</summary>
public record CustomerAuthResponseDto(
    string Token,
    DateTime ExpiresAtUtc,
    string Username,
    string Role,
    int CustomerId,
    string Name,
    string Email,
    string Phone);
