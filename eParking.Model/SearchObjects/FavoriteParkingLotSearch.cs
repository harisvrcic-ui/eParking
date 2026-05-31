namespace eParking.Model.SearchObjects
{
    public class FavoriteParkingLotSearch : PagedSearch
        {
            public int? UserId { get; set; }
        public int? ParkingLotId { get; set; }
    }
}