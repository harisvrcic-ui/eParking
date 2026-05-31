namespace eParking.Model.Responses
{
    public class ParkingLotViewHistoryResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public int ParkingLotId { get; set; }
        public string ParkingLotName { get; set; } = string.Empty;
        public int ViewCount { get; set; }
        public DateTime LastViewedAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
