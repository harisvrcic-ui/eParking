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

            if (reservationType.Name.Contains("daily", StringComparison.OrdinalIgnoreCase))
            {
                var days = Math.Max(1, (int)Math.Ceiling(duration.TotalDays));
                basePrice = days * reservationType.Price;
            }
            else
            {
                var hours = Math.Max(1, (int)Math.Ceiling(duration.TotalHours));
                basePrice = hours * reservationType.Price;
            }

            return Math.Round(basePrice * spot.ParkingSpotType.PriceMultiplier, 2);
        }
    }
}
