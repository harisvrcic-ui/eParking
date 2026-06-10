using System.ComponentModel.DataAnnotations;
using eParking.Model;

namespace eParking.Model.Requests
{
    public class ReservationTypeUpdateRequest
    {
        [Range(1, int.MaxValue)]
        public int Id { get; set; }

        [Required]
        [StringLength(AuthConstants.ReservationTypeNameMaxLength, MinimumLength = 1)]
        public string Name { get; set; } = string.Empty;

        [Range(typeof(decimal), "0.01", "999999999")]
        public decimal Price { get; set; }

        [Required]
        public BillingUnit BillingUnit { get; set; } = BillingUnit.Hourly;
    }
}
