using CarRental.Application.Interfaces;
using System.Globalization;
using CarRental.Domain.Models;
using CarRental.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.Web.Controllers;

/// <summary>
/// Admin dashboard controller for managing cars: list with status filtering,
/// details, create (with photo upload), edit (photo replace/remove + status),
/// and delete with rental-history safeguards.
/// </summary>
[Authorize]
public class CarsController(ICarRepository repo, ICarImageStorage images) : Controller
{
    // GET: /cars
    public async Task<IActionResult> Index([FromQuery] string? status)
    {
        var cars = status is null || !CarStatus.IsValid(status)
            ? await repo.GetAllAsync()
            : await repo.GetByStatusAsync(status);

        ViewData["CurrentStatus"] = status;
        return View(cars);
    }

    // GET: /cars/details/5
    public async Task<IActionResult> Details(int? id)
    {
        if (id is null) return RedirectToAction("Index");

        var car = await repo.GetByIdAsync(id.Value);
        if (car is null)
            return NotFound(new ErrorViewModel
            {
                Title = "السيارة غير موجودة",
                Detail = $"السيارة رقم {id} غير موجودة في النظام."
            });

        return View(car);
    }

    // GET: /cars/create
    [HttpGet]
    public IActionResult Create() => View(new CarViewModel());

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CarViewModel model)
    {
        if (!TryParsePrice(model.PricePerDayText, out var price))
            ModelState.AddModelError(nameof(CarViewModel.PricePerDayText),
                "السعر يجب أن يكون رقمًا صحيحًا بالموجة العشرية (مثال: 150.50)");

        if (!ModelState.IsValid)
        {
            ShowModelStateErrors();
            return View(model);
        }

        string? uploadedUrl = null;
        try
        {
            if (model.Image is not null)
            {
                var outcome = await images.SaveAsync(
                    model.Image.OpenReadStream(), model.Image.FileName, model.Image.Length);

                if (!outcome.Success)
                {
                    ModelState.AddModelError(nameof(CarViewModel.Image),
                        outcome.Error ?? "فشل حفظ الصورة المرفوعة");
                    return View(model);
                }

                uploadedUrl = outcome.RelativeUrl;
            }

            await repo.CreateAsync(new Car
            {
                Model = model.CarModel.Trim(),
                Brand = model.Brand.Trim(),
                PricePerDay = price,
                Status = CarStatus.Available,
                ImageUrl = uploadedUrl
            });

            TempData["SuccessMessage"] = "تمت إضافة السيارة بنجاح";
            return RedirectToAction("Index");
        }
        catch
        {
            if (uploadedUrl is not null)
                images.TryDelete(uploadedUrl);
            throw;
        }
    }

    // GET: /cars/edit/5
    [HttpGet]
    public async Task<IActionResult> Edit(int? id)
    {
        if (id is null) return RedirectToAction("Index");

        var car = await repo.GetByIdAsync(id.Value);
        if (car is null) return NotFound();

        return View(new CarViewModel
        {
            Id = car.Id,
            CarModel = car.Model,
            Brand = car.Brand,
            PricePerDayText = car.PricePerDay.ToString("F2", CultureInfo.InvariantCulture),
            Status = car.Status,
            CurrentImageUrl = car.ImageUrl
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, CarViewModel model)
    {
        if (id != model.Id) return RedirectToAction("Index");

        if (!TryParsePrice(model.PricePerDayText, out var price))
            ModelState.AddModelError(nameof(CarViewModel.PricePerDayText),
                "السعر يجب أن يكون رقمًا صحيحًا بالموجة العشرية (مثال: 150.50)");

        if (!ModelState.IsValid)
        {
            ShowModelStateErrors();
            model.Id = id;
            return View(model);
        }

        string? newImageUrl = null;
        string? keepOrOldUrl = null;

        if (model.Image is not null)
        {
            // New upload replaces the current photo.
            var outcome = await images.SaveAsync(
                model.Image.OpenReadStream(), model.Image.FileName, model.Image.Length);

            if (!outcome.Success)
            {
                ModelState.AddModelError(nameof(CarViewModel.Image),
                    outcome.Error ?? "فشل حفظ الصورة المرفوعة");
                model.Id = id;
                return View(model);
            }

            newImageUrl = outcome.RelativeUrl;
        }
        else if (model.RemoveImage)
        {
            // Explicit removal: clear the URL and delete the stored file.
            newImageUrl = null;
            images.TryDelete(model.CurrentImageUrl);
        }
        else
        {
            keepOrOldUrl = model.CurrentImageUrl;
        }

        var status = model.Status is null
            ? (await repo.GetByIdAsync(id))?.Status
            : CarStatus.IsValid(model.Status) ? model.Status : null;

        var updated = await repo.UpdateAsync(id,
            model.CarModel.Trim(),
            model.Brand.Trim(),
            price,
            newImageUrl ?? keepOrOldUrl,
            status);

        if (updated is null) return NotFound();

        TempData["SuccessMessage"] = "تم تعديل بيانات السيارة بنجاح";
        return RedirectToAction("Index");
    }

    // GET: /cars/delete/5
    [HttpGet]
    public async Task<IActionResult> Delete(int? id)
    {
        if (id is null) return RedirectToAction("Index");

        var car = await repo.GetByIdAsync(id.Value);
        if (car is null) return NotFound();

        return View(car);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var car = await repo.GetByIdAsync(id);
        if (car is null) return NotFound();

        if (await repo.HasActiveRentalsAsync(id))
        {
            TempData["ErrorMessage"] = "لا يمكن حذف سيارة عليها إيجار نشط — أنهِ أو ألغِ الإيجار أولاً";
            return RedirectToAction("Index");
        }

        if (await repo.HasAnyRentalsAsync(id))
        {
            TempData["ErrorMessage"] = "لا يمكن حذف سيارة لها سجل إيجارات — احتفظ بها في السجل أو عالج الإيجارات المرتبطة أولاً";
            return RedirectToAction("Index");
        }

        await repo.DeleteAsync(id);
        images.TryDelete(car.ImageUrl);

        TempData["SuccessMessage"] = "تم حذف السيارة بنجاح";
        return RedirectToAction("Index");
    }

    private static bool TryParsePrice(string text, out decimal price)
    {
        price = 0m;
        if (string.IsNullOrWhiteSpace(text)) return false;
        return decimal.TryParse(text, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out price)
               && price >= 0m;
    }

    private void ShowModelStateErrors()
    {
        var errs = string.Join("; ", ModelState
            .Where(kv => kv.Value is { Errors.Count: > 0 })
            .SelectMany(kv => kv.Value!.Errors.Select(e => $"{kv.Key}: {e.ErrorMessage}")));
        if (!string.IsNullOrEmpty(errs))
            TempData["ErrorMessage"] = errs;
    }
}
