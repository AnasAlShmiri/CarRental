using System.ComponentModel.DataAnnotations;

namespace CarRental.Domain.Models;

public class Car
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    [Required, MaxLength(50)]
    public string Brand { get; set; } = string.Empty;

    [Range(0.01, 1_000_000)]
    public decimal PricePerDay { get; set; }

    /// <summary>
    /// Public URL or relative path of the car photo (e.g. "/uploads/car-1.jpg").
    /// Required by the project spec ("a table containing images").
    /// </summary>
    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    /// <summary>One of <see cref="CarStatus"/>.</summary>
    [MaxLength(20)]
    public string Status { get; set; } = CarStatus.Available;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Rental> Rentals { get; set; } = [];
}
