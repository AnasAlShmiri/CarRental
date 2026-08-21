using System.Globalization;
using System.Text.Json.Serialization;
using CarRental.Application.Interfaces;
using CarRental.Infrastructure.Auth;
using CarRental.Infrastructure.Data;
using CarRental.Infrastructure.Repositories;
using CarRental.Infrastructure.Services;
using CarRental.Infrastructure.Storage;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.HttpOverrides;

// ── Culture: parse prices in the invariant form (150.50) so the database never
//    stores 10× prices, while the UI renders in Arabic.
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = new CultureInfo("ar");

var builder = WebApplication.CreateBuilder(args);

// ── Database (same provider switch as CarRental.API — one database, two hosts) ──
var provider = builder.Configuration["DatabaseProvider"] ?? "SqlServer";
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var isSqlServer = provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase);

builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    switch (provider.ToLowerInvariant())
    {
        case "sqlite":
            options.UseSqlite(connectionString ?? "Data Source=../car-rental.db");
            break;

        case "inmemory":
            options.UseInMemoryDatabase("CarRentalTestDb");
            break;

        default:
            options.UseSqlServer(connectionString, sql => sql.EnableRetryOnFailure());
            break;
    }
});

// ── Repositories + services (identical registrations to CarRental.API) ──────────
builder.Services.AddScoped<ICarRepository, CarRepository>();
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<IRentalRepository, RentalRepository>();
builder.Services.AddScoped<IStatisticsRepository, StatisticsRepository>();

builder.Services.Configure<ImageStorageOptions>(
    builder.Configuration.GetSection(ImageStorageOptions.SectionName));
builder.Services.PostConfigure<ImageStorageOptions>(o =>
{
    // MVC owns the shared web root used by both MVC and API for car photos.
    o.PhysicalRootPath = Path.GetFullPath(Path.Combine(
        builder.Environment.ContentRootPath, "wwwroot"));
});
builder.Services.AddScoped<ICarImageStorage, LocalCarImageStorage>();

builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection(JwtSettings.SectionName));
builder.Services.Configure<AdminUserSettings>(builder.Configuration.GetSection(AdminUserSettings.SectionName));
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<CarRental.Web.Services.AdminLoginService>();

// ── Authentication: admin signs in with the same JWT credentials, but the web
//    app keeps the session in a cookie for a proper server-rendered experience.
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    })
    .AddCookie(options =>
    {
        options.LoginPath = "/auth/login";
        options.LogoutPath = "/auth/logout";
        options.AccessDeniedPath = "/auth/denied";
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.SlidingExpiration = true;
        options.Cookie.Name = "CarRental.Web.Auth";
    });

builder.Services.AddAuthorization();
builder.Services.AddControllersWithViews();
builder.Services.AddRazorPages();

// ── Session: preserve last-used filters between page visits ────────────────────
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.Name = "CarRental.Web.Session";
});

builder.Services.Configure<ForwardedHeadersOptions>(options =>
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor
                               | ForwardedHeaders.XForwardedProto);

builder.Services.AddHealthChecks();

// ── Build ───────────────────────────────────────────────────────────────────────
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

    try
    {
        if (isSqlServer)
            db.Database.Migrate();
        else
        {
            db.Database.EnsureCreated();
            await SqliteSchemaCompatibility.EnsureAsync(db);
        }

        logger.LogInformation("Database is ready ({Provider}).", db.Database.ProviderName);
    }
    catch (Exception ex)
    {
        logger.LogError(ex,
            "Could not prepare the database. The web app will still start, but pages will " +
            "fail until the database is reachable. Provider: {Provider}", provider);
    }
}

app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async ctx =>
    {
        var ex = ctx.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>()?.Error;
        ctx.Response.Redirect($"/Home/Error?msg={Uri.EscapeDataString(ex?.GetType().Name ?? "error")}");
    });
});

app.UseHttpsRedirection();

// Car photos are served from the SAME wwwroot/uploads folder both hosts share.
Directory.CreateDirectory(Path.Combine(
    app.Environment.WebRootPath ?? Path.Combine(app.Environment.ContentRootPath, "wwwroot"),
    "uploads"));
app.UseStaticFiles();

app.UseSession();
app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Dashboard}/{action=Index}/{id?}");

app.MapHealthChecks("/health");

app.Run();

