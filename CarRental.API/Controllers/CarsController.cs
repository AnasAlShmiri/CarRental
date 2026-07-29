using CarRental.API.Contracts;
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

    /// <summary>
    /// Creates a car. Pick the photo in the SAME form — the "image" field shows a
    /// Choose-file button in Swagger. The server stores the file under wwwroot/uploads
    /// and fills in imageUrl automatically.
    /// </summary>
    /// <remarks>
    /// The image is optional. Accepted types: jpg, jpeg, png, gif, webp — up to 5 MB.
    /// The real format is verified from the file's bytes, so renaming a document to
    /// ".jpg" is rejected — and in that case the car is NOT created.
    /// </remarks>
    [HttpPost]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(CarDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CarDto>> Create([FromForm] CarCreateForm form, CancellationToken ct)
    {
        // Validate and store the photo BEFORE creating the car, so a bad file
        // means no half-created row.
        string? imageUrl = null;
        if (form.Image is { Length: > 0 })
        {
            await using var stream = form.Image.OpenReadStream();
            var outcome = await images.SaveAsync(stream, form.Image.FileName, form.Image.Length, ct);

            if (!outcome.Success)
                return Problem(
                    detail: outcome.Error,
                    statusCode: StatusCodes.Status400BadRequest,
                    title: "Image rejected");

            imageUrl = outcome.RelativeUrl;
        }

        try
        {
            var created = await repo.CreateAsync(new Car
            {
                Model = form.Model,
                Brand = form.Brand,
                PricePerDay = form.PricePerDay,
                ImageUrl = imageUrl
            });

            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created.ToDto());
        }
        catch
        {
            // The row was not saved — don't leave its photo behind on disk.
            images.TryDelete(imageUrl);
            throw;
        }
    }

    /// <summary>
    /// Updates a car in one form. Leave "image" empty to keep the current photo, pick a
    /// file to replace it, or set "removeImage" to true to delete it. Leave "status"
    /// out to keep the current status.
    /// </summary>
    [HttpPut("{id:int}")]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(CarDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CarDto>> Update(int id, [FromForm] CarUpdateForm form, CancellationToken ct)
    {
        if (form.Status is not null && !CarStatus.IsValid(form.Status))
            return Problem(
                detail: $"Unknown status '{form.Status}'. Allowed values: {string.Join(", ", CarStatus.All)}.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid status");

        // 404 before touching the disk — a photo must never be stored for a car
        // that does not exist.
        var existing = await repo.GetByIdAsync(id);
        if (existing is null)
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        // null = keep the current photo; "" = clear it; a path = the new photo.
        string? imageUrlChange = null;

        if (form.Image is { Length: > 0 })
        {
            await using var stream = form.Image.OpenReadStream();
            var outcome = await images.SaveAsync(stream, form.Image.FileName, form.Image.Length, ct);

            if (!outcome.Success)
                return Problem(
                    detail: outcome.Error,
                    statusCode: StatusCodes.Status400BadRequest,
                    title: "Image rejected");

            imageUrlChange = outcome.RelativeUrl;
        }
        else if (form.RemoveImage)
        {
            imageUrlChange = string.Empty;
        }

        var updated = await repo.UpdateAsync(
            id, form.Model, form.Brand, form.PricePerDay, imageUrlChange, form.Status);

        if (updated is null)
        {
            // The car vanished between the existence check and the update.
            images.TryDelete(imageUrlChange);
            return Problem(
                detail: $"Car {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");
        }

        // The photo changed or was removed — delete the file that is no longer referenced.
        if (imageUrlChange is not null &&
            existing.ImageUrl is not null &&
            !string.Equals(existing.ImageUrl, updated.ImageUrl, StringComparison.OrdinalIgnoreCase))
            images.TryDelete(existing.ImageUrl);

        return Ok(updated.ToDto());
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
