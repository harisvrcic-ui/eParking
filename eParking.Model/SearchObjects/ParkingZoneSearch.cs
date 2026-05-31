namespace eParking.Model.SearchObjects
{
    public class ParkingZoneSearch : PagedSearch
        {
            public string? Name { get; set; }
        public int? ParkingLotId { get; set; }
        public bool? IsActive { get; set; }
    }
}