namespace eParking.Model.Responses
{
    public class ParkingLotOverviewResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int TotalSpots { get; set; }
        public int AvailableSpots { get; set; }
        public int ZoneCount { get; set; }
        public string Status { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }
}
