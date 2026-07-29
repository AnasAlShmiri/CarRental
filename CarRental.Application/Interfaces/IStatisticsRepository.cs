using CarRental.Application.DTOs;

namespace CarRental.Application.Interfaces;

/// <summary>Aggregated dashboard numbers.</summary>
public interface IStatisticsRepository
{
    /// <param name="monthsOfRevenue">How many recent months the revenue chart covers.</param>
    Task<StatisticsDto> GetAsync(int monthsOfRevenue = 6);
}
