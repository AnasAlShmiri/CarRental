using System.Security.Claims;
using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using CarRental.Application.Mapping;
using CarRental.Domain.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Controllers;

/// <summary>
/// Customer-only authentication for the Flutter application.
/// Admin authentication remains under /api/auth.
/// </summary>
[ApiController]
[Route("api/customer-auth")]
[Produces("application/json")]
public class CustomerAuthController(
    ICustomerRepository customers,
    IPasswordHasher<Customer> passwordHasher,
    ITokenService tokenService,
    ILogger<CustomerAuthController> logger) : ControllerBase
{
    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CustomerAuthResponseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CustomerAuthResponseDto>> Register(CustomerRegisterDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        if (await customers.EmailExistsAsync(email))
            return Problem(
                detail: "An account with this email already exists.",
                statusCode: StatusCodes.Status409Conflict,
                title: "Email already registered");

        var customer = new Customer
        {
            Name = dto.Name.Trim(),
            Email = email,
            Phone = dto.Phone.Trim()
        };
        customer.PasswordHash = passwordHasher.HashPassword(customer, dto.Password);

        var created = await customers.CreateAsync(customer);
        logger.LogInformation("Customer account created for {Email} with id {CustomerId}.", created.Email, created.Id);

        var response = CreateResponse(created);
        return Created("/api/customer-auth/me", response);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CustomerAuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CustomerAuthResponseDto>> Login(CustomerLoginDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        var customer = await customers.GetByEmailAsync(email);
        var passwordResult = customer?.PasswordHash is null
            ? PasswordVerificationResult.Failed
            : passwordHasher.VerifyHashedPassword(customer, customer.PasswordHash, dto.Password);

        if (customer is null || passwordResult == PasswordVerificationResult.Failed)
        {
            logger.LogWarning("Failed customer login attempt for {Email}.", email);
            return Problem(
                detail: "Invalid email or password.",
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Authentication failed");
        }

        return Ok(CreateResponse(customer));
    }

    [HttpGet("me")]
    [Authorize(Roles = "Customer")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerDto>> Me()
    {
        var customerId = GetCustomerId();
        if (customerId is null)
            return Unauthorized();

        var customer = await customers.GetByIdAsync(customerId.Value);
        return customer is null
            ? NotFound()
            : Ok(customer.ToDto());
    }

    [HttpPut("me")]
    [Authorize(Roles = "Customer")]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerDto>> UpdateMe(CustomerProfileUpdateDto dto)
    {
        var customerId = GetCustomerId();
        if (customerId is null)
            return Unauthorized();

        var current = await customers.GetByIdAsync(customerId.Value);
        if (current is null)
            return NotFound();

        var updated = await customers.UpdateAsync(
            customerId.Value,
            dto.Name.Trim(),
            current.Email,
            dto.Phone.Trim());

        return updated is null ? NotFound() : Ok(updated.ToDto());
    }

    private CustomerAuthResponseDto CreateResponse(Customer customer)
    {
        var auth = tokenService.CreateToken(customer.Email, "Customer", customer.Id);
        return new CustomerAuthResponseDto(
            auth.Token,
            auth.ExpiresAtUtc,
            customer.Email,
            "Customer",
            customer.Id,
            customer.Name,
            customer.Email,
            customer.Phone);
    }

    private int? GetCustomerId()
    {
        var raw = User.FindFirstValue("customer_id");
        return int.TryParse(raw, out var customerId) ? customerId : null;
    }
}
