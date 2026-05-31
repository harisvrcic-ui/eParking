using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eParking.Services.Database.Parking
{
    public class ParkingSpot
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ParkingNumber { get; set; }

        [Required]
        public int ParkingSpotTypeId { get; set; }

        [ForeignKey(nameof(ParkingSpotTypeId))]
        public ParkingSpotType ParkingSpotType { get; set; } = null!;

        [Required]
        public int ZoneId { get; set; }

        [ForeignKey(nameof(ZoneId))]
        public ParkingZone Zone { get; set; } = null!;

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        [MaxLength(200)]
        public string? DisplayName { get; set; }

        [MaxLength(200)]
        public string? DisplayNameSearch { get; set; }

        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}
