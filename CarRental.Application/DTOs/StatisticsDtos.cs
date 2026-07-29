namespace CarRental.Application.DTOs;

/// <summary>
/// Headline numbers for the admin dashboard ("لوحة إحصائيات رئيسية مع رسوم بيانية").
/// One call feeds the KPI cards and the charts.
/// </summary>
public record StatisticsDto(
    CarStatsDto Cars,
    CustomerStatsDto Customers,
    RentalStatsDto Rentals,
    RevenueStatsDto Revenue,
    IReadOnlyList<MonthlyRevenueDto> MonthlyRevenue);

public record CarStatsDto(int Total, int Available, int Rented, int UnderMaintenance);

public record CustomerStatsDto(int Total);

public record RentalStatsDto(int Total, int Active, int Completed, int Cancelled);

/// <param name="Total">Realised revenue: the sum of completed rentals.</param>
/// <param name="ActiveValue">Money currently on the road: the sum of active rentals.</param>
public record RevenueStatsDto(decimal Total, decimal ActiveValue);

/// <summary>One bar of the revenue chart — completed rentals grouped by month.</summary>
public record MonthlyRevenueDto(int Year, int Month, decimal Revenue);
