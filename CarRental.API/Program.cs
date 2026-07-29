using System.Text;
using CarRental.API.Errors;
using CarRental.Application.Interfaces;
using CarRental.Infrastructure.Auth;
using CarRental.Infrastructure.Data;
using CarRental.Infrastructure.Repositories;
using CarRental.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

// ── Database ──────────────────────────────────────────────────────────────────
// The provider is configurable so the same code can run against SQL Server (default,
// what you use on Windows) or SQLite/InMemory for testing on machines without SQL Server.
// Set it via "DatabaseProvider" in appsettings.json or the DatabaseProvider env var.
var provider = builder.Configuration["DatabaseProvider"] ?? "SqlServer";
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var isSqlServer = provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase);

builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    switch (provider.ToLowerInvariant())
    {
        case "sqlite":
            options.UseSqlite(connectionString ?? "Data Source=carrental.db");
            break;

        case "inmemory":
            options.UseInMemoryDatabase("CarRentalTestDb");
            break;

        default:
            options.UseSqlServer(connectionString, sql => sql.EnableRetryOnFailure());
            break;
    }
});

// ── Repositories (Dependency Injection) ───────────────────────────────────────
builder.Services.AddScoped<ICarRepository, CarRepository>();
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<IRentalRepository, RentalRepository>();

// ── Authentication / Authorization ────────────────────────────────────────────
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection(JwtSettings.SectionName));
builder.Services.Configure<AdminUserSettings>(builder.Configuration.GetSection(AdminUserSettings.SectionName));
builder.Services.AddScoped<ITokenService, TokenService>();

var jwt = builder.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>() ?? new JwtSettings();

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt.Issuer,
            ValidateAudience = true,
            ValidAudience = jwt.Audience,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(string.IsNullOrWhiteSpace(jwt.Key)
                    // Placeholder so the app still starts if the key is missing; any real
                    // token will fail validation and AuthController reports the misconfiguration.
                    ? "unconfigured-development-key-please-set-Jwt-Key-32b"
                    : jwt.Key))
        };
    });

builder.Services.AddAuthorization();

// ── CORS ──────────────────────────────────────────────────────────────────────
// Without this the Flutter app and the MVC dashboard are blocked by the browser.
const string CorsPolicy = "CarRentalClients";
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];

builder.Services.AddCors(options =>
    options.AddPolicy(CorsPolicy, policy =>
    {
        if (allowedOrigins.Length > 0)
            policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
        else
            // No origins configured (e.g. local development / mobile clients, which are
            // not browser-origin bound anyway).
            policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    }));

// ── Error handling ────────────────────────────────────────────────────────────
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

// ── Controllers + JSON options ────────────────────────────────────────────────
builder.Services.AddControllers()
    .AddJsonOptions(options =>
        options.JsonSerializerOptions.ReferenceHandler =
            System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles);

// ── Swagger / OpenAPI (with a Bearer-token box) ───────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "CarRental API",
        Version = "v1",
        Description = """
            Car rental management API — Clean Architecture + Repository Pattern.

            ### Getting a token (needed for admin operations)

            1. Run **POST /api/Auth/login** with `{ "username": "admin", "password": "..." }`
               (the password is the `AdminUser:Password` value from configuration).
            2. Copy the `token` value from the response.
            3. Click the green **Authorize** button at the top of this page and paste the token.
               Paste the token **only** — do not type `Bearer` in front of it, Swagger adds it.

            ### What needs a token

            | Endpoints | Token |
            |---|---|
            | `GET /api/Cars`, `/api/Cars/available`, `/api/Cars/{id}` | Not required — public catalogue |
            | `POST /api/Rentals` | Not required — a customer books their own rental |
            | All other Cars / Rentals operations | Required |
            | Everything under `/api/Customers` | Required — personal data |

            ### Notes

            * `totalPrice` is always calculated by the server; never send it.
            * On **PUT /api/Cars/{id}**, leave `status` out to keep the car's current status.
            * Every error response is a ProblemDetails object whose `detail` explains the cause.
            """
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Paste the token from POST /api/auth/login (no \"Bearer \" prefix needed)."
    });

    // Swashbuckle 10 takes a factory, and Microsoft.OpenApi v2 keys security
    // requirements by scheme *reference* rather than by an inline scheme object.
    options.AddSecurityRequirement(_ => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer")] = new List<string>()
    });
});

builder.Services.AddHealthChecks();

// ── Build ─────────────────────────────────────────────────────────────────────
var app = builder.Build();

// Apply migrations at startup, but never let a database problem kill the process.
// The original code called Migrate() unguarded, so an unreachable SQL Server took the
// whole API down with an unhandled exception instead of surfacing a clear error.
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

    try
    {
        // The migrations in CarRental.Infrastructure/Migrations are generated for SQL Server.
        // Replaying them on another provider raises a false PendingModelChangesWarning
        // (provider type mappings differ), so the alternative providers just get the schema
        // created directly. Migrations remain the source of truth for SQL Server.
        if (isSqlServer)
            db.Database.Migrate();
        else
            db.Database.EnsureCreated();

        logger.LogInformation("Database is ready ({Provider}).", db.Database.ProviderName);
    }
    catch (Exception ex)
    {
        logger.LogError(ex,
            "Could not prepare the database. The API will still start, but data endpoints " +
            "will fail until the database is reachable. Provider: {Provider}", provider);
    }
}

app.UseExceptionHandler();

// Gives a self-explanatory JSON body to error responses the framework returns empty
// (401, 403, unmatched-route 404, 405, ...). Without this an unauthenticated call just
// gets a bare 401 with Content-Length: 0, which reads like a silent failure.
app.UseProblemDetailsForEmptyResponses();

// Only force HTTPS when an HTTPS endpoint actually exists. Redirecting unconditionally
// makes plain-HTTP calls (curl, Postman, the http launch profile) return 307s that hide
// the real response.
if (!app.Environment.IsDevelopment())
    app.UseHttpsRedirection();

// Serves car images from wwwroot/uploads.
app.UseStaticFiles();

app.UseCors(CorsPolicy);

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "CarRental API v1");
    c.DocumentTitle = "CarRental API";
});

// Authentication must run before authorization — the original had UseAuthorization()
// with no authentication registered at all.
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
