namespace CarRental.Domain.Models;

/// <summary>
/// Allowed values for <see cref="Rental.Status"/>.
/// </summary>
public static class RentalStatus
{
    public const string Active = "Active";
    public const string Completed = "Completed";
    public const string Cancelled = "Cancelled";

    public static readonly string[] All = [Active, Completed, Cancelled];

    public static bool IsValid(string? value) =>
        value is not null && All.Contains(value, StringComparer.Ordinal);

    /// <summary>A rental that still holds its car (blocks the car from being re-rented).</summary>
    public static bool IsOpen(string? value) => value == Active;
}
