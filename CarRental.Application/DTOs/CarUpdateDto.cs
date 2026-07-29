using System.ComponentModel.DataAnnotations;
using CarRental.Domain.Models;

namespace CarRental.Application.DTOs;

/// <summary>
/// Payload for updating a car.
/// <para>
/// <b>Status is nullable on purpose.</b> The previous version rebuilt the entity from the
/// create-DTO, so <c>Status</c> silently fell back to its default ("Available") and a rented
/// car was released by a simple price edit. Leaving <c>Status</c> null now means "keep the
/// current status"; only an explicit value changes it.
/// </para>
/// </summary>
public class CarUpdateDto
{
    [Required(ErrorMessage = "Model is required."), MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    [Required(ErrorMessage = "Brand is required."), MaxLength(50)]
    public string Brand { get; set; } = string.Empty;

    [Range(0.01, 1_000_000, ErrorMessage = "PricePerDay must be greater than 0.")]
    public decimal PricePerDay { get; set; }

    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    /// <summary>Optional. When null the existing status is preserved.</summary>
    [MaxLength(20)]
    public string? Status { get; set; }

    public bool HasValidStatus() => Status is null || CarStatus.IsValid(Status);
}
