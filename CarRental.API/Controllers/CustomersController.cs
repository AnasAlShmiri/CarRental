using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CustomersController(ICustomerRepository repo) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Customer>>> GetAll() =>
        Ok(await repo.GetAllAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Customer>> GetById(int id)
    {
        var customer = await repo.GetByIdAsync(id);
        return customer is null ? NotFound() : Ok(customer);
    }

    [HttpPost]
    public async Task<ActionResult<Customer>> Create(CustomerCreateDto dto)
    {
        var customer = new Customer
        {
            Name = dto.Name,
            Email = dto.Email,
            Phone = dto.Phone
        };
        var created = await repo.CreateAsync(customer);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<Customer>> Update(int id, CustomerCreateDto dto)
    {
        var customer = new Customer
        {
            Id = id,
            Name = dto.Name,
            Email = dto.Email,
            Phone = dto.Phone
        };
        var updated = await repo.UpdateAsync(customer);
        return updated is null ? NotFound() : Ok(updated);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id) =>
        await repo.DeleteAsync(id) ? NoContent() : NotFound();
}