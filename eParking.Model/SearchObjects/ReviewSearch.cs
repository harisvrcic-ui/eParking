namespace eParking.Model.SearchObjects
{
    public class ReviewSearch : PagedSearch
        {
            public int? UserId { get; set; }
        public int? ParkingLotId { get; set; }
        public int? MinRating { get; set; }
    }
}