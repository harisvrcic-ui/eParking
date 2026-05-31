using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eParking.Services.Database.Parking
{
    /// <summary>
    /// Aggregated view history per user and parking lot (recommender signal).
    /// </summary>
    public class ParkingLotViewHistory
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

        public int ViewCount { get; set; } = 1;

        public DateTime LastViewedAt { get; set; } = DateTime.UtcNow;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
