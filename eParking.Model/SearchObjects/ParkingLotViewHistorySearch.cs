namespace eParking.Model.SearchObjects
{
    public class ParkingLotViewHistorySearch : PagedSearch
        {
            public int? UserId { get; set; }
        public int? ParkingLotId { get; set; }
    }
}