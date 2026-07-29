using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using CarRental.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Repositories;

public class CarRepository(ApplicationDbContext db) : ICarRepository
{
    public async Task<IEnumerable<Car>> GetAllAsync() =>
        await db.Cars.AsNoTracking().OrderBy(c => c.Id).ToListAsync();

    public async Task<IEnumerable<Car>> GetByStatusAsync(string status) =>
        await db.Cars.AsNoTracking()
                     .Where(c => c.Status == status)
                     .OrderBy(c => c.Id)
                     .ToListAsync();

    public async Task<Car?> GetByIdAsync(int id) =>
        await db.Cars.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);

    public async Task<bool> ExistsAsync(int id) =>
        await db.Cars.AnyAsync(c => c.Id == id);

    public async Task<Car> CreateAsync(Car car)
    {
        // A new car is always available, and CreatedAt is server-owned.
        car.Status = CarStatus.Available;
        car.CreatedAt = DateTime.UtcNow;

        db.Cars.Add(car);
        await db.SaveChangesAsync();
        return car;
    }

    public async Task<Car?> UpdateAsync(
        int id, string model, string brand, decimal pricePerDay, string? imageUrl, string? newStatus)
    {
        var existing = await db.Cars.FirstOrDefaultAsync(c => c.Id == id);
        if (existing is null) return null;

        existing.Model = model;
        existing.Brand = brand;
        existing.PricePerDay = pricePerDay;

        // BUGFIX: only touch Status when the caller explicitly supplied one.
        // The previous version always assigned it, so the create-DTO's default
        // ("Available") silently released a car that was actually Rented.
        if (newStatus is not null)
            existing.Status = newStatus;

        // Same rule for the photo: null means "leave it alone", so editing a price
        // through the dashboard cannot silently wipe an uploaded image. An empty
        // string is an explicit "remove the photo".
        if (imageUrl is not null)
            existing.ImageUrl = imageUrl.Length == 0 ? null : imageUrl;

        // CreatedAt is never reassigned — it stays as originally recorded.
        await db.SaveChangesAsync();
        return existing;
    }

    public async Task<Car?> SetImageUrlAsync(int id, string? imageUrl)
    {
        var existing = await db.Cars.FirstOrDefaultAsync(c => c.Id == id);
        if (existing is null) return null;

        existing.ImageUrl = imageUrl;
        await db.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var car = await db.Cars.FirstOrDefaultAsync(c => c.Id == id);
        if (car is null) return false;

        db.Cars.Remove(car);
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> HasActiveRentalsAsync(int id) =>
        await db.Rentals.AnyAsync(r => r.CarId == id && r.Status == RentalStatus.Active);

    public async Task<bool> HasAnyRentalsAsync(int id) =>
        await db.Rentals.AnyAsync(r => r.CarId == id);
}
