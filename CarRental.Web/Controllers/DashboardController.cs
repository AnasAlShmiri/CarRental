using System.Text.Json;
using CarRental.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.Web.Controllers;

[Authorize(Roles = "Admin")]
public class DashboardController(IStatisticsRepository statistics) : Controller
{
    // GET: /
    public async Task<IActionResult> Index([FromQuery] int months = 6)
    {
        // Clamp the same way the API does (1–24) so the chart never grows unbounded.
        months = Math.Clamp(months, 1, 24);

        var stats = await statistics.GetAsync(monthsOfRevenue: months);

        // Chart.js consumes the revenue series as JSON — serialised once server-side
        // so the view never hand-builds arrays from Razor loops.
        ViewData["MonthsLabel"] = JsonSerializer.Serialize(
            stats.MonthlyRevenue.Select(m => $"{m.Month}/{m.Year}"));
        ViewData["RevenueSeries"] = JsonSerializer.Serialize(
            stats.MonthlyRevenue.Select(m => (double)m.Revenue));

        return View(stats);
    }

}
