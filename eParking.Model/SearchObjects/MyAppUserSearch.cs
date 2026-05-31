namespace eParking.Model.SearchObjects
{
    public class MyAppUserSearch : PagedSearch
        {
            public string? Username { get; set; }
        public string? Email { get; set; }
        public string? Name { get; set; }
        public bool? IsAdmin { get; set; }
        public bool? IsActive { get; set; }
    }
}