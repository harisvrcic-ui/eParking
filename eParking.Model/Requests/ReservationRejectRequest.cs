using System.ComponentModel.DataAnnotations;

namespace eParking.Model.Requests
{
    public class ReservationRejectRequest
    {
        [Required]
        [StringLength(500, MinimumLength = 1)]
        public string Reason { get; set; } = string.Empty;
    }
}
