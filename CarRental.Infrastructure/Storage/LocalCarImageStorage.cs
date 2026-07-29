using CarRental.Application.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CarRental.Infrastructure.Storage;

/// <summary>
/// Stores car photos as files under {webroot}/{RelativeFolder} so they can be served
/// directly by the static-file middleware.
/// </summary>
public class LocalCarImageStorage : ICarImageStorage
{
    private static readonly Dictionary<string, string[]> ExtensionsByType = new(StringComparer.OrdinalIgnoreCase)
    {
        [".jpg"] = ["jpeg"],
        [".jpeg"] = ["jpeg"],
        [".png"] = ["png"],
        [".gif"] = ["gif"],
        [".webp"] = ["webp"],
    };

    private readonly ImageStorageOptions _options;
    private readonly ILogger<LocalCarImageStorage> _logger;

    public LocalCarImageStorage(IOptions<ImageStorageOptions> options, ILogger<LocalCarImageStorage> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public IReadOnlyCollection<string> AllowedExtensions => ExtensionsByType.Keys.ToArray();

    public long MaxBytes => _options.MaxBytes;

    private string TargetDirectory =>
        Path.Combine(_options.PhysicalRootPath, _options.RelativeFolder);

    public async Task<ImageSaveOutcome> SaveAsync(
        Stream content, string originalFileName, long lengthInBytes, CancellationToken ct = default)
    {
        if (lengthInBytes <= 0)
            return ImageSaveOutcome.Rejected("The uploaded file is empty.");

        if (lengthInBytes > _options.MaxBytes)
            return ImageSaveOutcome.Rejected(
                $"The file is {lengthInBytes / 1024d / 1024d:F1} MB, which exceeds the " +
                $"{_options.MaxBytes / 1024d / 1024d:F0} MB limit.");

        // Only the extension is taken from the client's name — never the name itself.
        var extension = Path.GetExtension(originalFileName);
        if (string.IsNullOrWhiteSpace(extension) || !ExtensionsByType.TryGetValue(extension, out var expectedKinds))
            return ImageSaveOutcome.Rejected(
                $"'{extension}' is not a supported image type. Allowed: {string.Join(", ", AllowedExtensions)}.");

        // Buffer the upload so we can inspect its header and still write it afterwards.
        using var buffer = new MemoryStream();
        await content.CopyToAsync(buffer, ct);
        buffer.Position = 0;

        var actualKind = DetectImageKind(buffer);
        buffer.Position = 0;

        if (actualKind is null)
            return ImageSaveOutcome.Rejected(
                "The file's contents are not a recognised image. Renaming a non-image file " +
                "to .jpg or .png does not make it an image.");

        // Guards against a .exe renamed to .png: the header must match the extension.
        if (!expectedKinds.Contains(actualKind, StringComparer.OrdinalIgnoreCase))
            return ImageSaveOutcome.Rejected(
                $"The file extension says '{extension}' but its contents are '{actualKind}'. " +
                "Rename the file to match its real format and try again.");

        try
        {
            Directory.CreateDirectory(TargetDirectory);

            // Generated name: unique, lowercase, no user input, no path separators.
            var fileName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
            var physicalPath = Path.Combine(TargetDirectory, fileName);

            await using (var file = File.Create(physicalPath))
                await buffer.CopyToAsync(file, ct);

            var relativeUrl = $"/{_options.RelativeFolder}/{fileName}";
            _logger.LogInformation("Stored car image {File} ({Bytes} bytes)", relativeUrl, lengthInBytes);
            return ImageSaveOutcome.Ok(relativeUrl);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to write uploaded image to {Directory}", TargetDirectory);
            return ImageSaveOutcome.Rejected("The image could not be saved on the server.");
        }
    }

    public void TryDelete(string? relativeUrl)
    {
        if (string.IsNullOrWhiteSpace(relativeUrl)) return;

        // Only ever delete files this API stored: the value must be a local path inside
        // the uploads folder. External URLs and traversal attempts are ignored.
        if (relativeUrl.Contains("://", StringComparison.Ordinal)) return;

        var expectedPrefix = $"/{_options.RelativeFolder}/";
        if (!relativeUrl.StartsWith(expectedPrefix, StringComparison.OrdinalIgnoreCase)) return;

        var fileName = Path.GetFileName(relativeUrl);
        if (string.IsNullOrWhiteSpace(fileName)) return;

        try
        {
            var target = Path.GetFullPath(Path.Combine(TargetDirectory, fileName));
            var root = Path.GetFullPath(TargetDirectory);

            // Final containment check before touching the disk.
            if (!target.StartsWith(root, StringComparison.OrdinalIgnoreCase)) return;

            if (File.Exists(target))
            {
                File.Delete(target);
                _logger.LogInformation("Deleted car image {File}", relativeUrl);
            }
        }
        catch (Exception ex)
        {
            // A stale file is not worth failing the request over.
            _logger.LogWarning(ex, "Could not delete car image {File}", relativeUrl);
        }
    }

    /// <summary>Identifies the format from the file's magic bytes, or null if unrecognised.</summary>
    private static string? DetectImageKind(Stream stream)
    {
        Span<byte> head = stackalloc byte[12];
        var read = stream.Read(head);
        if (read < 3) return null;

        // JPEG: FF D8 FF
        if (head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF)
            return "jpeg";

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (read >= 8 &&
            head[0] == 0x89 && head[1] == 0x50 && head[2] == 0x4E && head[3] == 0x47 &&
            head[4] == 0x0D && head[5] == 0x0A && head[6] == 0x1A && head[7] == 0x0A)
            return "png";

        // GIF: "GIF8"
        if (read >= 4 && head[0] == 0x47 && head[1] == 0x49 && head[2] == 0x46 && head[3] == 0x38)
            return "gif";

        // WEBP: "RIFF" .... "WEBP"
        if (read >= 12 &&
            head[0] == 0x52 && head[1] == 0x49 && head[2] == 0x46 && head[3] == 0x46 &&
            head[8] == 0x57 && head[9] == 0x45 && head[10] == 0x42 && head[11] == 0x50)
            return "webp";

        return null;
    }
}
