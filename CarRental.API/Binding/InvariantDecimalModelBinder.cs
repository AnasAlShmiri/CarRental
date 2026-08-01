using System.Globalization;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace CarRental.API.Binding;

/// <summary>
/// Binds <see cref="decimal"/> values coming from form/query/route data using the
/// invariant culture, but WITHOUT <see cref="NumberStyles.AllowThousands"/>.
/// <para>
/// BUGFIX: the default binder (running under the invariant culture forced at startup)
/// parsed "10,5" as <c>105</c> — in the invariant culture the comma is a *thousands*
/// separator, so a European-style decimal comma silently multiplied a price by 10 and
/// the car was created with the wrong rate. Group separators are now rejected with a
/// clear validation message instead; only "150" / "150.50" style values are accepted.
/// </para>
/// <para>
/// JSON payloads are unaffected — System.Text.Json handles those, and JSON numbers
/// have no culture. This binder only guards the multipart/form fields (e.g. the Cars
/// form's pricePerDay).
/// </para>
/// </summary>
public sealed class InvariantDecimalModelBinder : IModelBinder
{
    // Decimal point and a leading sign only. No thousands separators, no exponent,
    // no currency symbols, no parentheses.
    private const NumberStyles Styles = NumberStyles.AllowDecimalPoint | NumberStyles.AllowLeadingSign;

    public Task BindModelAsync(ModelBindingContext bindingContext)
    {
        ArgumentNullException.ThrowIfNull(bindingContext);

        var valueResult = bindingContext.ValueProvider.GetValue(bindingContext.ModelName);
        if (valueResult == ValueProviderResult.None)
            return Task.CompletedTask; // Nothing submitted — leave it to [Required]/[Range] to decide.

        bindingContext.ModelState.SetModelValue(bindingContext.ModelName, valueResult);

        var raw = valueResult.FirstValue?.Trim();
        if (string.IsNullOrEmpty(raw))
        {
            // Empty nullable decimal is a legitimate "not provided".
            if (Nullable.GetUnderlyingType(bindingContext.ModelType) is not null)
                bindingContext.Result = ModelBindingResult.Success(null);
            return Task.CompletedTask;
        }

        if (decimal.TryParse(raw, Styles, CultureInfo.InvariantCulture, out var value))
        {
            bindingContext.Result = ModelBindingResult.Success(value);
        }
        else
        {
            bindingContext.ModelState.TryAddModelError(
                bindingContext.ModelName,
                $"'{raw}' is not a valid number. Use a dot as the decimal separator " +
                "(e.g. 150.50) and no thousands separators.");
        }

        return Task.CompletedTask;
    }
}

/// <summary>Wires <see cref="InvariantDecimalModelBinder"/> up for decimal and decimal?.</summary>
public sealed class InvariantDecimalModelBinderProvider : IModelBinderProvider
{
    public IModelBinder? GetBinder(ModelBinderProviderContext context)
    {
        ArgumentNullException.ThrowIfNull(context);

        return context.Metadata.UnderlyingOrModelType == typeof(decimal)
            ? new InvariantDecimalModelBinder()
            : null;
    }
}
