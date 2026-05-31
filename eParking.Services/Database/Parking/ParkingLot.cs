using System.ComponentModel.DataAnnotations;

namespace eParking.Services.Database.Parking
{
    public class ParkingLot
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// Cached count of spots in this lot (updated when spots/zones change).
        /// </summary>
        public int NumberOfSpots { get; set; }

        public ParkingLotStatus Status { get; set; } = ParkingLotStatus.Active;

        public bool IsActive { get; set; } = true;

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public ICollection<ParkingZone> Zones { get; set; } = new List<ParkingZone>();

        public ICollection<FavoriteParkingLot> Favorites { get; set; } = new List<FavoriteParkingLot>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        public ICollection<ParkingLotViewHistory> ViewHistories { get; set; } = new List<ParkingLotViewHistory>();
    }
}
