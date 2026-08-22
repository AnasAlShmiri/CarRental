using CarRental.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.Web.Controllers;

/// <summary>Anonymous error page used by the MVC exception handler.</summary>
[AllowAnonymous]
public class HomeController : Controller
{
    [HttpGet]
    public IActionResult Error() => View(new ErrorViewModel
    {
        Title = "حدث خطأ غير متوقع",
        Detail = "يرجى المحاولة مرة أخرى. إذا استمرت المشكلة فاتصل بمسؤول النظام."
    });
}
