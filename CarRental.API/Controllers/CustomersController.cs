using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Application.Mapping;
using CarRental.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Controllers;

/// <summary>
/// Customer records hold personal data, so the whole controller requires a token.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize(Roles = "Admin")]
public class CustomersController(ICustomerRepository repo) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<CustomerDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<CustomerDto>>> GetAll() =>
        Ok((await repo.GetAllAsync()).ToDtos());

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerDto>> GetById(int id)
    {
        var customer = await repo.GetByIdAsync(id);
        if (customer is null)
            return Problem(
                detail: $"Customer {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        return Ok(customer.ToDto());
    }

    [HttpPost]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CustomerDto>> Create(CustomerCreateDto dto)
    {
        // Email carries a unique index. Checking first turns a raw DbUpdateException
        // (previously an unhandled HTTP 500) into a clear 409.
        if (await repo.EmailExistsAsync(dto.Email))
            return Problem(
                detail: $"A customer with the email '{dto.Email}' already exists.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Duplicate email");

        var created = await repo.CreateAsync(new Customer
        {
            Name = dto.Name,
            Email = dto.Email,
            Phone = dto.Phone
        });

        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created.ToDto());
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CustomerDto>> Update(int id, CustomerCreateDto dto)
    {
        if (!await repo.ExistsAsync(id))
            return Problem(
                detail: $"Customer {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        // Exclude self so re-saving a customer without changing the email still works.
        if (await repo.EmailExistsAsync(dto.Email, excludeCustomerId: id))
            return Problem(
                detail: $"Another customer already uses the email '{dto.Email}'.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Duplicate email");

        var updated = await repo.UpdateAsync(id, dto.Name, dto.Email, dto.Phone);
        if (updated is null)
            return Problem(
                detail: $"Customer {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        return Ok(updated.ToDto());
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete(int id)
    {
        if (!await repo.ExistsAsync(id))
            return Problem(
                detail: $"Customer {id} was not found.",
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found");

        // BUGFIX: this controller had no relationship check at all, unlike CarsController.
        // Deleting a customer with rentals hit the Restrict FK and returned a bare 500.
        if (await repo.HasActiveRentalsAsync(id))
            return Problem(
                detail: "Cannot delete a customer with an active rental. Complete or cancel it first.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Customer has an active rental");

        if (await repo.HasAnyRentalsAsync(id))
            return Problem(
                detail: "Cannot delete a customer who has rental history, because those records must be preserved.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Customer has rental history");

        await repo.DeleteAsync(id);
        return NoContent();
    }
}
