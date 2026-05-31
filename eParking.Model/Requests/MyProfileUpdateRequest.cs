namespace eParking.Model.Requests
{
    /// <summary>
    /// Polja koja običan korisnik smije mijenjati na svom profilu.
    /// </summary>
    public class MyProfileUpdateRequest
    {
        public string Username { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public int? GenderId { get; set; }
        public int? CityId { get; set; }
    }
}
