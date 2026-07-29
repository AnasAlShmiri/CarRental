using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CarsController(ICarRepository repo) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Car>>> GetAll() =>
        Ok(await repo.GetAllAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Car>> GetById(int id)
    {
        var car = await repo.GetByIdAsync(id);
        return car is null ? NotFound() : Ok(car);
    }

    [HttpPost]
    public async Task<ActionResult<Car>> Create(CarCreateDto dto)
    {
        var car = new Car
        {
            Model = dto.Model,
            Brand = dto.Brand,
            PricePerDay = dto.PricePerDay
        };
        var created = await repo.CreateAsync(car);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<Car>> Update(int id, CarCreateDto dto)
    {
        var car = new Car
        {
            Id = id,
            Model = dto.Model,
            Brand = dto.Brand,
            PricePerDay = dto.PricePerDay
        };
        var updated = await repo.UpdateAsync(car);
        return updated is null ? NotFound() : Ok(updated);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        if (await repo.HasRentalsAsync(id))
            return Conflict("Cannot delete car with active rentals.");

        return await repo.DeleteAsync(id) ? NoContent() : NotFound();
    }
}