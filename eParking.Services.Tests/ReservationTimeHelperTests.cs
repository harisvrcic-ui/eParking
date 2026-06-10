using eParking.Model.Exceptions;
using eParking.Services;

namespace eParking.Services.Tests;

public class ReservationTimeHelperTests
{
    [Fact]
    public void ValidateReservationPeriod_rejects_end_before_start()
    {
        var start = new DateTime(2026, 6, 10, 12, 0, 0, DateTimeKind.Utc);
        var end = start.AddHours(-1);

        var ex = Assert.Throws<BusinessException>(() =>
            ReservationTimeHelper.ValidateReservationPeriod(start, end));

        Assert.Contains("after start", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void ValidateReservationPeriod_rejects_start_in_past()
    {
        var now = ReservationTimeHelper.UtcNow;
        var start = now.AddHours(-2);
        var end = now.AddHours(1);

        var ex = Assert.Throws<BusinessException>(() =>
            ReservationTimeHelper.ValidateReservationPeriod(start, end));

        Assert.Contains("past", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void NormalizeAndValidatePeriod_converts_unspecified_local_to_utc()
    {
        // 2026-06-10 10:00 in Sarajevo (CEST, UTC+2) -> 08:00 UTC
        var localStart = new DateTime(2026, 6, 10, 10, 0, 0, DateTimeKind.Unspecified);
        var localEnd = localStart.AddHours(2);

        var futureUtcStart = ReservationTimeHelper.NormalizeToUtc(localStart);
        if (futureUtcStart < ReservationTimeHelper.UtcNow)
        {
            localStart = localStart.AddDays(30);
            localEnd = localStart.AddHours(2);
        }

        var (startUtc, endUtc) = ReservationTimeHelper.NormalizeAndValidatePeriod(localStart, localEnd);

        Assert.Equal(DateTimeKind.Utc, startUtc.Kind);
        Assert.Equal(DateTimeKind.Utc, endUtc.Kind);
        Assert.True(endUtc > startUtc);
        Assert.True(startUtc >= ReservationTimeHelper.UtcNow);
    }
}
