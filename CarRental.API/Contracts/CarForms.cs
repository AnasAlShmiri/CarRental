using System.ComponentModel.DataAnnotations;

namespace CarRental.API.Contracts;

/// <summary>
/// Form payload for creating a car — the photo travels in the SAME request.
/// <para>
/// These form models live in the API layer (not Application) because IFormFile is an
/// HTTP concern that must not leak into the inner Clean Architecture layers.
/// </para>
/// </summary>
public class CarCreateForm
{
    [Required(ErrorMessage = "Model is required."), MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    [Required(ErrorMessage = "Brand is required."), MaxLength(50)]
    public string Brand { get; set; } = string.Empty;

    [Range(0.01, 1_000_000, ErrorMessage = "PricePerDay must be greater than 0.")]
    public decimal PricePerDay { get; set; }

    /// <summary>Optional photo (jpg / jpeg / png / gif / webp, up to 5 MB).</summary>
    public IFormFile? Image { get; set; }
}

/// <summary>
/// Form payload for updating a car.
/// <list type="bullet">
/// <item>Leave <see cref="Image"/> empty to keep the current photo.</item>
/// <item>Pick a new file to replace it (the old file is deleted).</item>
/// <item>Set <see cref="RemoveImage"/> to true to delete the photo.</item>
/// <item>Leave <see cref="Status"/> out to keep the current status.</item>
/// </list>
/// </summary>
public class CarUpdateForm
{
    [Required(ErrorMessage = "Model is required."), MaxLength(100)]
    public string Model { get; set; } = string.Empty;

    [Required(ErrorMessage = "Brand is required."), MaxLength(50)]
    public string Brand { get; set; } = string.Empty;

    [Range(0.01, 1_000_000, ErrorMessage = "PricePerDay must be greater than 0.")]
    public decimal PricePerDay { get; set; }

    /// <summary>Optional. When omitted the existing status is preserved.</summary>
    [MaxLength(20)]
    public string? Status { get; set; }

    /// <summary>Optional replacement photo. Omit to keep the current one.</summary>
    public IFormFile? Image { get; set; }

    /// <summary>True deletes the current photo. Ignored when a new Image is supplied.</summary>
    public bool RemoveImage { get; set; }
}
