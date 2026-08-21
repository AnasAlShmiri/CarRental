using System.Security.Claims;
using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Application.Mapping;
using CarRental.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Controllers;

/// <summary>
/// Self-service rental operations for the signed-in customer.
/// The customer id is always read from the JWT; it is never accepted from the client body.
/// </summary>
[ApiController]
[Route("api/customer/rentals")]
[Authorize(Roles = "Customer")]
[Produces("application/json")]
public class CustomerRentalsController(
    IRentalRepository rentals,
    ICarRepository cars) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<RentalDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<RentalDto>>> GetMine()
    {
        var customerId = GetCustomerId();
        if (customerId is null)
            return Unauthorized();

        return Ok((await rentals.GetByCustomerAsync(customerId.Value)).ToDtos());
    }

    [HttpPost]
    [ProducesResponseType(typeof(RentalDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<RentalDto>> Create(CustomerRentalCreateDto dto)
    {
        var customerId = GetCustomerId();
        if (customerId is null)
            return Unauthorized();

        // Rentals are day-based. Strip client time zones and store midnight UTC
        // so Android, Windows, and API servers interpret the same calendar dates.
        var start = DateTime.SpecifyKind(dto.StartDate.Date, DateTimeKind.Utc);
        var end = DateTime.SpecifyKind(dto.EndDate.Date, DateTimeKind.Utc);
        if (start >= end || start.Date < DateTime.UtcNow.Date)
            return Problem(
                detail: "The end date must be after the start date, and the start date cannot be in the past.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid rental dates");

        var car = await cars.GetByIdAsync(dto.CarId);
        if (car is null)
            return Problem(
                detail: $"Car {dto.CarId} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Car not found");

        if (car.Status != CarStatus.Available)
            return Problem(
                detail: "This car is not currently available for booking.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Car unavailable");

        if (await rentals.HasOverlappingRentalAsync(dto.CarId, start, end))
            return Problem(
                detail: "This car is already reserved for part of the selected period.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Booking conflict");

        try
        {
            var created = await rentals.CreateAsync(new Rental
            {
                CarId = dto.CarId,
                CustomerId = customerId.Value,
                StartDate = start,
                EndDate = end
            });

            var hydrated = await rentals.GetByIdAsync(created.Id);
            return CreatedAtAction(
                nameof(GetMine),
                null,
                hydrated?.ToDto() ?? created.ToDto());
        }
        catch (InvalidOperationException ex)
        {
            return Problem(
                detail: ex.Message,
                statusCode: StatusCodes.Status409Conflict,
                title: "Booking could not be completed");
        }
    }

    [HttpPost("{id:int}/cancel")]
    [ProducesResponseType(typeof(RentalDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<RentalDto>> Cancel(int id)
    {
        var customerId = GetCustomerId();
        if (customerId is null)
            return Unauthorized();

        var existing = await rentals.GetByIdAsync(id);
        if (existing is null || existing.CustomerId != customerId.Value)
            return NotFound();

        if (!RentalStatus.IsOpen(existing.Status))
            return Problem(
                detail: "Only an active booking can be cancelled.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Booking is already closed");

        var cancelled = await rentals.ChangeStatusAsync(id, RentalStatus.Cancelled);
        return cancelled is null ? NotFound() : Ok(cancelled.ToDto());
    }

    private int? GetCustomerId()
    {
        var raw = User.FindFirstValue("customer_id");
        return int.TryParse(raw, out var customerId) ? customerId : null;
    }
}
