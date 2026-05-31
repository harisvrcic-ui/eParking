namespace eParking.Model.Responses
{
    public class ParkingSpotResponse
    {
        public int Id { get; set; }
        public string ParkingNumber { get; set; } = string.Empty;
        public int ParkingSpotTypeId { get; set; }
        public string ParkingSpotTypeName { get; set; } = string.Empty;
        public int ZoneId { get; set; }
        public string ZoneName { get; set; } = string.Empty;
        public int ParkingLotId { get; set; }
        public string ParkingLotName { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public string? DisplayName { get; set; }
    }
}
