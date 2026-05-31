namespace eParking.Model.SearchObjects
{
    public class BrandSearch : PagedSearch
        {
            public string? Name { get; set; }
        public bool? IsActive { get; set; }
    }
}