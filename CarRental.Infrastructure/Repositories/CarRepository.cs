using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using CarRental.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Repositories;

public class CarRepository(ApplicationDbContext db) : ICarRepository
{
    public async Task<IEnumerable<Car>> GetAllAsync() =>
        await db.Cars.AsNoTracking().ToListAsync();

    public async Task<Car?> GetByIdAsync(int id) =>
        await db.Cars.FindAsync(id);

    public async Task<Car> CreateAsync(Car car)
    {
        db.Cars.Add(car);
        await db.SaveChangesAsync();
        return car;
    }

    public async Task<Car?> UpdateAsync(Car car)
    {
        var existing = await db.Cars.FindAsync(car.Id);
        if (existing is null) return null;

        existing.Model = car.Model;
        existing.Brand = car.Brand;
        existing.PricePerDay = car.PricePerDay;
        existing.Status = car.Status;

        await db.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var car = await db.Cars.FindAsync(id);
        if (car is null) return false;

        db.Cars.Remove(car);
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> HasRentalsAsync(int id) =>
        await db.Rentals.AnyAsync(r => r.CarId == id);
}
