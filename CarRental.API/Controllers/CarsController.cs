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
public class CarsController(ICarRepository repo) : ControllerBase
{
    /// <summary>Lists cars, optionally filtered by status (Available | Rented | UnderMaintenance).</summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(typeof(IEnumerable<CarDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<CarDto>>> GetAll([FromQuery] string? status)
    {
        if (status is not null && !CarStatus.IsValid(status))
            return Problem(
                detail: $"Unknown status '{status}'. Allowed values: {string.Join(", ", CarStatus.All)}.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid status filter");

        var cars = status is null
            ? await repo.GetAllAsync()
            : await repo.GetByStatusAsync(status);

        return Ok(cars.ToDtos());
    }

    /// <summary>Convenience endpoint for the mobile app: only cars that can be rented right now.</summary>
    /// <remarks>
    /// This literal route sits safely beside "{id:int}" because of the :int constraint.
    /// Without that constraint the two would be an ambiguous match at startup.
    /// </remarks>
    [HttpGet("available")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(IEnumerable<CarDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<CarDto>>> GetAvailable() =>
        Ok((await repo.GetByStatusAsync(CarStatus.Available)).ToDtos());

    [HttpGet("{id:int}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CarDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CarDto>> GetById(int id)
    {
        var car = await repo.GetByIdAsync(id);
        if (car is null)
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        return Ok(car.ToDto());
    }

    [HttpPost]
    [Authorize]
    [ProducesResponseType(typeof(CarDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CarDto>> Create(CarCreateDto dto)
    {
        var created = await repo.CreateAsync(new Car
        {
            Model = dto.Model,
            Brand = dto.Brand,
            PricePerDay = dto.PricePerDay,
            ImageUrl = dto.ImageUrl
        });

        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created.ToDto());
    }

    /// <summary>
    /// Updates a car. Omit "status" to keep the current one — an explicit value is the only
    /// way to change it, which stops a price edit from silently releasing a rented car.
    /// </summary>
    [HttpPut("{id:int}")]
    [Authorize]
    [ProducesResponseType(typeof(CarDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CarDto>> Update(int id, CarUpdateDto dto)
    {
        if (!dto.HasValidStatus())
            return Problem(
                detail: $"Unknown status '{dto.Status}'. Allowed values: {string.Join(", ", CarStatus.All)}.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid status");

        var updated = await repo.UpdateAsync(id, dto.Model, dto.Brand, dto.PricePerDay, dto.ImageUrl, dto.Status);
        if (updated is null)
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        return Ok(updated.ToDto());
    }

    [HttpDelete("{id:int}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete(int id)
    {
        if (!await repo.ExistsAsync(id))
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        // The message now matches the check. Previously it said "active rentals" while
        // actually blocking on *any* rental, including completed ones.
        if (await repo.HasActiveRentalsAsync(id))
            return Problem(
                detail: "Cannot delete a car with an active rental. Complete or cancel the rental first.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Car is rented");

        // The FK is Restrict, so historical rentals block a hard delete too.
        // Say so explicitly instead of letting it surface as an opaque 500.
        if (await repo.HasAnyRentalsAsync(id))
            return Problem(
                detail: "Cannot delete a car that has rental history. Set its status to 'UnderMaintenance' to take it out of circulation instead.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Car has rental history");

        await repo.DeleteAsync(id);
        return NoContent();
    }
}
