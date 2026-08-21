using CarRental.Application.DTOs;
using CarRental.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Controllers;

/// <summary>
/// Dashboard numbers for the admin panel: fleet breakdown, customer count,
/// rental pipeline and revenue — including the per-month series the charts need.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize(Roles = "Admin")]
public class StatisticsController(IStatisticsRepository stats) : ControllerBase
{
    /// <summary>All dashboard statistics in one call.</summary>
    /// <param name="months">How many recent months the revenue chart covers (1–24, default 6).</param>
    [HttpGet]
    [ProducesResponseType(typeof(StatisticsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StatisticsDto>> Get([FromQuery] int months = 6)
    {
        if (months is < 1 or > 24)
            return Problem(
                detail: "months must be between 1 and 24.",
                statusCode: StatusCodes.Status400BadRequest,
                title: "Invalid range");

        return Ok(await stats.GetAsync(months));
    }
}
