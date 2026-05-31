using System.ComponentModel.DataAnnotations;

namespace eParking.Services.Database.Parking
{
    public class Brand
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        public byte[]? Logo { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public ICollection<Car> Cars { get; set; } = new List<Car>();
    }
}
