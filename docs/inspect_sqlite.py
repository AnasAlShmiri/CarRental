from pathlib import Path
import sqlite3

root = Path(__file__).resolve().parents[1]
for relative in ("car-rental.db", "CarRental.API/car-rental.db", "CarRental.Web/car-rental.db"):
    path = root / relative
    print(f"--- {relative} ---")
    if not path.exists():
        print("missing")
        continue
    with sqlite3.connect(path) as connection:
        tables = [row[0] for row in connection.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
        print("tables:", ", ".join(tables))
        for table in ("Cars", "Customers", "Rentals"):
            if table in tables:
                count = connection.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
                print(f"{table}: {count}")
        if "Customers" in tables:
            columns = [row[1] for row in connection.execute('PRAGMA table_info("Customers")')]
            print("Customers columns:", ", ".join(columns))
