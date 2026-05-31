namespace eParking.Model.SearchObjects
{
    public class NewsSearch : PagedSearch
        {
            public string? Title { get; set; }
        public bool? IsActive { get; set; }
    }
}