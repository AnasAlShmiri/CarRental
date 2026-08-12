using System.ComponentModel.DataAnnotations;

namespace CarRental.Web.Models;

public class CustomerViewModel
{
    public int? Id { get; set; }

    [Required(ErrorMessage = "اسم العميل مطلوب")]
    [MaxLength(100)]
    [Display(Name = "الاسم")]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "البريد الإلكتروني مطلوب")]
    [EmailAddress(ErrorMessage = "بريد إلكتروني غير صالح")]
    [MaxLength(100)]
    [Display(Name = "البريد الإلكتروني")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "رقم الهاتف مطلوب")]
    [MaxLength(20)]
    [Phone(ErrorMessage = "رقم هاتف غير صالح")]
    [Display(Name = "رقم الهاتف")]
    public string Phone { get; set; } = string.Empty;

}
