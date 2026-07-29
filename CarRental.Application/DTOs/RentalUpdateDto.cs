using System.ComponentModel.DataAnnotations;
using CarRental.Domain.Models;

namespace CarRental.Application.DTOs;

/// <summary>
/// Payload for updating a rental's dates and/or status.
/// <para>
/// <b>CarId / CustomerId are deliberately absent.</b> The old endpoint accepted them but the
/// repository never copied them, so callers were silently lied to. Moving a rental to a
/// different car is a cancel-and-rebook operation, not an edit.
/// </para>
/// <para>
/// <c>TotalPrice</c> is never accepted from the client — it is always recalculated on the
/// server from the car's daily rate. The old endpoint left it unset, which zeroed it out.
/// </para>
/// </summary>
public class RentalUpdateDto
{
    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }

    /// <summary>Optional. When null the existing status is preserved.</summary>
    [MaxLength(20)]
    public string? Status { get; set; }

    public bool HasValidStatus() => Status is null || RentalStatus.IsValid(Status);
}
