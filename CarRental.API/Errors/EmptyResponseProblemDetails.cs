using System.Text.Json;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.API.Errors;

/// <summary>
/// Fills in a body for error responses that the framework returns empty.
/// <para>
/// ASP.NET Core answers an unauthenticated request with a bare <c>401</c> — status line and
/// a <c>WWW-Authenticate</c> header, but <c>Content-Length: 0</c>. The same applies to
/// <c>403</c>, to a <c>404</c> for a URL that matches no route, and to <c>405</c> for a
/// wrong HTTP verb. From the caller's side those look like the server failed silently,
/// which is exactly the confusion this middleware removes: every error now explains
/// itself and says what to do next.
/// </para>
/// </summary>
public static class EmptyResponseProblemDetails
{
    /// <summary>
    /// Registers the handler. Call it early in the pipeline — before authentication —
    /// so it can observe the final status code on the way back out.
    /// </summary>
    public static IApplicationBuilder UseProblemDetailsForEmptyResponses(this IApplicationBuilder app) =>
        app.UseStatusCodePages(async context =>
        {
            var http = context.HttpContext;
            var status = http.Response.StatusCode;

            var (title, detail) = Describe(status, http.Request.Method, http.Request.Path);

            var problem = new ProblemDetails
            {
                Status = status,
                Title = title,
                Detail = detail,
                Instance = $"{http.Request.Method} {http.Request.Path}"
            };

            http.Response.ContentType = "application/problem+json";
            await http.Response.WriteAsync(JsonSerializer.Serialize(problem,
                new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }));
        });

    private static (string Title, string Detail) Describe(int status, string method, string path) => status switch
    {
        StatusCodes.Status401Unauthorized => (
            "Authentication required",
            "A valid bearer token is required for this endpoint."),

        StatusCodes.Status403Forbidden => (
            "Access denied",
            "Your token is valid but your account is not allowed to perform this action."),

        StatusCodes.Status404NotFound => (
            "Endpoint not found",
            $"No endpoint matches {method} {path}. Check the URL spelling and the HTTP verb — "
          + "the full list of available endpoints is at /swagger."),

        StatusCodes.Status405MethodNotAllowed => (
            "Method not allowed",
            $"{path} exists but does not accept {method}. See /swagger for the verbs it supports."),

        StatusCodes.Status406NotAcceptable => (
            "Response format not supported",
            "This API only returns application/json. Adjust your Accept header."),

        StatusCodes.Status415UnsupportedMediaType => (
            "Unsupported request format",
            "The Content-Type header does not match what this endpoint accepts. Most endpoints "
          + "take application/json; the image-upload endpoints take multipart/form-data. "
          + "Check the endpoint in /swagger for the exact media type."),

        StatusCodes.Status429TooManyRequests => (
            "Too many requests",
            "Slow down and retry shortly."),

        StatusCodes.Status503ServiceUnavailable => (
            "Service unavailable",
            "The API cannot access its configured database right now. Check the connection settings and retry."),

        _ => (
            "Request failed",
            $"The request could not be completed (HTTP {status}).")
    };
}
