using System.ComponentModel.DataAnnotations;

namespace CarRental.Domain.Models;

public class Rental
{
    public int Id { get; set; }

    public int CarId { get; set; }
    public Car Car { get; set; } = null!;

    public int CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }

    [Range(0, double.MaxValue)]
    public decimal TotalPrice { get; set; }

    /// <summary>One of <see cref="RentalStatus"/>.</summary>
    [MaxLength(20)]
    public string Status { get; set; } = RentalStatus.Active;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
