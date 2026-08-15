using System.Security.Claims;
using CarRental.Web.Models;
using CarRental.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc.Routing;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.Web.Controllers;

/// <summary>
/// Sign-in for the admin panel.
/// <para>
/// Credentials are validated exactly like the API host (shared AdminUser settings), and
/// the claims are signed into a cookie — no JWT round-trip needed for server rendering.
/// </para>
/// </summary>
public class AuthController(AdminLoginService login) : Controller
{
    // GET: /auth/login
    [HttpGet]
    [AllowAnonymous]
    public IActionResult Login(string? returnUrl)
    {
        if (User.Identity?.IsAuthenticated == true)
            return RedirectToAction("Index", "Dashboard");

        ViewData["ReturnUrl"] = returnUrl;
        return View(new LoginViewModel());
    }

    [HttpPost]
    [AllowAnonymous]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model, string? returnUrl)
    {
        ViewData["ReturnUrl"] = returnUrl;

        if (!ModelState.IsValid)
            return View(model);

        if (!login.Validate(model.Username, model.Password))
        {
            ModelState.AddModelError(string.Empty, "اسم المستخدم أو كلمة المرور غير صحيحة");
            return View(model);
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.Name, login.Admin.Username),
            new(ClaimTypes.Role, login.Admin.Role),
            // A freshly signed JWT (same issuer/audience/key as the API host) so views
            // can forward Bearer auth to the shared API layer when mixing MVC + API calls.
            new("jwt", login.SignToken(login.Admin.Username, login.Admin.Role)),
            new(ClaimTypes.AuthenticationMethod, "password")
        };

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            principal,
            new AuthenticationProperties
            {
                IsPersistent = model.RememberMe,
                ExpiresUtc = model.RememberMe
                    ? DateTimeOffset.UtcNow.AddDays(30)
                    : DateTimeOffset.UtcNow.AddHours(8),
                RedirectUri = GetSafeReturnUrl(Url, returnUrl)
            });

        return RedirectToAction("Index", "Dashboard");
    }

    // POST: /auth/logout
    [HttpPost]
    [Authorize]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Login", "Auth");
    }

    [HttpGet]
    [AllowAnonymous]
    public IActionResult Denied() => View();

    /// <summary>Only allow same-site relative return URLs to prevent open redirects.</summary>
    [NonAction]
    private static string GetSafeReturnUrl(IUrlHelper? url, string? returnUrl)
    {
        if (string.IsNullOrWhiteSpace(returnUrl))
            return "/";

        return url?.IsLocalUrl(returnUrl) == true ? returnUrl : "/";
    }
}
