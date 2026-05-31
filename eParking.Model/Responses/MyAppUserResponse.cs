namespace eParking.Model.Responses
{
    public class MyAppUserResponse
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public string? PhoneNumber { get; set; }
        public int? GenderId { get; set; }
        public string? GenderName { get; set; }
        public int? CityId { get; set; }
        public string? CityName { get; set; }
        public bool IsAdmin { get; set; }
        public bool IsUser { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public int CarCount { get; set; }
        public string? Picture { get; set; }
    }
}
