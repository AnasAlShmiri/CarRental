using System.Globalization;
using System.Text;
using CarRental.API.Binding;
using CarRental.API.Errors;
using CarRental.Application.Interfaces;
using CarRental.Infrastructure.Auth;
using CarRental.Infrastructure.Data;
using CarRental.Infrastructure.Repositories;
using CarRental.Infrastructure.Services;
using CarRental.Infrastructure.Storage;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;

// Form values (multipart/form-data) parse numbers using the server's culture.
// Forcing invariant keeps "150.50" meaning the same price on any Windows locale
// (an Arabic locale could otherwise read the decimal separator differently).
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

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
builder.Services.AddScoped<IStatisticsRepository, StatisticsRepository>();

// ── Car image storage ─────────────────────────────────────────────────────────
// Files land in wwwroot/uploads and are served by UseStaticFiles() further down.
builder.Services.Configure<ImageStorageOptions>(
    builder.Configuration.GetSection(ImageStorageOptions.SectionName));
builder.Services.PostConfigure<ImageStorageOptions>(o =>
{
    // Only the host knows its web root, so it is supplied here rather than in config.
    if (string.IsNullOrWhiteSpace(o.PhysicalRootPath))
        o.PhysicalRootPath = builder.Environment.WebRootPath
                             ?? Path.Combine(builder.Environment.ContentRootPath, "wwwroot");
});
builder.Services.AddScoped<ICarImageStorage, LocalCarImageStorage>();

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
builder.Services.AddControllers(options =>
        // BUGFIX: the default binder read a form value of "10,5" as 105 — in the
        // invariant culture the comma is a THOUSANDS separator — silently storing a
        // 10x price. This binder accepts only "150" / "150.50" and rejects group
        // separators with a clear message. JSON bodies are unaffected.
        options.ModelBinderProviders.Insert(0, new InvariantDecimalModelBinderProvider()))
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
        // Swagger UI's markdown renderer does not support tables, so this description
        // deliberately uses only headings, bold text and bullet lists — anything else
        // collapses into one unreadable run of text.
        Description = """
            Car rental management API — Clean Architecture + Repository Pattern.

            ### 1. Get a token (needed for admin operations)

            **Step 1** — Run `POST /api/Auth/login` below with this body:

            `{ "username": "admin", "password": "Admin@12345" }`

            That is the development default, stored in `appsettings.json` under
            `AdminUser`. Change it before deploying.

            **Step 2** — Copy the `token` value from the response — the long string
            only, without the surrounding quotes.

            **Step 3** — Click the green **Authorize** button at the top-right of this
            page, paste the token, then press Authorize and Close.

            Paste the token **on its own**. Do not type `Bearer` in front of it —
            Swagger adds that automatically, and typing it yourself breaks the header.

            ### 2. Endpoints that need NO token

            * `GET /api/Cars` — the full catalogue
            * `GET /api/Cars/available` — only cars that are free to rent
            * `GET /api/Cars/{id}` — a single car
            * `POST /api/Rentals` — a customer booking their own rental
            * `GET /api/Rentals/customer/{customerId}` — a customer's own rental history
            * `GET /health` — service health probe

            ### 3. Endpoints that DO need a token

            * Creating, updating or deleting a car
            * Completing, cancelling, updating or deleting a rental
            * Listing or reading rentals
            * Everything under `/api/Customers` — these records hold personal data
            * `GET /api/Statistics` — dashboard numbers (fleet, rentals, revenue chart)

            ### 4. Things worth knowing

            * The Cars endpoints take form fields (multipart/form-data), not JSON — that
              is what lets the photo ride along in the same request. Customers and
              Rentals take JSON as usual.
            * `totalPrice` is always calculated by the server. Never send it.
            * On `PUT /api/Cars/{id}`, leave `status` empty to keep the car's current
              status. Sending it is the only way to change it.
            ### 5. Car photos — picked in the SAME form

            `POST /api/Cars` and `PUT /api/Cars/{id}` take form fields, and the
            **image** field shows a Choose-file button right in Swagger. One request:
            fill in the car's details, pick the photo from your computer, press
            Execute. The server stores the file under `wwwroot/uploads/` and fills in
            `imageUrl` automatically.

            * Accepted: jpg, jpeg, png, gif, webp — up to 5 MB.
            * The real format is verified from the file's bytes, so renaming a
              document to `.jpg` is rejected — and the car is NOT created.
            * On PUT: leave **image** empty to keep the current photo, pick a file to
              replace it (the old file is deleted), or set **removeImage** to true to
              delete it.
            * Every error response is a ProblemDetails object whose `detail` field
              explains what went wrong and how to fix it.
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

// Serves car images from wwwroot/uploads. Create the folder if it is missing —
// git does not track empty directories, so a fresh clone may not have it, and
// UseStaticFiles logs a warning when the web root does not exist.
var webRoot = app.Environment.WebRootPath
              ?? Path.Combine(app.Environment.ContentRootPath, "wwwroot");
Directory.CreateDirectory(Path.Combine(webRoot, "uploads"));

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
