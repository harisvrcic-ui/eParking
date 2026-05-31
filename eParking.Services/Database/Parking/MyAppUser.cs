using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eParking.Services.Database.Parking
{
    public class MyAppUser
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;

        public string PasswordSalt { get; set; } = string.Empty;

        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        public int? GenderId { get; set; }

        [ForeignKey(nameof(GenderId))]
        public Gender? Gender { get; set; }

        public int? CityId { get; set; }

        [ForeignKey(nameof(CityId))]
        public City? City { get; set; }

        public bool IsAdmin { get; set; }

        public bool IsUser { get; set; } = true;

        public int FailedLoginAttempts { get; set; }

        public DateTime? LockoutUntil { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public byte[]? Picture { get; set; }

        public ICollection<Car> Cars { get; set; } = new List<Car>();

        public ICollection<FavoriteParkingLot> FavoriteParkingLots { get; set; } = new List<FavoriteParkingLot>();
        public ICollection<UserNotification> Notifications { get; set; } = new List<UserNotification>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        public ICollection<ParkingLotViewHistory> ViewHistories { get; set; } = new List<ParkingLotViewHistory>();
    }
}
