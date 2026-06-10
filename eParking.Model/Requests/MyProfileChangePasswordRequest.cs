using System.ComponentModel.DataAnnotations;
using eParking.Model;

namespace eParking.Model.Requests
{
    public class MyProfileChangePasswordRequest
    {
        [Required]
        [StringLength(256, MinimumLength = 1)]
        public string CurrentPassword { get; set; } = string.Empty;

        [Required]
        [StringLength(256, MinimumLength = AuthConstants.MinPasswordLength)]
        public string NewPassword { get; set; } = string.Empty;
    }
}
