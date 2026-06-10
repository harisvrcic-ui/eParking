using eParking.Model;
using eParking.Services.Database.Parking;

namespace eParking.Services
{
    public static class ReservationPricing
    {
        public static decimal Calculate(ReservationType reservationType, ParkingSpot spot, DateTime startDate, DateTime endDate)
        {
            if (endDate <= startDate)
                throw new BusinessException("End date must be after start date.");

            var duration = endDate - startDate;
            decimal basePrice;

            if (reservationType.BillingUnit == BillingUnit.Daily)
            {
                var days = Math.Max(1, (int)Math.Ceiling(duration.TotalDays));
                basePrice = days * reservationType.Price;
            }
            else if (reservationType.BillingUnit == BillingUnit.Hourly)
            {
                var hours = Math.Max(1, (int)Math.Ceiling(duration.TotalHours));
                basePrice = hours * reservationType.Price;
            }
            else
                throw new BusinessException($"Nepoznata jedinica obračuna: {reservationType.BillingUnit}.");

            return Math.Round(basePrice * spot.ParkingSpotType.PriceMultiplier, 2);
        }
    }
}
