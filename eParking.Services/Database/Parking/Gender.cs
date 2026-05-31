using System.ComponentModel.DataAnnotations;

namespace eParking.Services.Database.Parking
{
    public class Gender
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public ICollection<MyAppUser> Users { get; set; } = new List<MyAppUser>();
    }
}
