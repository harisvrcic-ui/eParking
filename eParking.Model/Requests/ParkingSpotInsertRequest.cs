namespace eParking.Model.Requests
{
    public class ParkingSpotInsertRequest
    {
        public string ParkingNumber { get; set; } = string.Empty;
        public int ParkingSpotTypeId { get; set; }
        public int ZoneId { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
