using System.ComponentModel.DataAnnotations;

namespace CarRental.Application.DTOs;

/// <summary>Payload for creating a car. Status is always "Available" on creation.</summary>
public class CarCreateDto
{
    [Required(ErrorMessage = "Model is required."), MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    [Required(ErrorMessage = "Brand is required."), MaxLength(50)]
    public string Brand { get; set; } = string.Empty;

    [Range(0.01, 1_000_000, ErrorMessage = "PricePerDay must be greater than 0.")]
    public decimal PricePerDay { get; set; }

    [MaxLength(500)]
    public string? ImageUrl { get; set; }
}
