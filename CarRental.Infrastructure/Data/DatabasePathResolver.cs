using Microsoft.Data.Sqlite;

namespace CarRental.Infrastructure.Data;

/// <summary>
/// Normalizes relative SQLite paths against the repository root rather than the
/// process working directory. This keeps the API and MVC hosts on one database
/// when started from Visual Studio, a terminal, or the portable Windows scripts.
/// </summary>
public static class DatabasePathResolver
{
    public static string ResolveSqliteConnection(string? configuredConnectionString, string contentRootPath)
    {
        var builder = new SqliteConnectionStringBuilder(
            string.IsNullOrWhiteSpace(configuredConnectionString)
                ? "Data Source=../car-rental.db"
                : configuredConnectionString);

        if (string.IsNullOrWhiteSpace(builder.DataSource)
            || builder.DataSource.Equals(":memory:", StringComparison.OrdinalIgnoreCase)
            || Path.IsPathRooted(builder.DataSource))
        {
            return builder.ToString();
        }

        var repositoryRoot = FindRepositoryRoot(contentRootPath);
        builder.DataSource = Path.GetFullPath(Path.Combine(repositoryRoot, builder.DataSource));
        return builder.ToString();
    }

    private static string FindRepositoryRoot(string contentRootPath)
    {
        for (var directory = new DirectoryInfo(AppContext.BaseDirectory);
             directory is not null;
             directory = directory.Parent)
        {
            if (File.Exists(Path.Combine(directory.FullName, "CarRental.slnx")))
                return directory.FullName;
        }

        var contentRoot = new DirectoryInfo(contentRootPath);
        return contentRoot.Parent?.FullName ?? contentRoot.FullName;
    }
}
