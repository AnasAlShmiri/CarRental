using CarRental.Application.DTOs;
using CarRental.Domain.Models;

namespace CarRental.Application.Mapping;

/// <summary>Hand-written entity -> DTO projections (no AutoMapper dependency needed).</summary>
public static class EntityMappings
{
    public static CarDto ToDto(this Car car) => new(
        car.Id, car.Model, car.Brand, car.PricePerDay, car.ImageUrl, car.Status, car.CreatedAt);

    public static CustomerDto ToDto(this Customer c) => new(
        c.Id, c.Name, c.Email, c.Phone, c.CreatedAt);

    public static CarSummaryDto ToSummary(this Car car) => new(
        car.Id, car.Model, car.Brand, car.PricePerDay, car.ImageUrl);

    public static CustomerSummaryDto ToSummary(this Customer c) => new(c.Id, c.Name, c.Email);

    public static RentalDto ToDto(this Rental r) => new(
        r.Id,
        r.CarId,
        r.CustomerId,
        r.StartDate,
        r.EndDate,
        Math.Max(1, (r.EndDate.Date - r.StartDate.Date).Days),
        r.TotalPrice,
        r.Status,
        r.CreatedAt,
        // Navigation properties are only populated when the repository Include()s them.
        r.Car is null ? null : r.Car.ToSummary(),
        r.Customer is null ? null : r.Customer.ToSummary());

    public static IEnumerable<CarDto> ToDtos(this IEnumerable<Car> cars) => cars.Select(ToDto);
    public static IEnumerable<CustomerDto> ToDtos(this IEnumerable<Customer> cs) => cs.Select(ToDto);
    public static IEnumerable<RentalDto> ToDtos(this IEnumerable<Rental> rs) => rs.Select(ToDto);
}
