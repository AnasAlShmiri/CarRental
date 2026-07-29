namespace CarRental.Application.Interfaces;

/// <summary>Result of an attempted image save.</summary>
/// <param name="Success">True when the file was written.</param>
/// <param name="RelativeUrl">Web path to the stored file, e.g. "/uploads/abc123.jpg".</param>
/// <param name="Error">Human-readable reason the upload was rejected.</param>
public sealed record ImageSaveOutcome(bool Success, string? RelativeUrl, string? Error)
{
    public static ImageSaveOutcome Ok(string relativeUrl) => new(true, relativeUrl, null);
    public static ImageSaveOutcome Rejected(string error) => new(false, null, error);
}

/// <summary>
/// Stores car photos. Abstracted so the controller never touches the file system
/// directly, and so the backing store could later become S3/Azure Blob without
/// changing the API layer.
/// </summary>
public interface ICarImageStorage
{
    /// <summary>
    /// Validates and stores an uploaded image.
    /// <para>
    /// The client-supplied file name is used only to read its extension — the stored
    /// name is always generated, so a malicious name such as "../../appsettings.json"
    /// cannot escape the uploads folder.
    /// </para>
    /// </summary>
    Task<ImageSaveOutcome> SaveAsync(
        Stream content, string originalFileName, long lengthInBytes, CancellationToken ct = default);

    /// <summary>
    /// Deletes a previously stored file, given the relative URL kept on the car.
    /// Ignores values that point outside the uploads folder, and never throws.
    /// </summary>
    void TryDelete(string? relativeUrl);

    /// <summary>Extensions accepted by <see cref="SaveAsync"/>, for error messages.</summary>
    IReadOnlyCollection<string> AllowedExtensions { get; }

    /// <summary>Maximum accepted upload size in bytes.</summary>
    long MaxBytes { get; }
}
