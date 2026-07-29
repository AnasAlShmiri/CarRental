namespace CarRental.Application.DTOs;

/// <summary>
/// Response shapes returned by the API.
/// <para>
/// The controllers used to return EF entities directly, which serialised the whole
/// navigation graph (car -> rentals -> car -> ...) and only worked because
/// <c>ReferenceHandler.IgnoreCycles</c> papered over it. Returning explicit read models
/// keeps responses small, stable, and safe to expose to the Flutter app.
/// </para>
/// </summary>
public record CarDto(
    int Id,
    string Model,
    string Brand,
    decimal PricePerDay,
    string? ImageUrl,
    string Status,
    DateTime CreatedAt);

public record CustomerDto(
    int Id,
    string Name,
    string Email,
    string Phone,
    DateTime CreatedAt);

/// <summary>Compact car/customer info embedded inside a rental response.</summary>
public record CarSummaryDto(int Id, string Model, string Brand, decimal PricePerDay, string? ImageUrl);

public record CustomerSummaryDto(int Id, string Name, string Email);

public record RentalDto(
    int Id,
    int CarId,
    int CustomerId,
    DateTime StartDate,
    DateTime EndDate,
    int DurationInDays,
    decimal TotalPrice,
    string Status,
    DateTime CreatedAt,
    CarSummaryDto? Car,
    CustomerSummaryDto? Customer);
