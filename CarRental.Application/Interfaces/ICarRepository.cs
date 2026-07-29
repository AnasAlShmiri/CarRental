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
    /// Updates the editable fields. When <paramref name="newStatus"/> is null the car's
    /// current status is preserved — this is the fix for a price edit releasing a rented car.
    /// </summary>
    Task<Car?> UpdateAsync(int id, string model, string brand, decimal pricePerDay, string? imageUrl, string? newStatus);

    Task<bool> DeleteAsync(int id);

    /// <summary>True when the car has a rental that is still Active (blocks deletion).</summary>
    Task<bool> HasActiveRentalsAsync(int id);

    /// <summary>True when the car has any rental at all, in any status (FK Restrict blocks deletion).</summary>
    Task<bool> HasAnyRentalsAsync(int id);
}
