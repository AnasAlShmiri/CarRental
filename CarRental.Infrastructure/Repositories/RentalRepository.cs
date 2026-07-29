using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using CarRental.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Repositories;

/// <summary>
/// Rental persistence. Every write here batches all of its changes into a single
/// <c>SaveChangesAsync</c> call, which EF Core wraps in one implicit transaction.
/// That is what makes "create rental + mark car rented" atomic without needing an
/// explicit transaction (and keeps the code provider-agnostic).
/// </summary>
public class RentalRepository(ApplicationDbContext db) : IRentalRepository
{
    public async Task<IEnumerable<Rental>> GetAllAsync() =>
        await db.Rentals
                .AsNoTracking()
                .Include(r => r.Car)
                .Include(r => r.Customer)
                .OrderByDescending(r => r.Id)
                .ToListAsync();

    public async Task<IEnumerable<Rental>> GetByCustomerAsync(int customerId) =>
        await db.Rentals
                .AsNoTracking()
                .Include(r => r.Car)
                .Include(r => r.Customer)
                .Where(r => r.CustomerId == customerId)
                .OrderByDescending(r => r.Id)
                .ToListAsync();

    public async Task<Rental?> GetByIdAsync(int id) =>
        await db.Rentals
                .AsNoTracking()
                .Include(r => r.Car)
                .Include(r => r.Customer)
                .FirstOrDefaultAsync(r => r.Id == id);

    public async Task<bool> HasOverlappingRentalAsync(
        int carId, DateTime start, DateTime end, int? excludeRentalId = null) =>
        await db.Rentals.AnyAsync(r =>
            r.CarId == carId &&
            r.Status == RentalStatus.Active &&
            (excludeRentalId == null || r.Id != excludeRentalId) &&
            // Half-open interval overlap: [start, end) intersects [r.StartDate, r.EndDate)
            r.StartDate < end && start < r.EndDate);

    public async Task<Rental> CreateAsync(Rental rental)
    {
        var car = await db.Cars.FirstOrDefaultAsync(c => c.Id == rental.CarId)
                  ?? throw new InvalidOperationException($"Car {rental.CarId} does not exist.");

        rental.Status = RentalStatus.Active;
        rental.CreatedAt = DateTime.UtcNow;
        rental.TotalPrice = CalculatePrice(car.PricePerDay, rental.StartDate, rental.EndDate);

        db.Rentals.Add(rental);
        car.Status = CarStatus.Rented;

        // Single SaveChanges => insert + status update commit or fail together.
        await db.SaveChangesAsync();

        return rental;
    }

    public async Task<Rental?> UpdateAsync(int id, DateTime startDate, DateTime endDate, string? newStatus)
    {
        var existing = await db.Rentals
                               .Include(r => r.Car)
                               .FirstOrDefaultAsync(r => r.Id == id);
        if (existing is null) return null;

        var previousStatus = existing.Status;

        existing.StartDate = startDate;
        existing.EndDate = endDate;

        // BUGFIX: TotalPrice is recalculated server-side. The old endpoint never set it,
        // so every update silently zeroed the price.
        existing.TotalPrice = CalculatePrice(existing.Car.PricePerDay, startDate, endDate);

        // BUGFIX: null means "keep current status" instead of resetting to "Active".
        if (newStatus is not null)
            existing.Status = newStatus;

        // If this update closed the rental, the car must be released.
        if (RentalStatus.IsOpen(previousStatus) && !RentalStatus.IsOpen(existing.Status))
            await ReleaseCarIfFreeAsync(existing.CarId, excludeRentalId: existing.Id);

        // If it re-opened a closed rental, the car goes back to Rented.
        if (!RentalStatus.IsOpen(previousStatus) && RentalStatus.IsOpen(existing.Status))
            existing.Car.Status = CarStatus.Rented;

        await db.SaveChangesAsync();
        return existing;
    }

    public async Task<Rental?> ChangeStatusAsync(int id, string newStatus)
    {
        var existing = await db.Rentals
                               .Include(r => r.Car)
                               .FirstOrDefaultAsync(r => r.Id == id);
        if (existing is null) return null;

        var wasOpen = RentalStatus.IsOpen(existing.Status);
        existing.Status = newStatus;

        if (wasOpen && !RentalStatus.IsOpen(newStatus))
            await ReleaseCarIfFreeAsync(existing.CarId, excludeRentalId: existing.Id);
        else if (!wasOpen && RentalStatus.IsOpen(newStatus))
            existing.Car.Status = CarStatus.Rented;

        await db.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var rental = await db.Rentals.FirstOrDefaultAsync(r => r.Id == id);
        if (rental is null) return false;

        db.Rentals.Remove(rental);

        // BUGFIX: releasing the car was missing entirely, so deleting an active
        // rental left the car permanently stuck on "Rented".
        await ReleaseCarIfFreeAsync(rental.CarId, excludeRentalId: rental.Id);

        await db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// Sets the car back to "Available" — but only when no *other* Active rental still holds
    /// it, and only when it is currently "Rented" (so a car under maintenance is not
    /// accidentally put back into circulation).
    /// </summary>
    private async Task ReleaseCarIfFreeAsync(int carId, int excludeRentalId)
    {
        var stillHeld = await db.Rentals.AnyAsync(r =>
            r.CarId == carId &&
            r.Id != excludeRentalId &&
            r.Status == RentalStatus.Active);

        if (stillHeld) return;

        var car = await db.Cars.FirstOrDefaultAsync(c => c.Id == carId);
        if (car is not null && car.Status == CarStatus.Rented)
            car.Status = CarStatus.Available;
    }

    /// <summary>Days are billed on whole calendar days, with a one-day minimum.</summary>
    private static decimal CalculatePrice(decimal pricePerDay, DateTime start, DateTime end)
    {
        var days = Math.Max(1, (end.Date - start.Date).Days);
        return decimal.Round(pricePerDay * days, 2, MidpointRounding.AwayFromZero);
    }
}
