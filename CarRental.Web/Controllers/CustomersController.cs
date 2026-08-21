using CarRental.Application.Interfaces;
using CarRental.Domain.Models;
using CarRental.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CarRental.Web.Controllers;

[Authorize(Roles = "Admin")]
public class CustomersController(ICustomerRepository repo) : Controller
{
    // GET: /customers
    public async Task<IActionResult> Index() => View(await repo.GetAllAsync());

    // GET: /customers/details/5
    public async Task<IActionResult> Details(int? id)
    {
        if (id is null) return RedirectToAction("Index");

        var customer = await repo.GetByIdAsync(id.Value);
        if (customer is null) return NotFound(new ErrorViewModel
        {
            Title = "العميل غير موجود",
            Detail = $"العميل رقم {id} غير موجود في النظام."
        });

        return View(customer);
    }

    // GET: /customers/create
    [HttpGet]
    public IActionResult Create() => View(new CustomerViewModel());

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CustomerViewModel model)
    {
        if (!ModelState.IsValid)
        {
            ShowModelStateErrors();
            return View(model);
        }

        if (await repo.EmailExistsAsync(model.Email))
        {
            ModelState.AddModelError(nameof(CustomerViewModel.Email), "هذا البريد الإلكتروني مسجَّل لدى عميل آخر");
            return View(model);
        }

        await repo.CreateAsync(new Customer
        {
            Name = model.Name,
            Email = model.Email,
            Phone = model.Phone
        });

        TempData["SuccessMessage"] = "تمت إضافة العميل بنجاح";
        return RedirectToAction("Index");
    }

    // GET: /customers/edit/5
    [HttpGet]
    public async Task<IActionResult> Edit(int? id)
    {
        if (id is null) return RedirectToAction("Index");

        var customer = await repo.GetByIdAsync(id.Value);
        if (customer is null) return NotFound();

        return View(new CustomerViewModel
        {
            Id = customer.Id,
            Name = customer.Name,
            Email = customer.Email,
            Phone = customer.Phone
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, CustomerViewModel model)
    {
        if (id != model.Id) return RedirectToAction("Index");

        if (!ModelState.IsValid)
        {
            ShowModelStateErrors();
            model.Id = id;
            return View(model);
        }

        if (await repo.EmailExistsAsync(model.Email, excludeCustomerId: id))
        {
            ModelState.AddModelError(nameof(CustomerViewModel.Email), "هذا البريد الإلكتروني مسجَّل لدى عميل آخر");
            model.Id = id;
            return View(model);
        }

        var updated = await repo.UpdateAsync(id, model.Name, model.Email, model.Phone);
        if (updated is null) return NotFound();

        TempData["SuccessMessage"] = "تم تعديل بيانات العميل بنجاح";
        return RedirectToAction("Index");
    }

    // GET: /customers/delete/5
    [HttpGet]
    public async Task<IActionResult> Delete(int? id)
    {
        if (id is null) return RedirectToAction("Index");

        var customer = await repo.GetByIdAsync(id.Value);
        if (customer is null) return NotFound();

        return View(customer);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var customer = await repo.GetByIdAsync(id);
        if (customer is null) return NotFound();

        if (await repo.HasActiveRentalsAsync(id))
        {
            TempData["ErrorMessage"] = "لا يمكن حذف عميل عليه إيجار نشط — أنهِ أو ألغِ الإيجار أولاً";
            return RedirectToAction("Index");
        }

        if (await repo.HasAnyRentalsAsync(id))
        {
            TempData["ErrorMessage"] = "لا يمكن حذف عميل له سجل إيجارات — احتفظ بسجلات الحسابات المالية";
            return RedirectToAction("Index");
        }

        await repo.DeleteAsync(id);

        TempData["SuccessMessage"] = "تم حذف العميل بنجاح";
        return RedirectToAction("Index");
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
