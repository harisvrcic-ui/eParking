using eParking.Services;
using eParking.Services.Database.Parking;

namespace eParking.Services.Tests;

public class ReservationPricingTests
{
    private static ReservationType HourlyType(int pricePerHour = 2) => new()
    {
        Name = "Hourly",
        Price = pricePerHour
    };

    private static ReservationType DailyType(int pricePerDay = 15) => new()
    {
        Name = "Daily",
        Price = pricePerDay
    };

    private static ParkingSpot StandardSpot(decimal multiplier = 1m) => new()
    {
        ParkingSpotType = new ParkingSpotType { PriceMultiplier = multiplier }
    };

    [Fact]
    public void Hourly_25_hours_charges_25_units()
    {
        var start = new DateTime(2026, 5, 1, 8, 0, 0, DateTimeKind.Utc);
        var end = start.AddHours(25);

        var price = ReservationPricing.Calculate(HourlyType(2), StandardSpot(), start, end);

        Assert.Equal(50m, price);
    }

    [Fact]
    public void Hourly_partial_hour_rounds_up()
    {
        var start = new DateTime(2026, 5, 1, 8, 0, 0, DateTimeKind.Utc);
        var end = start.AddMinutes(90);

        var price = ReservationPricing.Calculate(HourlyType(3), StandardSpot(), start, end);

        Assert.Equal(6m, price);
    }

    [Fact]
    public void Daily_48_hours_charges_2_days()
    {
        var start = new DateTime(2026, 5, 1, 8, 0, 0, DateTimeKind.Utc);
        var end = start.AddHours(48);

        var price = ReservationPricing.Calculate(DailyType(10), StandardSpot(), start, end);

        Assert.Equal(20m, price);
    }

    [Fact]
    public void Daily_25_hours_charges_2_days_ceiling()
    {
        var start = new DateTime(2026, 5, 1, 8, 0, 0, DateTimeKind.Utc);
        var end = start.AddHours(25);

        var price = ReservationPricing.Calculate(DailyType(12), StandardSpot(), start, end);

        Assert.Equal(24m, price);
    }

    [Fact]
    public void Spot_multiplier_is_applied()
    {
        var start = new DateTime(2026, 5, 1, 8, 0, 0, DateTimeKind.Utc);
        var end = start.AddHours(2);

        var price = ReservationPricing.Calculate(HourlyType(5), StandardSpot(1.5m), start, end);

        Assert.Equal(15m, price);
    }
}
