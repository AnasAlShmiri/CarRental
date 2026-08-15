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

    /// <summary>Computed billing days (whole calendar days, minimum one) — shared by API DTOs and MVC views.</summary>
    public int DurationInDays => Math.Max(1, (EndDate.Date - StartDate.Date).Days);

    /// <summary>One of <see cref="RentalStatus"/>.</summary>
    [MaxLength(20)]
    public string Status { get; set; } = RentalStatus.Active;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
