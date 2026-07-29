using CarRental.Application.DTOs;

namespace CarRental.Application.Interfaces;

/// <summary>Issues JWTs for authenticated admin users.</summary>
public interface ITokenService
{
    AuthResponseDto CreateToken(string username, string role);
}
