using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using CarRental.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Repositories;

public class StatisticsRepository(ApplicationDbContext db) : IStatisticsRepository
{
    public async Task<StatisticsDto> GetAsync(int monthsOfRevenue = 6)
    {
        // ── fleet ────────────────────────────────────────────────────────────
        var carsTotal = await db.Cars.CountAsync();
        var carsAvailable = await db.Cars.CountAsync(c => c.Status == CarStatus.Available);
        var carsRented = await db.Cars.CountAsync(c => c.Status == CarStatus.Rented);
        var carsMaintenance = await db.Cars.CountAsync(c => c.Status == CarStatus.UnderMaintenance);

        // ── customers ────────────────────────────────────────────────────────
        var customersTotal = await db.Customers.CountAsync();

        // ── rentals ──────────────────────────────────────────────────────────
        var rentalsTotal = await db.Rentals.CountAsync();
        var rentalsActive = await db.Rentals.CountAsync(r => r.Status == RentalStatus.Active);
        var rentalsCompleted = await db.Rentals.CountAsync(r => r.Status == RentalStatus.Completed);
        var rentalsCancelled = await db.Rentals.CountAsync(r => r.Status == RentalStatus.Cancelled);

        // ── revenue ──────────────────────────────────────────────────────────
        // Cast to nullable so an empty table sums to null (-> 0) instead of throwing.
        var revenueTotal = await db.Rentals
            .Where(r => r.Status == RentalStatus.Completed)
            .SumAsync(r => (decimal?)r.TotalPrice) ?? 0m;

        var revenueActive = await db.Rentals
            .Where(r => r.Status == RentalStatus.Active)
            .SumAsync(r => (decimal?)r.TotalPrice) ?? 0m;

        // ── monthly revenue chart ────────────────────────────────────────────
        // The window is small (a handful of rows for a course project), so the rows are
        // fetched and grouped in memory — identical behaviour on SQL Server and SQLite,
        // with no provider-specific date-translation surprises.
        var window = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc)
            .AddMonths(-(monthsOfRevenue - 1));

        var completed = await db.Rentals
            .AsNoTracking()
            .Where(r => r.Status == RentalStatus.Completed && r.CreatedAt >= window)
            .Select(r => new { r.CreatedAt, r.TotalPrice })
            .ToListAsync();

        var monthly = completed
            .GroupBy(r => new { r.CreatedAt.Year, r.CreatedAt.Month })
            .Select(g => new MonthlyRevenueDto(g.Key.Year, g.Key.Month, g.Sum(x => x.TotalPrice)))
            .OrderBy(m => m.Year).ThenBy(m => m.Month)
            .ToList();

        return new StatisticsDto(
            new CarStatsDto(carsTotal, carsAvailable, carsRented, carsMaintenance),
            new CustomerStatsDto(customersTotal),
            new RentalStatsDto(rentalsTotal, rentalsActive, rentalsCompleted, rentalsCancelled),
            new RevenueStatsDto(revenueTotal, revenueActive),
            monthly);
    }
}
