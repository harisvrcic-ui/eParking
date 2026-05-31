namespace eParking.Model.Responses
{
    public class ParkingLotDetailResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int TotalSpots { get; set; }
        public int AvailableSpots { get; set; }
        public string Status { get; set; } = string.Empty;
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public List<ParkingZoneDetailResponse> Zones { get; set; } = new();
    }

    public class ParkingZoneDetailResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public List<ParkingSpotDetailResponse> Spots { get; set; } = new();
    }

    public class ParkingSpotDetailResponse
    {
        public int Id { get; set; }
        public string ParkingNumber { get; set; } = string.Empty;
        public string? DisplayName { get; set; }
        public string? ZoneName { get; set; }
        public string SpotTypeName { get; set; } = string.Empty;
        public bool IsAvailableNow { get; set; }
    }
}
