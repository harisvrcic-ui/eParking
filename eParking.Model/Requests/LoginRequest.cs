using System.ComponentModel.DataAnnotations;
using eParking.Model;

namespace eParking.Model.Requests
{
    public class LoginRequest
    {
        [Required]
        [StringLength(AuthConstants.UsernameMaxLength, MinimumLength = 1)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [StringLength(256, MinimumLength = 1)]
        public string Password { get; set; } = string.Empty;
    }
}
