using eParking.Model;

namespace eParking.Model.SearchObjects
{
    public class ReservationSearch : PagedSearch
    {
        public int? UserId { get; set; }
        public int? CarId { get; set; }
        public int? ParkingSpotId { get; set; }
        public int? ParkingLotId { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public ReservationStatus? Status { get; set; }
    }
}