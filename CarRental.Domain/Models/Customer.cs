using System.ComponentModel.DataAnnotations;

namespace CarRental.Domain.Models;

public class Customer
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(150)]
    public string Email { get; set; } = string.Empty;

    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;

    /// <summary>
    /// Stored password hash for customer self-service authentication.
    /// Never expose this property through a response DTO.
    /// </summary>
    public string? PasswordHash { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Rental> Rentals { get; set; } = [];
}
