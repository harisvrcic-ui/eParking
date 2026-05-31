namespace eParking.Model.SearchObjects
{
    public class ParkingLotSearch : PagedSearch
        {
            public string? Name { get; set; }
        public int? Status { get; set; }
        public bool? IsActive { get; set; }
    }
}