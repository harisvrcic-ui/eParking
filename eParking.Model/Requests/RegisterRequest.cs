namespace eParking.Model.Requests
{
    /// <summary>
    /// Public registration — no role/privilege fields (RS2 auth).
    /// </summary>
    public class RegisterRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public int? GenderId { get; set; }
        public int? CityId { get; set; }
    }
}
