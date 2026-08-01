using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using CarRental.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Repositories;

public class CustomerRepository(ApplicationDbContext db) : ICustomerRepository
{
    public async Task<IEnumerable<Customer>> GetAllAsync() =>
        await db.Customers.AsNoTracking().OrderBy(c => c.Id).ToListAsync();

    public async Task<Customer?> GetByIdAsync(int id) =>
        await db.Customers.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);

    public async Task<bool> ExistsAsync(int id) =>
        await db.Customers.AnyAsync(c => c.Id == id);

    // BUGFIX: the comparison was culture/provider dependent — SQL Server's default
    // collation is case-insensitive but SQLite's is case-sensitive, so
    // "ANAS@example.com" slipped past this check on SQLite and created a duplicate.
    // Normalising both sides makes every provider behave the same way.
    public async Task<bool> EmailExistsAsync(string email, int? excludeCustomerId = null) =>
        await db.Customers.AnyAsync(c =>
            c.Email.ToLower() == email.ToLower() &&
            (excludeCustomerId == null || c.Id != excludeCustomerId));

    public async Task<Customer> CreateAsync(Customer customer)
    {
        customer.CreatedAt = DateTime.UtcNow;

        db.Customers.Add(customer);
        await db.SaveChangesAsync();
        return customer;
    }

    public async Task<Customer?> UpdateAsync(int id, string name, string email, string phone)
    {
        var existing = await db.Customers.FirstOrDefaultAsync(c => c.Id == id);
        if (existing is null) return null;

        existing.Name = name;
        existing.Email = email;
        existing.Phone = phone;

        // CreatedAt intentionally untouched.
        await db.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var customer = await db.Customers.FirstOrDefaultAsync(c => c.Id == id);
        if (customer is null) return false;

        db.Customers.Remove(customer);
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> HasActiveRentalsAsync(int id) =>
        await db.Rentals.AnyAsync(r => r.CustomerId == id && r.Status == RentalStatus.Active);

    public async Task<bool> HasAnyRentalsAsync(int id) =>
        await db.Rentals.AnyAsync(r => r.CustomerId == id);
}
