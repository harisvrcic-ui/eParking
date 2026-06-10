using eParking.Model;
using eParking.Model.Exceptions;
using eParking.Services;

namespace eParking.Services.Tests;

public class ReservationStatusHelperTests
{
    [Theory]
    [InlineData(0, ReservationStatus.Pending)]
    [InlineData(1, ReservationStatus.Confirmed)]
    [InlineData(2, ReservationStatus.Cancelled)]
    [InlineData(3, ReservationStatus.Completed)]
    public void ParseOrThrow_returns_valid_status(int value, ReservationStatus expected)
    {
        Assert.Equal(expected, ReservationStatusHelper.ParseOrThrow(value));
    }

    [Theory]
    [InlineData(-1)]
    [InlineData(4)]
    [InlineData(99)]
    public void ParseOrThrow_throws_for_invalid_status(int value)
    {
        Assert.Throws<BusinessException>(() => ReservationStatusHelper.ParseOrThrow(value));
    }

    [Theory]
    [InlineData(0, "Pending")]
    [InlineData(1, "Confirmed")]
    [InlineData(2, "Cancelled")]
    [InlineData(3, "Completed")]
    [InlineData(99, ReservationStatusHelper.UnknownStatusName)]
    public void FormatStatus_maps_known_and_unknown_values(int value, string expected)
    {
        Assert.Equal(expected, ReservationStatusHelper.FormatStatus(value));
    }
}
