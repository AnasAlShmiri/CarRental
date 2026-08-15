using System.ComponentModel.DataAnnotations;

namespace CarRental.Web.Models;

/// <summary>
/// Admin form model for creating/editing a car. The price is captured as text
/// ("150.50") so the Arabic UI can keep the dot decimal separator — it is
/// parsed once, server-side, in the invariant culture by the controller.
/// Do not use [Range] on PricePerDayText; the validator would re-parse with
/// the request culture and reject the dot.
/// </summary>
public class CarViewModel
{
    public int? Id { get; set; }

    [Required(ErrorMessage = "الموديل مطلوب")]
    [MaxLength(100)]
    [Display(Name = "الموديل")]
    public string CarModel { get; set; } = string.Empty;

    [Required(ErrorMessage = "الماركة مطلوبة")]
    [MaxLength(50)]
    [Display(Name = "الماركة")]
    public string Brand { get; set; } = string.Empty;

    [Required(ErrorMessage = "السعر اليومي مطلوب")]
    [MaxLength(20)]
    [Display(Name = "السعر اليومي")]
    public string PricePerDayText { get; set; } = string.Empty;

    /// <summary>Parsed value — filled in the controller after validation.</summary>
    [Microsoft.AspNetCore.Mvc.ModelBinding.BindNever]
    public decimal PricePerDay { get; set; }

    /// <summary>Optional photo (jpg / jpeg / png / gif / webp, up to 5 MB).</summary>
    [Display(Name = "صورة السيارة")]
    public IFormFile? Image { get; set; }

    /// <summary>Currently stored photo URL — shown in edit forms and forms without an upload.</summary>
    public string? CurrentImageUrl { get; set; }

    /// <summary>True deletes the current photo. Ignored when a new Image is supplied.</summary>
    [Display(Name = "إزالة الصورة الحالية")]
    public bool RemoveImage { get; set; }

    /// <summary>Nullable so "leave status as is" survives round-trips; empty == preserve.</summary>
    [Display(Name = "الحالة")]
    public string? Status { get; set; }
}
