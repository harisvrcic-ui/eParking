namespace eParking.Model.SearchObjects
{
    public class GenderSearch : PagedSearch
    {
        public string? Name { get; set; }
        public bool? IsActive { get; set; }
    }
}
