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

    [MaxLength(20)]
    public string Status { get; set; } = "Active"; // Active | Completed | Cancelled

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
