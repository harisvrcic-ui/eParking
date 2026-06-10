using System.ComponentModel.DataAnnotations;
using eParking.Model;

namespace eParking.Model.Requests
{
    public class MyAppUserUpdateRequest
    {
        [Range(1, int.MaxValue)]
        public int Id { get; set; }

        [Required]
        [StringLength(AuthConstants.UsernameMaxLength, MinimumLength = 3)]
        public string Username { get; set; } = string.Empty;

        [StringLength(256, MinimumLength = AuthConstants.MinPasswordLength)]
        public string? Password { get; set; }

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

        public bool IsAdmin { get; set; }

        public bool IsUser { get; set; } = true;

        public bool IsActive { get; set; } = true;
    }
}
