namespace eParking.Model.Requests
{
    public class ParkingLotViewHistoryUpdateRequest
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ParkingLotId { get; set; }
        public int ViewCount { get; set; }
    }
}
