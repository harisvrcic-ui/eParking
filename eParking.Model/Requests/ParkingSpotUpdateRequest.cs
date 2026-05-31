namespace eParking.Model.Requests
{
    public class ParkingSpotUpdateRequest
    {
        public int Id { get; set; }
        public string ParkingNumber { get; set; } = string.Empty;
        public int ParkingSpotTypeId { get; set; }
        public int ZoneId { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
