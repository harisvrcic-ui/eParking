using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eParking.Services.Database.Parking
{
    public class Reservation
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CarId { get; set; }

        [ForeignKey(nameof(CarId))]
        public Car Car { get; set; } = null!;

        [Required]
        public int ParkingSpotId { get; set; }

        [ForeignKey(nameof(ParkingSpotId))]
        public ParkingSpot ParkingSpot { get; set; } = null!;

        [Required]
        public int ReservationTypeId { get; set; }

        [ForeignKey(nameof(ReservationTypeId))]
        public ReservationType ReservationType { get; set; } = null!;

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        public double FinalPrice { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public int Status { get; set; } = (int)Model.ReservationStatus.Pending;

        public DateTime? StatusChangedAt { get; set; }

        public int? StatusChangedByUserId { get; set; }

        [ForeignKey(nameof(StatusChangedByUserId))]
        public MyAppUser? StatusChangedByUser { get; set; }

        [MaxLength(500)]
        public string? StatusNote { get; set; }
    }
}
