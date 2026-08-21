using System.ComponentModel.DataAnnotations;

namespace CarRental.Application.DTOs;

public class CustomerCreateDto
{
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(150), EmailAddress]
    public string Email { get; set; } = string.Empty;

    [MaxLength(20)]
    [RegularExpression(@"^[0-9+()\-\s]{7,20}$", ErrorMessage = "Phone number format is invalid.")]
    public string Phone { get; set; } = string.Empty;
}
