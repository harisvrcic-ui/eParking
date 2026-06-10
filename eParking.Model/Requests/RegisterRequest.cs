using System.ComponentModel.DataAnnotations;
using eParking.Model;

namespace eParking.Model.Requests
{
    /// <summary>
    /// Public registration — no role/privilege fields (RS2 auth).
    /// </summary>
    public class RegisterRequest
    {
        [Required]
        [StringLength(AuthConstants.UsernameMaxLength, MinimumLength = 3)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [StringLength(256, MinimumLength = AuthConstants.MinPasswordLength)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [StringLength(AuthConstants.NameMaxLength, MinimumLength = 1)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [StringLength(AuthConstants.NameMaxLength, MinimumLength = 1)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [StringLength(AuthConstants.EmailMaxLength)]
        public string Email { get; set; } = string.Empty;

        [StringLength(AuthConstants.PhoneMaxLength)]
        public string? PhoneNumber { get; set; }

        [Range(1, int.MaxValue)]
        public int? GenderId { get; set; }

        [Range(1, int.MaxValue)]
        public int? CityId { get; set; }
    }
}
