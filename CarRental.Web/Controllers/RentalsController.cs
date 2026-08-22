using CarRental.Application.Interfaces;
using CarRental.Domain.Exceptions;
using CarRental.Domain.Models;
using CarRental.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.Web.Controllers;

[Authorize(Roles = "Admin")]
public class RentalsController(
    IRentalRepository rentalRepo,
    ICarRepository carRepo,
    ICustomerRepository customerRepo) : Controller
{
    // GET: /rentals
    public async Task<IActionResult> Index() => View(await rentalRepo.GetAllAsync());

    // GET: /rentals/details/5
    public async Task<IActionResult> Details(int? id)
    {
        if (id is null) return RedirectToAction("Index");

        var rental = await rentalRepo.GetByIdAsync(id.Value);
        if (rental is null) return NotFound(new ErrorViewModel
        {
            Title = "الإيجار غير موجود",
            Detail = $"الإيجار رقم {id} غير موجود في النظام."
        });

        return View(rental);
    }

    // GET: /rentals/create
    [HttpGet]
    public async Task<IActionResult> Create()
    {
        await LoadSelectListsAsync();
        return View(new RentalViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(RentalViewModel model)
    {
        await LoadSelectListsAsync();

        if (!ModelState.IsValid)
        {
            var errs = string.Join("; ", ModelState
                .Where(kv => kv.Value is { Errors.Count: > 0 })
                .SelectMany(kv => kv.Value!.Errors.Select(e => $"{kv.Key}: {e.ErrorMessage}")));
            if (!string.IsNullOrEmpty(errs))
                TempData["ErrorMessage"] = errs;
            return View(model);
        }

        var start = DateTime.SpecifyKind(model.StartDate.Date, DateTimeKind.Utc);
        var end = DateTime.SpecifyKind(model.EndDate.Date, DateTimeKind.Utc);

        var car = await carRepo.GetByIdAsync(model.CarId);
        if (car is null)
        {
            ModelState.AddModelError(nameof(RentalViewModel.CarId), "السيارة المحددة غير موجودة");
            return View(model);
        }

        if (!await customerRepo.ExistsAsync(model.CustomerId))
        {
            ModelState.AddModelError(nameof(RentalViewModel.CustomerId), "العميل المحدد غير موجود");
            return View(model);
        }

        if (end <= start)
        {
            ModelState.AddModelError(nameof(RentalViewModel.EndDate),
                "تاريخ النهاية يجب أن يكون بعد تاريخ البداية بيوم على الأقل");
            return View(model);
        }

        if (start.Date < DateTime.UtcNow.Date)
        {
            ModelState.AddModelError(nameof(RentalViewModel.StartDate),
                "لا يمكن الحجز بتاريخ بداية في الماضي");
            return View(model);
        }

        if (car.Status == CarStatus.UnderMaintenance)
        {
            ModelState.AddModelError(nameof(RentalViewModel.CarId),
                "هذه السيارة قيد الصيانة ولا يمكن تأجيرها");
            return View(model);
        }

        if (await rentalRepo.HasOverlappingRentalAsync(model.CarId, start, end))
        {
            ModelState.AddModelError(nameof(RentalViewModel.CarId),
                "السيارة محجوزة بالفعل خلال هذه الفترة — اختر فترة أخرى أو سيارة أخرى");
            return View(model);
        }

        if (car.Status != CarStatus.Available)
        {
            ModelState.AddModelError(nameof(RentalViewModel.CarId),
                $"السيارة حالياً '{car.Status}' ولا يمكن تأجيرها");
            return View(model);
        }

        try
        {
            await rentalRepo.CreateAsync(new Rental
            {
                CarId = model.CarId,
                CustomerId = model.CustomerId,
                StartDate = start,
                EndDate = end
            });
        }
        catch (DomainConflictException ex)
        {
            ModelState.AddModelError(nameof(RentalViewModel.CarId),
                ex.Message.Contains("already reserved", StringComparison.OrdinalIgnoreCase)
                    ? "السيارة حُجزت للتو خلال هذه الفترة — اختر فترة أخرى أو سيارة أخرى"
                    : "السيارة لم تعد متاحة للحجز — حدّث الصفحة واختر سيارة أخرى");
            return View(model);
        }

        TempData["SuccessMessage"] = "تم إنشاء الحجز بنجاح وخصم السيارة من الكتالوج";
        return RedirectToAction("Index");
    }

    // POST: /rentals/complete/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Complete(int id)
    {
        return await TransitionAsync(id, RentalStatus.Completed,
            "تم إكمال الإيجار وإعادة السيارة إلى الكتالوج");
    }

    // POST: /rentals/cancel/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Cancel(int id)
    {
        return await TransitionAsync(id, RentalStatus.Cancelled,
            "تم إلغاء الإيجار وإعادة السيارة إلى الكتالوج");
    }

    // GET: /rentals/delete/5
    [HttpGet]
    public async Task<IActionResult> Delete(int? id)
    {
        if (id is null) return RedirectToAction("Index");

        var rental = await rentalRepo.GetByIdAsync(id.Value);
        if (rental is null) return NotFound();

        return View(rental);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var deleted = await rentalRepo.DeleteAsync(id);
        if (!deleted) return NotFound();

        TempData["SuccessMessage"] = "تم حذف الإيجار وإعادة السيارة إلى الكتالوج";
        return RedirectToAction("Index");
    }

    private async Task<IActionResult> TransitionAsync(int id, string target, string successMessage)
    {
        var existing = await rentalRepo.GetByIdAsync(id);
        if (existing is null) return NotFound();

        if (existing.Status == target)
        {
            TempData["ErrorMessage"] = $"الإيجار بالفعل '{target}'";
            return RedirectToAction("Index");
        }

        if (!RentalStatus.IsOpen(existing.Status))
        {
            TempData["ErrorMessage"] =
                $"الإيجار '{existing.Status}' ولا يمكن تغيير حالته بعد إغلاقه";
            return RedirectToAction("Index");
        }

        var updated = await rentalRepo.ChangeStatusAsync(id, target);
        if (updated is null) return NotFound();

        TempData["SuccessMessage"] = successMessage;
        return RedirectToAction("Index");
    }

    /// <summary>Populates car/customer dropdowns and caches them in ViewData.</summary>
    [NonAction]
    private async Task LoadSelectListsAsync()
    {
        var cars = (await carRepo.GetAllAsync())
            .Select(c => new { c.Id, Label = $"{c.Brand} {c.Model} ({c.Status})" });
        ViewData["Cars"] = cars;

        var customers = (await customerRepo.GetAllAsync())
            .Select(c => new { c.Id, Label = c.Name });
        ViewData["Customers"] = customers;
    }
}
