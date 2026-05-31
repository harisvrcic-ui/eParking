using eParking.Model;

namespace eParking.Model.Requests
{
    public class ParkingLotUpdateRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int Status { get; set; } = ParkingLotStatusIds.Active;
        public bool IsActive { get; set; } = true;
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }
}
