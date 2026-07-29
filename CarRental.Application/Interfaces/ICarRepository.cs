using CarRental.Domain.Models;

namespace CarRental.Application.Interfaces;

public interface ICarRepository
{
    Task<IEnumerable<Car>> GetAllAsync();
    Task<Car?> GetByIdAsync(int id);
    Task<Car> CreateAsync(Car car);
    Task<Car?> UpdateAsync(Car car);
    Task<bool> DeleteAsync(int id);
    Task<bool> HasRentalsAsync(int id);
}
