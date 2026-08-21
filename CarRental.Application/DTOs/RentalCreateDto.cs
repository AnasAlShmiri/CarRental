using System.ComponentModel.DataAnnotations;

namespace CarRental.Application.DTOs;

/// <summary>
/// Payload for creating a rental.
/// <c>TotalPrice</c> is intentionally not accepted — the server computes it from the
/// car's daily rate so a client cannot dictate the price.
/// </summary>
public class RentalCreateDto
{
    [Range(1, int.MaxValue, ErrorMessage = "CarId must be a positive number.")]
    public int CarId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "CustomerId must be a positive number.")]
    public int CustomerId { get; set; }

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }
}


/// <summary>Customer booking payload. The customer identity comes from the JWT.</summary>
public class CustomerRentalCreateDto
{
    [Range(1, int.MaxValue, ErrorMessage = "CarId must be a positive number.")]
    public int CarId { get; set; }

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }
}
