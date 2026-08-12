import re

# 1. CarsController: restore CarViewModel in Create GET/POST, remove TestBind, remove Console.Error log
p = "Controllers/CarsController.cs"
s = open(p).read()

# restore Create GET
s = s.replace("public IActionResult Create() => View(new CarViewModel2());",
              "public IActionResult Create() => View(new CarViewModel());")
# restore Create POST signature
s = s.replace("public async Task<IActionResult> Create(CarViewModel2 model)",
              "public async Task<IActionResult> Create([FromForm] CarViewModel model)")
# remove TestBind block (GET + POST)
s = re.sub(r"\s*// GET/POST test binding probe\n.*?return RedirectToAction\(\"Index\"\);\n    \}", "", s, flags=re.DOTALL)
# remove Console.Error log line
s = re.sub(r'\s*Console\.Error\.WriteLine\(\$\[Cars\.Create\].*?\);\n', "\n", s)

open(p, "w").write(s)
print("CarsController cleaned:", "TestBind" not in s and "CarViewModel2" not in s)

# 2. Program.cs: remove test-echo endpoint
p = "Program.cs"
s = open(p).read()
s = re.sub(r'\napp\.MapPost\("/test-echo".*?\n\}\);\n', "\n", s, flags=re.DOTALL)
open(p, "w").write(s)
print("Program.cs cleaned:", "test-echo" not in s)

# 3. Remove debug file
import os
try:
    os.remove("Models/CarViewModel2.cs")
    print("CarViewModel2.cs removed")
except FileNotFoundError:
    print("CarViewModel2.cs already gone")
