namespace eParking.Model.SearchObjects
{
    public class CitySearch : PagedSearch
        {
            public string? Name { get; set; }
        public bool? IsActive { get; set; }
    }
}