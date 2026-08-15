namespace CarRental.Web.Models;

public class ErrorViewModel
{
    /// <summary>Optional title shown above the error detail.</summary>
    public string? Title { get; set; }

    /// <summary>Optional human-readable detail; when null a generic message is rendered.</summary>
    public string? Detail { get; set; }

    public bool HasDetail => !string.IsNullOrWhiteSpace(Detail);
}
