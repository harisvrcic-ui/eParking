using System.ComponentModel.DataAnnotations;

namespace eParking.Services.Database.Parking
{
    public class City
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        public int? CountryId { get; set; }

        public Country? Country { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public ICollection<MyAppUser> Users { get; set; } = new List<MyAppUser>();
    }
}
