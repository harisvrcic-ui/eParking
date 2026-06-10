using eParking.Model;
using eParking.Services;
using eParking.Services.Database.Parking;

namespace eParking.Services.Tests;

public class ReservationPricingTests
{
    private static ReservationType HourlyType(decimal pricePerHour = 2m, string name = "Hourly") => new()
    {
        Name = name,
        Price = pricePerHour,
        BillingUnit = BillingUnit.Hourly
    };

    private static ReservationType DailyType(decimal pricePerDay = 15m, string name = "Daily") => new()
    {
        Name = name,
        Price = pricePerDay,
        BillingUnit = BillingUnit.Daily
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

    [Fact]
    public void Hourly_decimal_unit_price_is_preserved()
    {
        var start = new DateTime(2026, 5, 1, 8, 0, 0, DateTimeKind.Utc);
        var end = start.AddHours(1);

        var price = ReservationPricing.Calculate(HourlyType(2.50m), StandardSpot(), start, end);

        Assert.Equal(2.50m, price);
    }

    [Fact]
    public void Daily_billing_uses_billing_unit_not_display_name()
    {
        var start = new DateTime(2026, 5, 1, 8, 0, 0, DateTimeKind.Utc);
        var end = start.AddHours(48);

        var price = ReservationPricing.Calculate(DailyType(10, name: "Dnevna"), StandardSpot(), start, end);

        Assert.Equal(20m, price);
    }

    [Fact]
    public void Hourly_name_with_daily_word_still_charges_hourly_when_billing_unit_hourly()
    {
        var start = new DateTime(2026, 5, 1, 8, 0, 0, DateTimeKind.Utc);
        var end = start.AddHours(2);

        var price = ReservationPricing.Calculate(HourlyType(5, name: "Daily special promo"), StandardSpot(), start, end);

        Assert.Equal(10m, price);
    }
}
