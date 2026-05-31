using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eParking.Services.Database.Parking
{
    public class Review
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public MyAppUser User { get; set; } = null!;

        [Required]
        public int ParkingLotId { get; set; }

        [ForeignKey(nameof(ParkingLotId))]
        public ParkingLot ParkingLot { get; set; } = null!;

        [Required]
        public int Rating { get; set; } // 1-5

        [MaxLength(1000)]
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}

