using Microsoft.AspNetCore.Diagnostics;
using CarRental.Domain.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CarRental.API.Errors;

/// <summary>
/// Turns unhandled exceptions into RFC 7807 ProblemDetails responses.
/// <para>
/// Before this existed, any database failure (duplicate email, foreign-key restriction,
/// SQL Server unreachable) surfaced as a bare HTTP 500 with a stack trace in the console
/// and nothing useful in the response body.
/// </para>
/// </summary>
public class GlobalExceptionHandler(
    ILogger<GlobalExceptionHandler> logger,
    IHostEnvironment env) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext context, Exception exception, CancellationToken cancellationToken)
    {
        var (status, title, detail) = Classify(exception);

        logger.LogError(exception,
            "Unhandled exception on {Method} {Path} -> {Status}",
            context.Request.Method, context.Request.Path, status);

        var problem = new ProblemDetails
        {
            Status = status,
            Title = title,
            Detail = detail,
            Instance = $"{context.Request.Method} {context.Request.Path}"
        };

        // Only leak exception internals outside production.
        if (!env.IsProduction())
            problem.Extensions["exception"] = exception.GetType().Name;

        context.Response.StatusCode = status;
        await context.Response.WriteAsJsonAsync(problem, cancellationToken);
        return true;
    }

    private static (int Status, string Title, string Detail) Classify(Exception ex) => ex switch
    {
        // Unique index / foreign-key violations arrive wrapped in DbUpdateException.
        DbUpdateConcurrencyException =>
            (StatusCodes.Status409Conflict,
             "Concurrency conflict",
             "The record was modified by someone else. Reload it and try again."),

        DomainConflictException conflict =>
            (StatusCodes.Status409Conflict, "Resource conflict", conflict.Message),

        DbUpdateException dbEx =>
            (StatusCodes.Status409Conflict,
             "Database constraint violation",
             DescribeDbUpdate(dbEx)),

        InvalidOperationException ioEx =>
            (StatusCodes.Status400BadRequest, "Invalid operation", ioEx.Message),

        // The configured database provider is unavailable, or the platform doesn't support it.
        PlatformNotSupportedException pEx =>
            (StatusCodes.Status503ServiceUnavailable,
             "Database unavailable",
             pEx.Message),

        TaskCanceledException or OperationCanceledException =>
            (StatusCodesExtra.Status499ClientClosedRequest, "Request cancelled", "The request was cancelled."),

        _ => (StatusCodes.Status500InternalServerError,
              "Unexpected error",
              "An unexpected error occurred while processing the request.")
    };

    private static string DescribeDbUpdate(DbUpdateException ex)
    {
        var message = ex.InnerException?.Message ?? ex.Message;

        if (message.Contains("UNIQUE", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("duplicate key", StringComparison.OrdinalIgnoreCase))
            return "A record with the same unique value already exists (e.g. a customer email).";

        if (message.Contains("FOREIGN KEY", StringComparison.OrdinalIgnoreCase) ||
            message.Contains("REFERENCE constraint", StringComparison.OrdinalIgnoreCase))
            return "The operation violates a relationship constraint — a referenced record is missing, or this record is still referenced by others.";

        return "The write was rejected by a database constraint.";
    }
}

/// <summary>ASP.NET Core has no named constant for 499.</summary>
internal static class StatusCodesExtra
{
    public const int Status499ClientClosedRequest = 499;
}
