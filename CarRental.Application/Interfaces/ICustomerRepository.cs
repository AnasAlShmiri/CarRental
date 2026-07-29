using CarRental.Domain.Models;

namespace CarRental.Application.Interfaces;

public interface ICustomerRepository
{
    Task<IEnumerable<Customer>> GetAllAsync();

    Task<Customer?> GetByIdAsync(int id);

    Task<bool> ExistsAsync(int id);

    /// <summary>
    /// Email has a unique index. Checking up front turns what used to be an
    /// unhandled DbUpdateException (HTTP 500) into a clean 409 Conflict.
    /// </summary>
    Task<bool> EmailExistsAsync(string email, int? excludeCustomerId = null);

    Task<Customer> CreateAsync(Customer customer);

    Task<Customer?> UpdateAsync(int id, string name, string email, string phone);

    Task<bool> DeleteAsync(int id);

    /// <summary>True when the customer has a rental that is still Active.</summary>
    Task<bool> HasActiveRentalsAsync(int id);

    /// <summary>True when the customer has any rental at all (FK is Restrict, so deletion would fail).</summary>
    Task<bool> HasAnyRentalsAsync(int id);
}
