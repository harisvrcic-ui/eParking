namespace eParking.Services;

/// <summary>
/// Jedinstvena pravila: rezervacija je aktivna samo dok traje (start &lt;= sada &lt; kraj).
/// Datumi iz mobilne app šalju se kao UTC; stariji zapisi bez Kind tretiraju se kao lokalno (BiH).
/// </summary>
public static class ReservationTimeHelper
{
    private static readonly TimeZoneInfo AppTimeZone = ResolveAppTimeZone();

    private static TimeZoneInfo ResolveAppTimeZone()
    {
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById(
                OperatingSystem.IsWindows()
                    ? "Central European Standard Time"
                    : "Europe/Sarajevo");
        }
        catch (TimeZoneNotFoundException)
        {
            return TimeZoneInfo.Local;
        }
    }

    public static DateTime UtcNow => DateTime.UtcNow;

    /// <summary>Normalizacija pri spremanju (POST/PUT).</summary>
    public static DateTime NormalizeToUtc(DateTime value)
    {
        return value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => TimeZoneInfo.ConvertTimeToUtc(
                DateTime.SpecifyKind(value, DateTimeKind.Unspecified),
                AppTimeZone)
        };
    }

    /// <summary>Usporedba sadašnjeg trenutka (za čitanje iz baze).</summary>
    public static DateTime ToUtcForCompare(DateTime value)
    {
        if (value.Kind == DateTimeKind.Utc)
            return value;

        if (value.Kind == DateTimeKind.Local)
            return value.ToUniversalTime();

        return TimeZoneInfo.ConvertTimeToUtc(
            DateTime.SpecifyKind(value, DateTimeKind.Unspecified),
            AppTimeZone);
    }

    public static bool IsActiveAt(DateTime start, DateTime end, DateTime? atUtc = null)
    {
        var now = atUtc ?? UtcNow;
        var s = ToUtcForCompare(start);
        var e = ToUtcForCompare(end);
        return s <= now && e > now;
    }
}
