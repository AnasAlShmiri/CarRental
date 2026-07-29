using CarRental.Domain.Models;

namespace CarRental.Application.Interfaces;

public interface ICarRepository
{
    Task<IEnumerable<Car>> GetAllAsync();

    /// <summary>Optionally filter by status, e.g. only "Available" cars for the mobile app.</summary>
    Task<IEnumerable<Car>> GetByStatusAsync(string status);

    Task<Car?> GetByIdAsync(int id);

    Task<bool> ExistsAsync(int id);

    Task<Car> CreateAsync(Car car);

    /// <summary>
    /// Updates the editable fields.
    /// <para>
    /// <paramref name="newStatus"/> null preserves the current status — this is the fix for a
    /// price edit releasing a rented car.
    /// </para>
    /// <para>
    /// <paramref name="imageUrl"/> follows the same rule: null preserves the existing image,
    /// so editing a price does not silently discard an uploaded photo. Pass an empty string
    /// to deliberately clear it.
    /// </para>
    /// </summary>
    Task<Car?> UpdateAsync(int id, string model, string brand, decimal pricePerDay, string? imageUrl, string? newStatus);

    Task<bool> DeleteAsync(int id);

    /// <summary>True when the car has a rental that is still Active (blocks deletion).</summary>
    Task<bool> HasActiveRentalsAsync(int id);

    /// <summary>True when the car has any rental at all, in any status (FK Restrict blocks deletion).</summary>
    Task<bool> HasAnyRentalsAsync(int id);
}
