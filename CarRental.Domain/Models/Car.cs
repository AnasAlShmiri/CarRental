using System.ComponentModel.DataAnnotations;

namespace CarRental.Domain.Models;

public class Car
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    [Required, MaxLength(50)]
    public string Brand { get; set; } = string.Empty;

    [Range(0, double.MaxValue)]
    public decimal PricePerDay { get; set; }

    [MaxLength(20)]
    public string Status { get; set; } = "Available"; // Available | Rented

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Rental> Rentals { get; set; } = [];
}
