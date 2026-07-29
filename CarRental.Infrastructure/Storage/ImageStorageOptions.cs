namespace CarRental.Infrastructure.Storage;

/// <summary>
/// Where and how car photos are stored. Bound from the "ImageStorage" configuration
/// section; <see cref="PhysicalRootPath"/> is supplied by the API host at startup
/// because only the host knows its content/web root.
/// </summary>
public class ImageStorageOptions
{
    public const string SectionName = "ImageStorage";

    /// <summary>Absolute path of the web root (wwwroot). Set by the host, not by config.</summary>
    public string PhysicalRootPath { get; set; } = string.Empty;

    /// <summary>Folder beneath the web root that holds the images.</summary>
    public string RelativeFolder { get; set; } = "uploads";

    /// <summary>Upload size ceiling. Default 5 MB.</summary>
    public long MaxBytes { get; set; } = 5 * 1024 * 1024;
}
