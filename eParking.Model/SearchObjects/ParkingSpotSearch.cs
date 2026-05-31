namespace eParking.Model.SearchObjects
{
    public class ParkingSpotSearch : PagedSearch
        {
            public string? ParkingNumber { get; set; }
        public int? ZoneId { get; set; }
        public int? ParkingLotId { get; set; }
        public int? ParkingSpotTypeId { get; set; }
        public bool? IsActive { get; set; }
    }
}