using CarRental.Domain.Models;

namespace CarRental.Application.Interfaces;

public interface IRentalRepository
{
    Task<IEnumerable<Rental>> GetAllAsync();

    Task<IEnumerable<Rental>> GetByCustomerAsync(int customerId);

    Task<Rental?> GetByIdAsync(int id);

    /// <summary>
    /// True when the car already has an Active rental whose date range overlaps
    /// [<paramref name="start"/>, <paramref name="end"/>).
    /// </summary>
    Task<bool> HasOverlappingRentalAsync(int carId, DateTime start, DateTime end, int? excludeRentalId = null);

    /// <summary>
    /// Persists the rental <b>and</b> flips the car to "Rented" inside a single transaction.
    /// Previously these were two separate SaveChanges calls, so a failure on the second
    /// left the car marked Rented with no rental behind it.
    /// </summary>
    Task<Rental> CreateAsync(Rental rental);

    /// <summary>
    /// Updates dates and (optionally) status, recalculating TotalPrice from the car's
    /// daily rate. Passing null for <paramref name="newStatus"/> preserves the current status.
    /// </summary>
    Task<Rental?> UpdateAsync(int id, DateTime startDate, DateTime endDate, string? newStatus);

    /// <summary>
    /// Moves a rental to Completed or Cancelled and releases the car back to "Available"
    /// in one transaction. This is the lifecycle step the API was missing entirely.
    /// </summary>
    Task<Rental?> ChangeStatusAsync(int id, string newStatus);

    /// <summary>
    /// Deletes the rental and releases its car if no other Active rental holds it.
    /// The old implementation left the car stuck on "Rented" forever.
    /// </summary>
    Task<bool> DeleteAsync(int id);
}
