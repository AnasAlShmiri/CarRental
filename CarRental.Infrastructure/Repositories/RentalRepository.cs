using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using CarRental.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Repositories;

public class RentalRepository(ApplicationDbContext db) : IRentalRepository
{
    public async Task<IEnumerable<Rental>> GetAllAsync() =>
        await db.Rentals
                .AsNoTracking()
                .Include(r => r.Car)
                .Include(r => r.Customer)
                .ToListAsync();

    public async Task<Rental?> GetByIdAsync(int id) =>
        await db.Rentals
                .Include(r => r.Car)
                .Include(r => r.Customer)
                .FirstOrDefaultAsync(r => r.Id == id);

    public async Task<Rental> CreateAsync(Rental rental)
    {
        db.Rentals.Add(rental);
        await db.SaveChangesAsync();
        return rental;
    }

    public async Task<Rental?> UpdateAsync(Rental rental)
    {
        var existing = await db.Rentals.FindAsync(rental.Id);
        if (existing is null) return null;

        existing.StartDate = rental.StartDate;
        existing.EndDate = rental.EndDate;
        existing.TotalPrice = rental.TotalPrice;
        existing.Status = rental.Status;

        await db.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var rental = await db.Rentals.FindAsync(id);
        if (rental is null) return false;

        db.Rentals.Remove(rental);
        await db.SaveChangesAsync();
        return true;
    }
}
