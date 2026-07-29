using System.ComponentModel.DataAnnotations;

namespace CarRental.Application.DTOs;

public class RentalCreateDto
{
    [Required]
    public int CarId { get; set; }

    [Required]
    public int CustomerId { get; set; }

    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }
}
