using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eParking.Services.Database.Parking
{
    public class FavoriteParkingLot
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

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

