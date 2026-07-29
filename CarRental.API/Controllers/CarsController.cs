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
public class CarsController(ICarRepository repo, ICarImageStorage images) : ControllerBase
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

        // Remember the current photo so a change or explicit clear does not leave the
        // old file orphaned on disk.
        var previousImage = (await repo.GetByIdAsync(id))?.ImageUrl;

        var updated = await repo.UpdateAsync(id, dto.Model, dto.Brand, dto.PricePerDay, dto.ImageUrl, dto.Status);
        if (updated is null)
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        if (previousImage is not null &&
            !string.Equals(previousImage, updated.ImageUrl, StringComparison.OrdinalIgnoreCase))
            images.TryDelete(previousImage);

        return Ok(updated.ToDto());
    }

    /// <summary>
    /// Uploads a photo for a car from your computer and stores it under wwwroot/uploads,
    /// then points the car's ImageUrl at it. Replacing a photo deletes the previous file.
    /// </summary>
    /// <remarks>
    /// Accepts jpg, jpeg, png, gif and webp up to 5 MB. The file's real format is verified
    /// from its header, so renaming another file type to .jpg will be rejected.
    /// </remarks>
    [HttpPost("{id:int}/image")]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(CarDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CarDto>> UploadImage(int id, IFormFile file, CancellationToken ct)
    {
        var car = await repo.GetByIdAsync(id);
        if (car is null)
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        if (file is null || file.Length == 0)
            return Problem(
                detail: "No file was received. Choose an image file in the 'file' field and try again.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "No file uploaded");

        await using var stream = file.OpenReadStream();
        var outcome = await images.SaveAsync(stream, file.FileName, file.Length, ct);

        if (!outcome.Success)
            return Problem(
                detail: outcome.Error,
                statusCode: StatusCodes.Status400BadRequest,
                title: "Image rejected");

        var previousImage = car.ImageUrl;

        var updated = await repo.SetImageUrlAsync(id, outcome.RelativeUrl);
        if (updated is null)
        {
            // The car disappeared between the two calls — don't leave the file orphaned.
            images.TryDelete(outcome.RelativeUrl);
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");
        }

        // Only remove the old file once the new URL is safely persisted.
        if (!string.Equals(previousImage, outcome.RelativeUrl, StringComparison.OrdinalIgnoreCase))
            images.TryDelete(previousImage);

        return Ok(updated.ToDto());
    }

    /// <summary>Removes a car's photo and deletes the stored file.</summary>
    [HttpDelete("{id:int}/image")]
    [Authorize]
    [ProducesResponseType(typeof(CarDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CarDto>> DeleteImage(int id)
    {
        var car = await repo.GetByIdAsync(id);
        if (car is null)
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        if (car.ImageUrl is null)
            return Ok(car.ToDto());   // already has no photo — nothing to do

        var updated = await repo.SetImageUrlAsync(id, null);
        images.TryDelete(car.ImageUrl);

        return Ok((updated ?? car).ToDto());
    }

    [HttpDelete("{id:int}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete(int id)
    {
        var car = await repo.GetByIdAsync(id);
        if (car is null)
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

        // Don't leave the photo behind as an orphaned file on disk.
        images.TryDelete(car.ImageUrl);

        return NoContent();
    }
}
