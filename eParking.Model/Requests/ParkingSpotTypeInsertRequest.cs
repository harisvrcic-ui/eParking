namespace eParking.Model.Requests
{
    public class ParkingSpotTypeInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal PriceMultiplier { get; set; } = 1m;
    }
}
