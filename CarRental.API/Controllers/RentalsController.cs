using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RentalsController(IRentalRepository rentalRepo, ICarRepository carRepo) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Rental>>> GetAll() =>
        Ok(await rentalRepo.GetAllAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Rental>> GetById(int id)
    {
        var rental = await rentalRepo.GetByIdAsync(id);
        return rental is null ? NotFound() : Ok(rental);
    }

    [HttpPost]
    public async Task<ActionResult<Rental>> Create(RentalCreateDto dto)
    {
        var car = await carRepo.GetByIdAsync(dto.CarId);
        if (car is null) return BadRequest("Car not found.");
        if (car.Status != "Available") return BadRequest("Car is not available.");

        var days = (dto.EndDate - dto.StartDate).Days;
        if (days <= 0) return BadRequest("EndDate must be after StartDate.");

        var rental = new Rental
        {
            CarId = dto.CarId,
            CustomerId = dto.CustomerId,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            TotalPrice = car.PricePerDay * days,
            Status = "Active"
        };

        car.Status = "Rented";
        await carRepo.UpdateAsync(car);

        var created = await rentalRepo.CreateAsync(rental);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<Rental>> Update(int id, RentalCreateDto dto)
    {
        var rental = new Rental
        {
            Id = id,
            CarId = dto.CarId,
            CustomerId = dto.CustomerId,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate
        };
        var updated = await rentalRepo.UpdateAsync(rental);
        return updated is null ? NotFound() : Ok(updated);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id) =>
        await rentalRepo.DeleteAsync(id) ? NoContent() : NotFound();
}