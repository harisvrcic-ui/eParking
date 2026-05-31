namespace eParking.Model.SearchObjects
{
    public class CarSearch : PagedSearch
        {
            public int? UserId { get; set; }
        public int? BrandId { get; set; }
        public string? LicensePlate { get; set; }
        public bool? IsActive { get; set; }
    }
}