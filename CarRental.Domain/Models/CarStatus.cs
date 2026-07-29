namespace CarRental.Domain.Models;

/// <summary>
/// Allowed values for <see cref="Car.Status"/>.
/// Kept as string constants (not an enum) so the existing nvarchar(20) column
/// and the previously generated migration stay valid.
/// </summary>
public static class CarStatus
{
    public const string Available = "Available";
    public const string Rented = "Rented";
    public const string UnderMaintenance = "UnderMaintenance";

    public static readonly string[] All = [Available, Rented, UnderMaintenance];

    public static bool IsValid(string? value) =>
        value is not null && All.Contains(value, StringComparer.Ordinal);
}
