namespace eParking.Model.Requests
{
    public class MyAppUserUpdateRequest
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string? Password { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public int? GenderId { get; set; }
        public int? CityId { get; set; }
        public bool IsAdmin { get; set; }
        public bool IsUser { get; set; } = true;
        public bool IsActive { get; set; } = true;
    }
}
