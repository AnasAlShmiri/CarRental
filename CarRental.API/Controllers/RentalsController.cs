using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Application.Mapping;
using CarRental.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize(Roles = "Admin")]
public class RentalsController(
    IRentalRepository rentalRepo,
    ICarRepository carRepo,
    ICustomerRepository customerRepo) : ControllerBase
{
    [HttpGet]
    [Authorize]
    [ProducesResponseType(typeof(IEnumerable<RentalDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<RentalDto>>> GetAll() =>
        Ok((await rentalRepo.GetAllAsync()).ToDtos());

    /// <summary>Administrative view of a customer's rental history.</summary>
    [HttpGet("customer/{customerId:int}")]
    [ProducesResponseType(typeof(IEnumerable<RentalDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<RentalDto>>> GetByCustomer(int customerId)
    {
        if (!await customerRepo.ExistsAsync(customerId))
            return Problem(
                detail: $"Customer {customerId} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        return Ok((await rentalRepo.GetByCustomerAsync(customerId)).ToDtos());
    }

    [HttpGet("{id:int}")]
    [Authorize]
    [ProducesResponseType(typeof(RentalDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<RentalDto>> GetById(int id)
    {
        var rental = await rentalRepo.GetByIdAsync(id);
        if (rental is null)
            return Problem(
                detail: $"Rental {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        return Ok(rental.ToDto());
    }

    /// <summary>
    /// Books a car. The server owns the price calculation and flips the car to "Rented"
    /// atomically with the insert.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(RentalDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<RentalDto>> Create(RentalCreateDto dto)
    {
        var car = await carRepo.GetByIdAsync(dto.CarId);
        if (car is null)
            return Problem(
                detail: $"Car {dto.CarId} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Car not found");

        // BUGFIX: the customer was never validated. A bad CustomerId used to reach the
        // database and blow up as a foreign-key violation (HTTP 500).
        if (!await customerRepo.ExistsAsync(dto.CustomerId))
            return Problem(
                detail: $"Customer {dto.CustomerId} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Customer not found");

        if (dto.EndDate.Date <= dto.StartDate.Date)
            return Problem(
                detail: "EndDate must be at least one day after StartDate.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid rental period");

        // BUGFIX: rentals could previously be booked in the past.
        if (dto.StartDate.Date < DateTime.UtcNow.Date)
            return Problem(
                detail: "StartDate cannot be in the past.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid rental period");

        if (car.Status == CarStatus.UnderMaintenance)
            return Problem(
                detail: "This car is under maintenance and cannot be rented.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Car unavailable");

        // BUGFIX: explicit overlap check. Status alone was not enough to prevent
        // double-booking the same car across two date ranges.
        if (await rentalRepo.HasOverlappingRentalAsync(dto.CarId, dto.StartDate, dto.EndDate))
            return Problem(
                detail: "This car already has an active rental overlapping those dates.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Dates unavailable");

        if (car.Status != CarStatus.Available)
            return Problem(
                detail: $"Car {dto.CarId} is currently '{car.Status}' and cannot be rented.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Car unavailable");

        var created = await rentalRepo.CreateAsync(new Rental
        {
            CarId = dto.CarId,
            CustomerId = dto.CustomerId,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate
        });

        // Re-read so the response carries the Car/Customer summaries.
        var full = await rentalRepo.GetByIdAsync(created.Id);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, (full ?? created).ToDto());
    }

    /// <summary>
    /// Changes the rental period and optionally its status. TotalPrice is always
    /// recalculated server-side; omitting "status" preserves the current one.
    /// </summary>
    [HttpPut("{id:int}")]
    [Authorize]
    [ProducesResponseType(typeof(RentalDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<RentalDto>> Update(int id, RentalUpdateDto dto)
    {
        if (!dto.HasValidStatus())
            return Problem(
                detail: $"Unknown status '{dto.Status}'. Allowed values: {string.Join(", ", RentalStatus.All)}.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid status");

        if (dto.EndDate.Date <= dto.StartDate.Date)
            return Problem(
                detail: "EndDate must be at least one day after StartDate.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid rental period");

        var existing = await rentalRepo.GetByIdAsync(id);
        if (existing is null)
            return Problem(
                detail: $"Rental {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        // Don't let an edit push this rental onto another active booking of the same car.
        if (await rentalRepo.HasOverlappingRentalAsync(existing.CarId, dto.StartDate, dto.EndDate, excludeRentalId: id))
            return Problem(
                detail: "Another active rental for this car overlaps those dates.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Dates unavailable");

        // BUGFIX: reopening a closed rental (status back to Active) used to flip the car
        // to "Rented" unconditionally — even a car that had been moved to maintenance.
        var reopening = !RentalStatus.IsOpen(existing.Status) && dto.Status == RentalStatus.Active;
        if (reopening && existing.Car?.Status == CarStatus.UnderMaintenance)
            return Problem(
                detail: "This rental's car is under maintenance, so the rental cannot be reopened. " +
                        "Set the car back to Available first.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Car under maintenance");

        var updated = await rentalRepo.UpdateAsync(id, dto.StartDate, dto.EndDate, dto.Status);
        if (updated is null)
            return Problem(
                detail: $"Rental {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        var full = await rentalRepo.GetByIdAsync(id);
        return Ok((full ?? updated).ToDto());
    }

    /// <summary>
    /// Marks the rental Completed and releases the car back to "Available".
    /// The API previously had no way to do this, so cars stayed "Rented" forever.
    /// </summary>
    [HttpPut("{id:int}/complete")]
    [Authorize]
    [ProducesResponseType(typeof(RentalDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public Task<ActionResult<RentalDto>> Complete(int id) =>
        TransitionAsync(id, RentalStatus.Completed);

    /// <summary>Marks the rental Cancelled and releases the car back to "Available".</summary>
    [HttpPut("{id:int}/cancel")]
    [Authorize]
    [ProducesResponseType(typeof(RentalDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public Task<ActionResult<RentalDto>> Cancel(int id) =>
        TransitionAsync(id, RentalStatus.Cancelled);

    [HttpDelete("{id:int}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        // The repository also releases the car — deleting an active rental used to
        // leave its car permanently stuck on "Rented".
        var deleted = await rentalRepo.DeleteAsync(id);
        if (!deleted)
            return Problem(
                detail: $"Rental {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        return NoContent();
    }

    private async Task<ActionResult<RentalDto>> TransitionAsync(int id, string target)
    {
        var existing = await rentalRepo.GetByIdAsync(id);
        if (existing is null)
            return Problem(
                detail: $"Rental {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        if (existing.Status == target)
            return Problem(
                detail: $"Rental {id} is already '{target}'.",
                statusCode: StatusCodes.Status409Conflict,
                title: "No change");

        if (!RentalStatus.IsOpen(existing.Status))
            return Problem(
                detail: $"Rental {id} is '{existing.Status}' and can no longer be changed.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Rental is closed");

        var updated = await rentalRepo.ChangeStatusAsync(id, target);
        if (updated is null)
            return Problem(
                detail: $"Rental {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        var full = await rentalRepo.GetByIdAsync(id);
        return Ok((full ?? updated).ToDto());
    }
}
