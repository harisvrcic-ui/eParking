namespace eParking.Model.Responses
{
    public class ParkingLotResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int NumberOfSpots { get; set; }
        public string Status { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public int ZoneCount { get; set; }
    }
}
