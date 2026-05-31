namespace eParking.Model.SearchObjects
{
    public class CountrySearch : PagedSearch
        {
            public string? Name { get; set; }
        public bool? IsActive { get; set; }
    }
}