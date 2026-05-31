using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eParking.Services.Database.Parking
{
    public class PasswordResetToken
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public MyAppUser User { get; set; } = null!;

        [Required]
        [MaxLength(256)]
        public string CodeHash { get; set; } = string.Empty;

        [Required]
        [MaxLength(64)]
        public string CodeSalt { get; set; } = string.Empty;

        public DateTime ExpiresAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public bool IsUsed { get; set; }
    }
}
