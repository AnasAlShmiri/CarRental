using System.ComponentModel.DataAnnotations;

namespace CarRental.Application.DTOs;

public class CarCreateDto
{
    [Required, MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    [Required, MaxLength(50)]
    public string Brand { get; set; } = string.Empty;

    [Range(0, double.MaxValue)]
    public decimal PricePerDay { get; set; }
}
