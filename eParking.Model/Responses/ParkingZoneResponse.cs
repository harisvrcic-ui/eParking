namespace eParking.Model.Responses
{
    public class ParkingZoneResponse
    {
        public int Id { get; set; }
        public int ParkingLotId { get; set; }
        public string ParkingLotName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public int SpotCount { get; set; }
    }
}
