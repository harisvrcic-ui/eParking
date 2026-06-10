using System.ComponentModel.DataAnnotations;
using eParking.Model;

namespace eParking.Model.Requests
{
    public class CarUpdateRequest
    {
        [Range(1, int.MaxValue)]
        public int Id { get; set; }

        [Range(1, int.MaxValue)]
        public int BrandId { get; set; }

        [Range(1, int.MaxValue)]
        public int ColorId { get; set; }

        [Range(1, int.MaxValue)]
        public int UserId { get; set; }

        [Required]
        [StringLength(AuthConstants.CarModelMaxLength, MinimumLength = 1)]
        public string Model { get; set; } = string.Empty;

        [Required]
        [StringLength(AuthConstants.LicensePlateMaxLength, MinimumLength = 2)]
        public string LicensePlate { get; set; } = string.Empty;

        [Range(1900, 2100)]
        public int? YearOfManufacture { get; set; }

        public string? Picture { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
