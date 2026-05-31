using System.ComponentModel.DataAnnotations;

namespace eParking.Services.Database.Parking
{
    public class Color
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(7)]
        public string? HexCode { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public ICollection<Car> Cars { get; set; } = new List<Car>();
    }
}
