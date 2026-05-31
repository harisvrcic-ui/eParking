namespace eParking.Model.SearchObjects
{
    public class ParkingSpotAvailabilitySearch : PagedSearch
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int? ParkingLotId { get; set; }
        public int? ZoneId { get; set; }
    }
}
