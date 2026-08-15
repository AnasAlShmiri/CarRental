using System.ComponentModel.DataAnnotations;

namespace CarRental.Web.Models;

public class RentalViewModel
{
    [Required(ErrorMessage = "السيارة مطلوبة")]
    [Range(1, int.MaxValue, ErrorMessage = "اختر سيارة من القائمة")]
    [Display(Name = "السيارة")]
    public int CarId { get; set; }

    [Required(ErrorMessage = "العميل مطلوب")]
    [Range(1, int.MaxValue, ErrorMessage = "اختر عميلاً من القائمة")]
    [Display(Name = "العميل")]
    public int CustomerId { get; set; }

    [Required(ErrorMessage = "تاريخ البداية مطلوب")]
    [DataType(DataType.Date)]
    [Display(Name = "تاريخ البداية")]
    public DateTime StartDate { get; set; } = DateTime.UtcNow.Date.AddDays(1);

    [Required(ErrorMessage = "تاريخ النهاية مطلوب")]
    [DataType(DataType.Date)]
    [Display(Name = "تاريخ النهاية")]
    public DateTime EndDate { get; set; } = DateTime.UtcNow.Date.AddDays(3);

    /// <summary>Client-side hint only — the server recalculates the price in UTC.</summary>
    public int DurationInDays =>
        Math.Max(1, (EndDate.Date - StartDate.Date).Days);
}
