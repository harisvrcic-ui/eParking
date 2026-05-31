namespace eParking.Model.Requests
{
    public class ParkingLotViewHistoryInsertRequest
    {
        public int UserId { get; set; }
        public int ParkingLotId { get; set; }
        public int ViewCount { get; set; } = 1;
    }
}
