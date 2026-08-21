namespace CarRental.Domain.Exceptions;

/// <summary>
/// A valid request that cannot be completed because the current resource state
/// conflicts with it, such as a car becoming unavailable during booking.
/// </summary>
public sealed class DomainConflictException(string message) : Exception(message);
