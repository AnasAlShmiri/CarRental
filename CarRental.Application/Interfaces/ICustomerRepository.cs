using CarRental.Domain.Models;

namespace CarRental.Application.Interfaces;

public interface ICustomerRepository
{
    Task<IEnumerable<Customer>> GetAllAsync();
    Task<Customer?> GetByIdAsync(int id);
    Task<Customer> CreateAsync(Customer customer);
    Task<Customer?> UpdateAsync(Customer customer);
    Task<bool> DeleteAsync(int id);
}
