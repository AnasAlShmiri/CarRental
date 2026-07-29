using CarRental.Domain.Models;

namespace CarRental.Application.Interfaces;

public interface IRentalRepository
{
    Task<IEnumerable<Rental>> GetAllAsync();
    Task<Rental?> GetByIdAsync(int id);
    Task<Rental> CreateAsync(Rental rental);
    Task<Rental?> UpdateAsync(Rental rental);
    Task<bool> DeleteAsync(int id);
}
