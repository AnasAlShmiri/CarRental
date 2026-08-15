import re

# 1. Create lean view model
with open("Models/CarViewModel.cs") as f:
    src = f.read()

# Find the class body
m = re.search(r"public class CarViewModel(\s*:\s*IValidatableObject)?\s*\{(.*?)\n\}", src, re.DOTALL)
body = m.group(2)

# Remove Image, RemoveImage, CurrentImageUrl lines; keep the rest
lean_lines = []
for line in body.splitlines():
    stripped = line.strip()
    if stripped.startswith("public IFormFile? Image") or stripped.startswith("public bool RemoveImage") or stripped.startswith("public string? CurrentImageUrl"):
        continue
    lean_lines.append(line)

lean_body = "\n".join(lean_lines)
lean = src.replace(body, lean_body).replace("public class CarViewModel", "public class CarViewModelLean", 1)
lean = re.sub(r"^\s*//.*Image.*$", "", lean, flags=re.M)

with open("Models/CarViewModelLean.cs", "w") as f:
    f.write(lean)
print("CarViewModelLean created")

# 2. Swap CarsController: Create and Edit (GET/POST) to use CarViewModelLean
with open("Controllers/CarsController.cs") as f:
    ctrl = f.read()

# GET Create
ctrl = ctrl.replace("public IActionResult Create() => View(new CarViewModel());",
                    "public IActionResult Create() => View(new CarViewModelLean());")
# POST Create signature
ctrl = ctrl.replace("public async Task<IActionResult> Create([FromForm] CarViewModel model, CancellationToken ct)",
                    "public async Task<IActionResult> Create([FromForm] CarViewModelLean model, CancellationToken ct)")

# GET Edit: returns CarViewModel -> CarViewModelLean
ctrl = ctrl.replace("return View(new CarViewModel\n        {\n            Id = car.Id,\n            Model = car.Model,\n            Brand = car.Brand,\n            PricePerDay = car.PricePerDay,\n            CurrentImageUrl = car.ImageUrl,\n            Status = car.Status\n        });",
                    "return View(new CarViewModelLean\n        {\n            Id = car.Id,\n            Model = car.Model,\n            Brand = car.Brand,\n            PricePerDay = car.PricePerDay,\n            Status = car.Status\n        });")

# POST Edit signature
ctrl = ctrl.replace("public async Task<IActionResult> Edit(int id, [FromForm] CarViewModel model, CancellationToken ct)",
                    "public async Task<IActionResult> Edit(int id, [FromForm] CarViewModelLean model, CancellationToken ct)")

# TryParsePrice signature + body references
ctrl = ctrl.replace("private bool TryParsePrice(CarViewModel model, out decimal price)",
                    "private bool TryParsePrice(CarViewModelLean model, out decimal price)")
ctrl = ctrl.replace("ModelState.AddModelError(nameof(CarViewModel.PricePerDayText),",
                    "ModelState.AddModelError(nameof(CarViewModelLean.PricePerDayText),")

# POST Create/POST Edit Image handling blocks: since Lean has no Image, remove those blocks.
# POST Create image block (lines 64-80 area): from "string? imageUrl = null;" to "imageUrl = outcome.RelativeUrl;"
ctrl = re.sub(r"\s*string\? imageUrl = null;\n(?:        [^\n]*\n)*?        imageUrl = outcome\.RelativeUrl;\n", "\n", ctrl)
# POST Create: fix remaining create car call (now uses local imageUrl var from before?) rebuild the create section cleanly
ctrl = ctrl.replace("""        try
        {
            await repo.CreateAsync(new Car
            {
                Model = model.Model,
                Brand = model.Brand,
                PricePerDay = model.PricePerDay,
                ImageUrl = imageUrl
            });
        }
        catch
        {
            images.TryDelete(imageUrl);
            throw;
        }""", """        await repo.CreateAsync(new Car
        {
            Model = model.Model,
            Brand = model.Brand,
            PricePerDay = model.PricePerDay
        });""")

# POST Edit: remove image-change blocks, keep update call without imageUrlChange
ctrl = re.sub(r"\s*// null = keep the current photo.*?else if \(model\.RemoveImage\)\n        \{\n            imageUrlChange = string\.Empty;\n        \}\n", "\n", ctrl, flags=re.S)
ctrl = re.sub(r"\s*if \(model\.Image is \{ Length: > 0 \}\)\n(?:        [^\n]*\n)*?            imageUrlChange = outcome\.RelativeUrl;\n", "\n", ctrl)
ctrl = ctrl.replace("""        Car? updated;
        try
        {
            updated = await repo.UpdateAsync(
                id, model.Model, model.Brand, model.PricePerDay, imageUrlChange, model.Status);
        }
        catch
        {
            images.TryDelete(imageUrlChange);
            throw;
        }""", """        var updated = await repo.UpdateAsync(
            id, model.Model, model.Brand, model.PricePerDay, null, model.Status);""")
ctrl = re.sub(r"\s*// The photo changed or was removed.*?images\.TryDelete\(model\.CurrentImageUrl\);\n", "\n", ctrl, flags=re.S)

with open("Controllers/CarsController.cs", "w") as f:
    f.write(ctrl)

print("CarsController swapped. Image refs left:", ctrl.count("model.Image"), ctrl.count("model.RemoveImage"))

# 3. Swap Views: Create.cshtml and Edit.cshtml @model
for v in ["Views/Cars/Create.cshtml", "Views/Cars/Edit.cshtml"]:
    with open(v) as f:
        s = f.read()
    s = s.replace("@model CarRental.Web.Models.CarViewModel", "@model CarRental.Web.Models.CarViewModelLean")
    with open(v, "w") as f:
        f.write(s)
    print(v, "swapped")
