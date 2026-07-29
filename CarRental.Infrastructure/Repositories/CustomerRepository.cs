using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using CarRental.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Repositories;

public class CustomerRepository(ApplicationDbContext db) : ICustomerRepository
{
    public async Task<IEnumerable<Customer>> GetAllAsync() =>
        await db.Customers.AsNoTracking().ToListAsync();

    public async Task<Customer?> GetByIdAsync(int id) =>
        await db.Customers.FindAsync(id);

    public async Task<Customer> CreateAsync(Customer customer)
    {
        db.Customers.Add(customer);
        await db.SaveChangesAsync();
        return customer;
    }

    public async Task<Customer?> UpdateAsync(Customer customer)
    {
        var existing = await db.Customers.FindAsync(customer.Id);
        if (existing is null) return null;

        existing.Name = customer.Name;
        existing.Email = customer.Email;
        existing.Phone = customer.Phone;

        await db.SaveChangesAsync();
        return existing;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var customer = await db.Customers.FindAsync(id);
        if (customer is null) return false;

        db.Customers.Remove(customer);
        await db.SaveChangesAsync();
        return true;
    }
}
