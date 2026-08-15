s = open("Controllers/CarsController.cs").read()
test = """
    // GET/POST test binding probe
    [HttpGet]
    public IActionResult TestBind() => View("Create", new CustomerViewModel());

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> TestBind(CustomerViewModel model)
    {
        Console.Error.WriteLine($"[Cars.TestBind] IsValid={ModelState.IsValid} Name={model.Name} Email={model.Email} Phone={model.Phone}");
        if (!ModelState.IsValid)
        {
            var errs = string.Join("; ", ModelState
                .Where(kv => kv.Value is { Errors.Count: > 0 })
                .SelectMany(kv => kv.Value!.Errors.Select(e => $"{kv.Key}: {e.ErrorMessage}")));
            if (!string.IsNullOrEmpty(errs))
                TempData["ErrorMessage"] = errs;
            return View("Create", model);
        }
        TempData["SuccessMessage"] = "TestBind OK: " + model.Name;
        return RedirectToAction("Index");
    }
"""
if "TestBind" not in s:
    s = s.replace("    // GET: /cars/create", test + "\n    // GET: /cars/create")
    open("Controllers/CarsController.cs", "w").write(s)
    print("added TestBind")
else:
    print("already present")
