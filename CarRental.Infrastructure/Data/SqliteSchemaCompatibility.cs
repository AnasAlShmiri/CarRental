using Microsoft.EntityFrameworkCore;

namespace CarRental.Infrastructure.Data;

/// <summary>
/// Applies small, backward-compatible SQLite schema additions for portable development
/// databases created with EnsureCreated. SQL Server installations continue to use EF
/// migrations as the source of truth.
/// </summary>
public static class SqliteSchemaCompatibility
{
    public static async Task EnsureAsync(
        ApplicationDbContext db,
        CancellationToken cancellationToken = default)
    {
        if (!db.Database.IsSqlite())
            return;

        await db.Database.OpenConnectionAsync(cancellationToken);
        try
        {
            foreach (var pragma in new[]
                     {
                         "PRAGMA foreign_keys = ON;",
                         "PRAGMA journal_mode = WAL;",
                         "PRAGMA synchronous = NORMAL;",
                         "PRAGMA busy_timeout = 5000;"
                     })
            {
                await using var pragmaCommand = db.Database.GetDbConnection().CreateCommand();
                pragmaCommand.CommandText = pragma;
                await pragmaCommand.ExecuteNonQueryAsync(cancellationToken);
            }

            var hasPasswordHash = false;
            await using (var command = db.Database.GetDbConnection().CreateCommand())
            {
                command.CommandText = "PRAGMA table_info('Customers');";
                await using var reader = await command.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    if (string.Equals(reader.GetString(1), "PasswordHash", StringComparison.OrdinalIgnoreCase))
                    {
                        hasPasswordHash = true;
                        break;
                    }
                }
            }

            if (!hasPasswordHash)
            {
                await db.Database.ExecuteSqlRawAsync(
                    "ALTER TABLE \"Customers\" ADD COLUMN \"PasswordHash\" TEXT NULL;",
                    cancellationToken);
            }
        }
        finally
        {
            await db.Database.CloseConnectionAsync();
        }
    }
}
