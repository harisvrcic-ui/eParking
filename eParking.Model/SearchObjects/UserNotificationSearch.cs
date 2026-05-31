namespace eParking.Model.SearchObjects
{
    public class UserNotificationSearch : PagedSearch
        {
            public int? UserId { get; set; }
        public bool? IsRead { get; set; }
    }
}