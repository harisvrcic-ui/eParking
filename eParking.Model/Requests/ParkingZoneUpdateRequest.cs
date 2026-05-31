namespace eParking.Model.Requests
{
    public class ParkingZoneUpdateRequest
    {
        public int Id { get; set; }
        public int ParkingLotId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
